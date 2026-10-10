import math,sys,unittest
from pathlib import Path
sys.path.insert(0,str(Path(__file__).resolve().parents[1]))
from tools.pose_motion import fit_grip_position

class PoseMotionTests(unittest.TestCase):
    def test_reachable_position_is_unchanged(self):
        self.assertEqual(fit_grip_position((0,.2),[(0,0,1),(0,.5,1)]),(0,.2))
    def test_projects_to_one_arm_boundary(self):
        point=fit_grip_position((2,0),[(0,0,1),(0,0,2)])
        self.assertAlmostEqual(point[0],1);self.assertAlmostEqual(point[1],0)
    def test_fits_both_arms_when_each_single_projection_violates_the_other(self):
        point=fit_grip_position((0,3),[(-.7,0,1),(.7,0,1)])
        self.assertAlmostEqual(point[0],0)
        self.assertAlmostEqual(point[1],math.sqrt(1-.7**2))
    def test_incompatible_grips_fail_explicitly(self):
        with self.assertRaises(ValueError):fit_grip_position((0,0),[(-2,0,.5),(2,0,.5)])

if __name__=='__main__':unittest.main()
