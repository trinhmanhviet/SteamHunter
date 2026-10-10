"""Check the actual exported pictures/geometry, not just rig target coordinates."""
import json,sys
from pathlib import Path
from PIL import Image

directory=Path(sys.argv[1]);data=json.loads((directory/'render.json').read_text())
running=[f for f in data['frames'] if f['phase']=='run']
pictures={Image.open(directory/f['body']).convert('RGBA').tobytes() for f in running}
assert len(pictures)>=min(4,len(running)),f'Run did not articulate: only {len(pictures)} distinct body pictures'
for frame in data['frames']:
    center=sum(p[0] for p in frame['blade_polygon'])/len(frame['blade_polygon'])
    if frame['phase']=='run':assert center<64,('Back-mounted sword ended up in front',frame['cell'],center)
    if frame['phase']=='idle':
        assert center>64,('Held idle is not pointing forward',center)
        tip=max(frame['blade_polygon'],key=lambda p:(p[0]-frame['weapon_origin'][0])**2+(p[1]-frame['weapon_origin'][1])**2)
        assert tip[1]<frame['weapon_origin'][1],('Reference idle must point diagonally upward',tip)
    assert max(frame['wrist_error_pixels'].values())<.5
print('LOCOMOTION_EXPORT: articulated cycle, back-mounted running sword, forward idle, reachable hands')
