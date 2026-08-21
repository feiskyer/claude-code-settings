import importlib.util
import os
import unittest
from pathlib import Path
from types import SimpleNamespace
from unittest.mock import Mock, call, patch

MODULE_PATH = Path(__file__).with_name("nanobanana.py")
SPEC = importlib.util.spec_from_file_location("nanobanana", MODULE_PATH)
nanobanana = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(nanobanana)


def response(payload=None, content=b""):
    result = Mock()
    result.json.return_value = payload
    result.content = content
    return result


class AtlasGenerationTests(unittest.TestCase):
    def setUp(self):
        self.args = SimpleNamespace(
            model=None,
            prompt="A paper-cut mountain landscape",
            request_timeout=30.0,
            poll_timeout=10.0,
            poll_interval=0.01,
        )

    @patch.object(nanobanana.time, "sleep")
    @patch.object(nanobanana.httpx, "get")
    @patch.object(nanobanana.httpx, "post")
    def test_submits_once_and_polls_until_completed(self, post, get, sleep):
        post.return_value = response(
            {"code": 200, "data": {"id": "prediction-1", "status": "starting"}}
        )
        get.side_effect = [
            response(
                {"code": 200, "data": {"id": "prediction-1", "status": "processing"}}
            ),
            response(
                {
                    "code": 200,
                    "data": {
                        "id": "prediction-1",
                        "status": "completed",
                        "outputs": ["https://cdn.example/image.png"],
                    },
                }
            ),
            response(content=b"image-bytes"),
        ]

        with patch.dict(
            os.environ,
            {"ATLASCLOUD_API_BASE": "https://api.atlascloud.ai/v1"},
        ):
            os.environ.pop("ATLASCLOUD_MEDIA_API_BASE", None)
            generated = nanobanana.generate_with_atlas(self.args, "16:9", "test-key")

        self.assertEqual(generated, b"image-bytes")
        post.assert_called_once()
        self.assertEqual(
            post.call_args.args[0],
            "https://api.atlascloud.ai/api/v1/model/generateImage",
        )
        self.assertEqual(
            post.call_args.kwargs["json"]["model"], nanobanana.DEFAULT_ATLAS_MODEL
        )
        self.assertEqual(post.call_args.kwargs["json"]["aspect_ratio"], "16:9")
        self.assertEqual(
            get.call_args_list,
            [
                call(
                    "https://api.atlascloud.ai/api/v1/model/prediction/prediction-1",
                    headers={"Authorization": "Bearer test-key"},
                    timeout=30.0,
                ),
                call(
                    "https://api.atlascloud.ai/api/v1/model/prediction/prediction-1",
                    headers={"Authorization": "Bearer test-key"},
                    timeout=30.0,
                ),
                call("https://cdn.example/image.png", timeout=30.0),
            ],
        )
        self.assertEqual(sleep.call_count, 2)

    @patch.object(nanobanana.httpx, "post")
    def test_rejects_failed_submit_without_retry(self, post):
        post.return_value = response({"code": 500, "message": "provider unavailable"})

        with self.assertRaisesRegex(RuntimeError, "provider unavailable"):
            nanobanana.generate_with_atlas(self.args, "1:1", "test-key")

        post.assert_called_once()


if __name__ == "__main__":
    unittest.main()
