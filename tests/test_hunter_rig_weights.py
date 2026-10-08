import sys
import unittest
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from tools.hunter_rig_weights import LANDMARKS, compute_weights


class HunterRigWeightsTests(unittest.TestCase):
    def test_face_and_solids_do_not_follow_torso_or_knee_deformation(self):
        points = np.array([[0, 0, .93], [-.12, -.06, .025], [.12, -.06, .025]])
        names, weights = compute_weights(points)
        self.assertEqual(weights[0, names.index("head")], 1)
        self.assertEqual(weights[1, names.index("foot.R")], 1)
        self.assertEqual(weights[2, names.index("foot.L")], 1)

    def test_red_coat_panel_moves_with_hips_instead_of_stretching_with_knee(self):
        points = np.array([[-.11, -.03, .40], [-.190, -.045, .40], [-.191, -.045, .399]])
        colours = np.array([[.68, .22, .14], [.68, .22, .14], [.89, .62, .18]])
        names, weights = compute_weights(points, colours)
        np.testing.assert_array_equal(weights[:, names.index("hips")], [1, 1, 1])

    def test_dark_red_gloves_are_bound_to_hands_even_when_colour_matches_coat(self):
        points = np.array([[-.245, -.06, .42], [.245, -.06, .42]])
        colours = np.array([[.404, .141, .11], [.404, .141, .11]])
        names, weights = compute_weights(points, colours)
        self.assertEqual(weights[0, names.index("hand.R")], 1)
        self.assertEqual(weights[1, names.index("hand.L")], 1)

    def test_weights_are_normalized_and_right_leg_does_not_attach_to_left_leg(self):
        points = np.array([[-.11, 0, .25], [.11, 0, .25], [-.21, 0, .61]])
        names, weights = compute_weights(points)
        np.testing.assert_allclose(weights.sum(axis=1), 1)
        self.assertTrue(np.all(weights >= 0))
        self.assertEqual(weights[0, names.index("shin.L")], 0)
        self.assertEqual(weights[1, names.index("shin.R")], 0)

    def test_forearm_surface_cannot_borrow_hip_weights(self):
        names, weights = compute_weights(np.array([[-.22, -.04, .52]]), np.array([[.36, .525, .71]]))
        self.assertEqual(weights[0, names.index("hips")], 0)
        self.assertAlmostEqual(sum(weights[0, names.index(name)] for name in ("upper_arm.R", "forearm.R", "hand.R")), 1)

    def test_outer_coat_outline_remains_with_hips_when_texture_is_dark_blue(self):
        names, weights = compute_weights(np.array([[-.19, -.08, .37]]), np.array([[.08, .106, .169]]))
        self.assertEqual(weights[0, names.index("hips")], 1)


if __name__ == "__main__":
    unittest.main()
