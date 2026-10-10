# Great Sword — reference skeleton review

12 manual screen-space pose sketches from the user-supplied clip and extracted frames.
Frame IDs: 23, 24, 26, 28, 29, 30, 31, 32, 40, 68, 76, 84.
The user's follow-up correction selects frame 26 for the held rear charge pose;
frames 28/29 are the transition after release, not the charge hold.
The earlier portion contains the video transition effect; frame 23 is a clearer starting view.

- `charge_reference_comparison.png`: enlarged body overlay / skeleton for frames 26 and 29.
- `skeleton_keyframes.png`: twelve poses with full blade direction.
- `body_keyframes.png`: body enlargement at a shared scale; blade cropped where needed.
- `reference_overlays.png`: the same landmarks over the original frames.
- `overlay_*.png`, `skeleton_*.png`, `skeleton_*.svg`: individual frame drawings.
- `poses.json`: hand-annotated coordinates in the original 640x360 image plane.

Cyan: camera-near limbs; coral: camera-far limbs; white: head/trunk; gold: blade guide.
Dashed connections indicate occlusion/estimated joint centers under armor. This is a
pose sketch, not an exact motion capture measurement or a solved 3D skeleton.
The clip's perspective is retained; near/far labels must not be treated as anatomical
left/right without a separate 3D interpretation. The ornate sword bends, so its blade
and handle guides are separate. No interpolation between the twelve sketches is included.

These are review drawings, not production game assets. Regenerate with the project's
isolated Python: `.tools/hunyuan-env/Scripts/python.exe prototypes/reference_skeleton/draw.py`.
