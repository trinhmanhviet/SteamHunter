import json
import shutil
import sys
import unittest
from pathlib import Path

from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from tools.character_factory_runner import run_factory


class CharacterFactoryRunnerTests(unittest.TestCase):
    def test_run_factory_writes_frames_sheet_report_and_spriteframes(self):
        root = Path(__file__).resolve().parents[1] / "art" / ".test-tmp-character-factory-runner"
        shutil.rmtree(root, ignore_errors=True)
        (root / "reference").mkdir(parents=True)
        (root / "poses" / "idle").mkdir(parents=True)
        try:
            master = make_figure((210, 77, 57, 255))
            master.save(root / "reference" / "master_side.png")
            Image.new("RGBA", (128, 128), (0, 0, 0, 0)).save(root / "poses" / "idle" / "00.png")
            definition = {
                "character": "test_hunter",
                "sprite_size": [128, 128],
                "target_height": 104,
                "ground_y": 116,
                "pivot": [64, 116],
                "palette_colors": 32,
                "max_retries": 1,
                "references": ["reference/master_side.png"],
                "animations": {"idle": [{"frame": "00", "pose": "stand", "template": "poses/idle/00.png"}]},
            }
            definition_path = root / "character.json"
            definition_path.write_text(json.dumps(definition), encoding="utf-8")

            output = run_factory(definition_path, FakeClient(master))

            self.assertTrue(output["sheet"].exists())
            self.assertTrue(output["metadata"].exists())
            self.assertTrue(output["spriteframes"].exists())
            self.assertTrue(output["preview"].exists())
            report = json.loads(output["report"].read_text(encoding="utf-8"))
            self.assertEqual(report["frames"]["idle/00"]["errors"], [])
        finally:
            shutil.rmtree(root, ignore_errors=True)


class FakeClient:
    def __init__(self, source):
        self.source = source

    def upload_image(self, path):
        return Path(path).name

    def queue_and_wait(self, _workflow):
        return {"filename": "frame.png", "subfolder": "", "type": "output"}

    def download_image(self, _image, destination):
        destination.parent.mkdir(parents=True, exist_ok=True)
        self.source.save(destination)
        return destination


def make_figure(color):
    image = Image.new("RGBA", (128, 128), (0, 0, 0, 0))
    for y in range(10, 110):
        for x in range(45, 85):
            image.putpixel((x, y), color)
    return image


if __name__ == "__main__":
    unittest.main()
