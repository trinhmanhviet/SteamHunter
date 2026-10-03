import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "tools"))

from make_audio import build_camp_music, build_swing


class AudioTests(unittest.TestCase):
    def test_camp_music_is_eight_seconds(self):
        self.assertEqual(len(build_camp_music()), 8 * 22050)

    def test_swing_sound_has_audible_samples(self):
        self.assertGreater(max(abs(value) for value in build_swing()), 0.1)


if __name__ == "__main__":
    unittest.main()
