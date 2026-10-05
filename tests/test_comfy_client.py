import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from tools.comfy_client import ComfyClient


class ComfyClientTests(unittest.TestCase):
    def test_view_url_encodes_a_completed_image_descriptor(self):
        client = ComfyClient("http://127.0.0.1:8188")

        url = client.view_url({"filename": "frame 01.png", "subfolder": "factory/hunter", "type": "output"})

        self.assertEqual(url, "http://127.0.0.1:8188/view?filename=frame+01.png&subfolder=factory%2Fhunter&type=output")


if __name__ == "__main__":
    unittest.main()
