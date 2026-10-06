import shutil
import sys
import unittest
from pathlib import Path

from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from tools.character_master import derive_reference_crops


class CharacterMasterTests(unittest.TestCase):
    def test_derive_reference_crops_writes_identity_and_equipment_layers(self):
        root = Path(__file__).resolve().parents[1] / ".test-tmp-character-master"
        shutil.rmtree(root, ignore_errors=True)
        root.mkdir()
        try:
            master = Image.new("RGBA", (128, 128), (0, 0, 0, 0))
            for y in range(12, 116):
                for x in range(46, 82):
                    master.putpixel((x, y), (210, 77, 57, 255))
            path = root / "master_side.png"
            master.save(path)

            outputs = derive_reference_crops(path, root / "reference")

            self.assertEqual(set(outputs), {"identity", "equipment", "full"})
            self.assertTrue(all(path.exists() for path in outputs.values()))
            for output in outputs.values():
                with Image.open(output) as image:
                    self.assertEqual(image.size, (128, 128))
        finally:
            shutil.rmtree(root, ignore_errors=True)


if __name__ == "__main__":
    unittest.main()
