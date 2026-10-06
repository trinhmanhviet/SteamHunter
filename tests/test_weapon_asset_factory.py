import sys
import unittest
from pathlib import Path

from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from tools.weapon_asset_factory import build_great_cleaver


class WeaponAssetFactoryTests(unittest.TestCase):
    def test_build_great_cleaver_writes_long_weapon_and_grip_contract(self):
        directory = Path(__file__).resolve().parents[1] / ".test-tmp-weapon-asset"
        directory.mkdir(exist_ok=True)
        try:
            result = build_great_cleaver(directory)
            with Image.open(result["texture"]) as texture:
                self.assertEqual(texture.size, (192, 64))
                bbox = texture.getchannel("A").getbbox()
                self.assertGreater(bbox[2] - bbox[0], 150)
            contract = result["contract"].read_text(encoding="utf-8")
            self.assertIn('"grip"', contract)
            self.assertIn('"skins"', contract)
        finally:
            for path in directory.glob("*"):
                path.unlink()
            directory.rmdir()


if __name__ == "__main__":
    unittest.main()
