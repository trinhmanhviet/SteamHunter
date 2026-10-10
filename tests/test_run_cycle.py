import math,sys,unittest
from pathlib import Path
sys.path.insert(0,str(Path(__file__).resolve().parents[1]))
from tools.run_cycle import foot_pose

class RunCycleTests(unittest.TestCase):
    def test_wrap_has_no_pose_jump(self):
        for a,b in zip(foot_pose(0),foot_pose(1)):
            self.assertAlmostEqual(a,b)
        for a,b in zip(foot_pose(0),foot_pose(1-1e-7)):
            self.assertAlmostEqual(a,b,places=5)
    def test_stance_plants_forefoot_and_travels_back(self):
        front=foot_pose(0);back=foot_pose(.4)
        self.assertEqual(front[1],0);self.assertEqual(back[1],0)
        self.assertLess(front[0],back[0]);self.assertGreater(back[2],front[2])
    def test_swing_lifts_and_returns_to_front(self):
        swing=foot_pose(.70)
        self.assertGreater(swing[1],.1)
        self.assertLess(foot_pose(.95)[0],foot_pose(.45)[0])
    def test_opposite_feet_do_not_both_remain_planted(self):
        for i in range(100):
            a,b=foot_pose(i/100),foot_pose(i/100+.5)
            self.assertTrue(a[1]>0 or b[1]>0)
            self.assertTrue(all(math.isfinite(x) for x in a+b))

if __name__=='__main__':unittest.main()
