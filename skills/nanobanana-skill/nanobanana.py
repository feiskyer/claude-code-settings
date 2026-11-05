#!/usr/bin/env python3
# Generate or edit images using Google Gemini API
import os
import argparse
import uuid
from dotenv import load_dotenv
from google import genai
from google.genai import types
from PIL import Image
from io import BytesIO

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


def main():
    # Parse command-line arguments
    parser = argparse.ArgumentParser(
        description="Generate or edit images using Google Gemini API"
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
        default="gemini-nano-banana-2.1",
        choices=[
            "gemini-nano-banana-2.1",
            "gemini-3.1-flash-image",
            "gemini-3-pro-image",
            "gemini-2.5-flash-image",
        ],
        help="Model to use for image generation (default: gemini-nano-banana-2.1)",
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

    args = parser.parse_args()

    # Google API configuration from environment variables
    api_key = os.getenv("GEMINI_API_KEY") or ""
    if not api_key:
        parser.error(
            "Missing GEMINI_API_KEY environment variable. "
            "Set it in ~/.nanobanana.env or export it."
        )

    # Initialize Gemini client
    client = genai.Client(api_key=api_key)

    # Get aspect ratio from size
    aspect_ratio = ASPECT_RATIO_MAP.get(args.size, "16:9")

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
    # gemini-2.5 image models reject Google Search grounding and thinking
    legacy_model = args.model.startswith("gemini-2.5")
    if not args.no_search and not legacy_model:
        config_kwargs["tools"] = [types.Tool(google_search=types.GoogleSearch())]
    if not args.no_think and not legacy_model:
        config_kwargs["thinking_config"] = types.ThinkingConfig(include_thoughts=True)

    # Generate or edit image
    response = client.models.generate_content(
        model=args.model,
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
            # Skip draft images produced during thinking; keep only the final one
            if part.thought:
                continue
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
