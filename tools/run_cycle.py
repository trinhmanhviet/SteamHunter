"""Normalized in-place running foot motion for the existing hunter rig."""
import math

CYCLE_SECONDS=.42


def foot_pose(phase):
    """Return ankle Y, forefoot clearance and heel pitch in actor-height units."""
    phase%=1.0
    if phase<=.42:
        t=phase/.42
        heel=45*max(0,(phase-.30)/.12)
        return (-.26+.52*t,0.0,heel)
    t=(phase-.42)/.58
    smooth=(1-math.cos(math.pi*t))/2
    return (.26-.52*smooth,.18*math.sin(math.pi*t),45*(1-smooth)+15*math.sin(math.pi*t)**2)
