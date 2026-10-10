import sys
import unittest
from pathlib import Path
import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from tools.hunter_rig_weights import LANDMARKS, lower_leg_weights


class LegArmorBindingTests(unittest.TestCase):
    def test_greaves_follow_one_shin_without_foot_or_opposite_leg_weights(self):
        names = list(LANDMARKS)
        weights = lower_leg_weights(np.array([[-.11, 0, .20], [.11, 0, .20]]), names)
        self.assertEqual(weights[0, names.index('shin.R')], 1)
        self.assertEqual(weights[1, names.index('shin.L')], 1)
        self.assertEqual(np.count_nonzero(weights[0]), 1)
        self.assertEqual(np.count_nonzero(weights[1]), 1)

    def test_boots_are_rigid_and_joint_blends_stay_normalized(self):
        names = list(LANDMARKS)
        points = np.array([[-.12, -.05, .06], [-.12, 0, .145], [.11, 0, .2875]])
        weights = lower_leg_weights(points, names)
        self.assertEqual(weights[0, names.index('foot.R')], 1)
        self.assertGreater(weights[1, names.index('shin.R')], 0)
        self.assertGreater(weights[1, names.index('foot.R')], 0)
        self.assertGreater(weights[2, names.index('thigh.L')], 0)
        self.assertGreater(weights[2, names.index('shin.L')], 0)
        np.testing.assert_allclose(weights.sum(axis=1), 1)


if __name__ == '__main__':
    unittest.main()
