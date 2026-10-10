"""Small geometric helper for keeping a two-handed grip within arm reach."""
import math


def fit_grip_position(point,discs):
    """Closest Y/Z point inside both arms' reachable discs; no limb stretching."""
    if len(discs)!=2 or any(r<=0 for _,_,r in discs):
        raise ValueError('Expected two positive reach discs')
    def inside(p):
        return all(math.hypot(p[0]-y,p[1]-z)<=r+1e-8 for y,z,r in discs)
    if inside(point):return tuple(point)
    candidates=[]
    for y,z,r in discs:
        dy,dz=point[0]-y,point[1]-z;distance=math.hypot(dy,dz)
        if distance:
            candidate=(y+dy*r/distance,z+dz*r/distance)
            if inside(candidate):candidates.append(candidate)
    ay,az,ar=discs[0];by,bz,br=discs[1]
    dy,dz=by-ay,bz-az;distance=math.hypot(dy,dz)
    if distance and abs(ar-br)<=distance<=ar+br:
        along=(ar*ar-br*br+distance*distance)/(2*distance)
        perpendicular=math.sqrt(max(0,ar*ar-along*along))
        cy,cz=ay+along*dy/distance,az+along*dz/distance
        for sign in (-1,1):
            candidate=(cy-sign*perpendicular*dz/distance,cz+sign*perpendicular*dy/distance)
            if inside(candidate):candidates.append(candidate)
    if not candidates:raise ValueError('No common arm reach for this grip')
    return min(candidates,key=lambda p:math.dist(p,point))
