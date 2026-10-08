import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from tools.blender_sprite_contract import ortho_framing, project_ndc, sample_frames, srgb_to_linear


class BlenderSpriteContractTests(unittest.TestCase):
    def test_camera_locks_rest_height_and_ground_without_frame_cropping(self):
        scale, center_z = ortho_framing(2.0)
        ground_ndc = 0.5 - center_z / scale
        head_ndc = 0.5 + (2.0 - center_z) / scale
        self.assertEqual(project_ndc((0.5, ground_ndc)), (64, 116))
        self.assertEqual(project_ndc((0.5, head_ndc)), (64, 12))

    def test_projection_keeps_offscreen_socket_position_for_clipping_detection(self):
        self.assertEqual(project_ndc((1.25, 0.5)), (160, 64))

    def test_sampling_30_fps_at_6_fps_has_no_duplicate_endpoint(self):
        self.assertEqual(sample_frames(1, 30, 30, 6), [1, 6, 11, 16, 21, 26])

    def test_sampling_non_multiple_fps_uses_timestamps(self):
        self.assertEqual(sample_frames(0, 23, 24, 10), [0, 2, 5, 7, 10, 12, 14, 17, 19, 22])

    def test_invalid_calibration_and_sampling_fail_explicitly(self):
        with self.assertRaises(ValueError):
            ortho_framing(0)
        with self.assertRaises(ValueError):
            sample_frames(30, 1, 30, 6)

    def test_decoder_srgb_colour_is_converted_before_linear_blender_display(self):
        self.assertAlmostEqual(srgb_to_linear(0.5), 0.21404114048223255)
        self.assertEqual(srgb_to_linear(0), 0)
        self.assertEqual(srgb_to_linear(1), 1)


if __name__ == "__main__":
    unittest.main()
