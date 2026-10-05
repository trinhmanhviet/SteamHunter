import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from tools.character_factory_workflow import build_frame_workflow, generate_frame


class CharacterFactoryWorkflowTests(unittest.TestCase):
    def test_build_frame_workflow_uses_master_references_and_pose(self):
        graph = build_frame_workflow(
            ["master.png", "identity.png", "weapon.png", "pose.png"],
            "hold the heavy blade overhead",
            9,
            "factory/hunter/charge_00",
        )

        encoder = graph["5"]["inputs"]
        self.assertEqual(encoder["images"]["image_1"], ["10", 0])
        self.assertEqual(encoder["images"]["image_4"], ["13", 0])
        self.assertIn("Do not redesign", encoder["prompt"])
        self.assertEqual(graph["7"]["inputs"]["seed"], 9)
        self.assertEqual(graph["7"]["inputs"]["latent_image"], ["5", 2])
        self.assertEqual(graph["9"]["inputs"]["filename_prefix"], "factory/hunter/charge_00")
        self.assertEqual(graph["9"]["inputs"]["images"], ["20", 0])
        self.assertEqual(graph["20"]["class_type"], "RMBG")
        self.assertEqual(graph["20"]["inputs"]["image"], ["19", 0])
        self.assertEqual(graph["19"]["class_type"], "ImageRGBA2RGB")

    def test_generate_frame_uploads_each_locked_reference_before_queueing(self):
        client = RecordingClient()

        result = generate_frame(
            client,
            [Path("master.png"), Path("identity.png"), Path("weapon.png"), Path("pose.png")],
            "hold the heavy blade overhead",
            9,
            "factory/hunter/charge_00",
        )

        self.assertEqual(client.uploaded, ["master.png", "identity.png", "weapon.png", "pose.png"])
        self.assertEqual(client.graph["5"]["inputs"]["images"]["image_4"], ["13", 0])
        self.assertEqual(result, {"filename": "frame.png", "subfolder": "factory"})


class RecordingClient:
    def __init__(self):
        self.uploaded = []
        self.graph = None

    def upload_image(self, path):
        self.uploaded.append(path.name)
        return f"upload/{path.name}"

    def queue_and_wait(self, graph):
        self.graph = graph
        return {"filename": "frame.png", "subfolder": "factory"}


if __name__ == "__main__":
    unittest.main()
