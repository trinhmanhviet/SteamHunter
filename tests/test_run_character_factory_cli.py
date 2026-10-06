import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "tools"))

from run_character_factory import build_parser


class CharacterFactoryCliTests(unittest.TestCase):
    def test_cli_uses_local_comfy_by_default(self):
        args = build_parser().parse_args(["art/characters/hunter/character.json"])
        self.assertEqual(args.comfy_url, "http://127.0.0.1:8188")
        self.assertEqual(args.definition, Path("art/characters/hunter/character.json"))


if __name__ == "__main__":
    unittest.main()
