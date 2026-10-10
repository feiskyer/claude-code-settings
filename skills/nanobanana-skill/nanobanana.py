#!/usr/bin/env python3
# Generate or edit images using Google Gemini or Atlas Cloud
import argparse
import os
import time
import uuid
from io import BytesIO
from urllib.parse import quote

import httpx
from dotenv import load_dotenv
from google import genai
from google.genai import types
from PIL import Image

# Load environment variables
load_dotenv(os.path.expanduser("~") + "/.nanobanana.env")

# Aspect ratio to resolution mapping
ASPECT_RATIO_MAP = {
    "1024x1024": "1:1",  # 1:1
    "832x1248": "2:3",  # 2:3
    "1248x832": "3:2",  # 3:2
    "864x1184": "3:4",  # 3:4
    "1184x864": "4:3",  # 4:3
    "896x1152": "4:5",  # 4:5
    "1152x896": "5:4",  # 5:4
    "768x1344": "9:16",  # 9:16
    "1344x768": "16:9",  # 16:9
    "1536x672": "21:9",  # 21:9
}

DEFAULT_GEMINI_MODEL = "gemini-3.1-flash-image-preview"
DEFAULT_ATLAS_MODEL = "google/nano-banana/text-to-image-developer"
DEFAULT_ATLAS_API_BASE = "https://api.atlascloud.ai/api/v1"
ATLAS_TERMINAL_FAILURES = {"failed", "canceled", "cancelled"}


def atlas_response_data(response):
    response.raise_for_status()
    body = response.json()
    if not isinstance(body, dict):
        raise TypeError("Atlas Cloud returned a non-object response.")
    code = body.get("code")
    if code not in (None, 0, 200):
        raise RuntimeError(
            body.get("message") or f"Atlas Cloud request failed with code {code}."
        )
    data = body.get("data", body)
    if not isinstance(data, dict):
        raise TypeError("Atlas Cloud response does not contain an object payload.")
    return data


def generate_with_atlas(args, aspect_ratio, api_key):
    api_base = os.getenv("ATLASCLOUD_MEDIA_API_BASE", DEFAULT_ATLAS_API_BASE).rstrip(
        "/"
    )
    model = args.model or DEFAULT_ATLAS_MODEL
    headers = {
        "Authorization": f"Bearer {api_key}",
        "Content-Type": "application/json",
    }
    payload = {"model": model, "prompt": args.prompt, "aspect_ratio": aspect_ratio}

    # Intentionally submit exactly once. A failed generation request must be retried by the user.
    submitted = atlas_response_data(
        httpx.post(
            f"{api_base}/model/generateImage",
            headers=headers,
            json=payload,
            timeout=args.request_timeout,
        )
    )
    prediction_id = submitted.get("id")
    if not prediction_id:
        raise ValueError("Atlas Cloud response does not contain a prediction id.")

    deadline = time.monotonic() + args.poll_timeout
    result = submitted
    while True:
        status = str(result.get("status", "")).lower()
        if status == "completed":
            break
        if status in ATLAS_TERMINAL_FAILURES:
            raise RuntimeError(
                result.get("error") or f"Atlas Cloud generation {status}."
            )
        if time.monotonic() >= deadline:
            raise TimeoutError(
                f"Atlas Cloud generation did not complete within {args.poll_timeout} seconds."
            )
        time.sleep(args.poll_interval)
        result = atlas_response_data(
            httpx.get(
                f"{api_base}/model/prediction/{quote(str(prediction_id), safe='')}",
                headers={"Authorization": f"Bearer {api_key}"},
                timeout=args.request_timeout,
            )
        )

    outputs = result.get("outputs")
    if not isinstance(outputs, list) or not outputs or not isinstance(outputs[0], str):
        raise ValueError("Atlas Cloud completed without an image output URL.")
    output = httpx.get(outputs[0], timeout=args.request_timeout)
    output.raise_for_status()
    return output.content


def main():
    # Parse command-line arguments
    parser = argparse.ArgumentParser(
        description="Generate or edit images using Google Gemini or Atlas Cloud"
    )
    parser.add_argument(
        "--provider",
        choices=["gemini", "atlas"],
        default="gemini",
        help="Image provider to use (default: gemini)",
    )
    parser.add_argument(
        "--prompt",
        type=str,
        required=True,
        help="Prompt for image generation or editing",
    )
    parser.add_argument(
        "--output",
        type=str,
        default=f"nanobanana-{uuid.uuid4()}.png",
        help="Output image filename (default: nanobanana-<UUID>.png)",
    )
    parser.add_argument(
        "--input", type=str, nargs="*", help="Input image files for editing (optional)"
    )
    parser.add_argument(
        "--size",
        type=str,
        default="768x1344",
        choices=list(ASPECT_RATIO_MAP.keys()),
        help="Size/aspect ratio of the generated image (default: 768x1344 / 9:16)",
    )
    parser.add_argument(
        "--model",
        type=str,
        help="Provider model override",
    )
    parser.add_argument(
        "--resolution",
        type=str,
        default="1K",
        choices=["1K", "2K", "4K"],
        help="Resolution of the generated image (default: 1K)",
    )
    parser.add_argument(
        "--no-search",
        action="store_true",
        default=False,
        help="Disable Google Search grounding (enabled by default)",
    )
    parser.add_argument(
        "--no-think",
        action="store_true",
        default=False,
        help="Disable thinking/reasoning (useful for models that don't support it)",
    )
    parser.add_argument(
        "--poll-interval",
        type=float,
        default=3.0,
        help="Atlas Cloud result polling interval in seconds (default: 3)",
    )
    parser.add_argument(
        "--poll-timeout",
        type=float,
        default=600.0,
        help="Atlas Cloud result polling timeout in seconds (default: 600)",
    )
    parser.add_argument(
        "--request-timeout",
        type=float,
        default=60.0,
        help="Atlas Cloud HTTP request timeout in seconds (default: 60)",
    )

    args = parser.parse_args()

    # Get aspect ratio from size
    aspect_ratio = ASPECT_RATIO_MAP.get(args.size, "16:9")

    if args.provider == "atlas":
        if args.input:
            parser.error(
                "Atlas Cloud provider currently supports text-to-image generation only."
            )
        if (
            args.poll_interval <= 0
            or args.poll_timeout <= 0
            or args.request_timeout <= 0
        ):
            parser.error("Atlas Cloud timeout and polling values must be positive.")
        api_key = os.getenv("ATLASCLOUD_API_KEY") or ""
        if not api_key:
            parser.error("Missing ATLASCLOUD_API_KEY environment variable.")
        print(
            f"Generating image via Atlas Cloud (size: {args.size}) with prompt: {args.prompt}"
        )
        image = Image.open(BytesIO(generate_with_atlas(args, aspect_ratio, api_key)))
        image.save(args.output)
        print(f"\n\nImage saved to: {args.output}")
        return

    # Google API configuration from environment variables
    api_key = os.getenv("GEMINI_API_KEY") or ""
    if not api_key:
        parser.error(
            "Missing GEMINI_API_KEY environment variable. "
            "Set it in ~/.nanobanana.env or export it."
        )

    # Initialize Gemini client
    client = genai.Client(api_key=api_key)
    model = args.model or DEFAULT_GEMINI_MODEL

    # Build contents list for the API call
    contents = []

    # Check if input images are provided
    if args.input and len(args.input) > 0:
        # Use images.generate_content() with images for editing
        print(f"Editing images with prompt: {args.prompt}")
        print(f"Input images: {args.input}")
        print(f"Aspect ratio: {aspect_ratio} ({args.size})")

        # Add prompt first
        contents.append(args.prompt)

        # Add all input images
        for img_path in args.input:
            image = Image.open(img_path)
            contents.append(image)
    else:
        print(f"Generating image (size: {args.size}) with prompt: {args.prompt}")
        contents.append(args.prompt)

    # Build generation config
    config_kwargs = {
        "response_modalities": ["TEXT", "IMAGE"],
        "image_config": types.ImageConfig(
            aspect_ratio=aspect_ratio,
            image_size=args.resolution,
        ),
    }
    if not getattr(args, "no_search", False):
        config_kwargs["tools"] = [types.Tool(google_search=types.GoogleSearch())]
    if not getattr(args, "no_think", False):
        config_kwargs["thinking_config"] = types.ThinkingConfig(include_thoughts=True)

    # Generate or edit image
    response = client.models.generate_content(
        model=model,
        contents=contents,
        config=types.GenerateContentConfig(**config_kwargs),
    )

    if (
        response.candidates is None
        or len(response.candidates) == 0
        or response.candidates[0].content is None
        or response.candidates[0].content.parts is None
    ):
        raise ValueError("No data received from the API.")

    # Extract image from response
    image_saved = False
    for part in response.candidates[0].content.parts:
        if part.text is not None:
            print(f"{part.text}", end="")
        elif part.inline_data is not None and part.inline_data.data is not None:
            image = Image.open(BytesIO(part.inline_data.data))

            image.save(args.output)
            image_saved = True
            print(f"\n\nImage saved to: {args.output}")

    if not image_saved:
        print(
            "\n\nWarning: No image data found in the API response. This usually means the model returned only text. Please try again with a different prompt to make image generation more clear."
        )


if __name__ == "__main__":
    main()
