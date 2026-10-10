# Great Cleaver locomotion and reference idle — 0.10.20

Reuses the current hunter and rigid leg armor. User reference images define a
wide braced idle with a low two-handed grip and blade angled upward in front.
The sheathed weapon crosses from one shoulder toward the opposite hip in 3D.

## Art

- `motion/`: 12 run cells, one reference idle, four .16s stopping/draw cells,
  paired layers, editable locomotion rig and previews.
- `combat_transitions/`: only ready/raise/recovery, authored around the new idle.
  This partial Blender study is not a full combat timeline.
- `combat_motion/`: complete render table combining the new transitions and
  accepted hold/release/contact/follow-through pictures.
- `combat_assets/`: 74 combat cells; 51 protected original cells and their
  contact geometry remain identical to 0.10.19.
- `assets/`: final 91-cell body/weapon sheets and runtime manifest.

Run cycle is .42s at full speed. Planted foot travel approximately matches
movement at 225 logical px/s; the other knee rises through swing, and arms swing
opposite the legs. The rigid weapon follows the spine.

## Reproduce

1. Run bundled Blender on `prototypes/user_pose_animation/motion/overhead_rig.blend`
   with `tools/render_hunter_locomotion.py -- prototypes/hunter_locomotion/motion`.
2. Run Blender on the archived `prototypes/user_pose_animation/user_poses.blend`
   with `tools/render_user_pose_animation.py -- prototypes/hunter_locomotion/combat_transitions`
   plus `--idle-controls prototypes/hunter_locomotion/motion/render.json --transitions-only`.
3. Run `tools/pack_hunter_combat_transitions.py`, then `tools/pack_hunter_locomotion.py`.
4. Promote the final asset directory with `tools/promote_hunter_art.py`.

This does not overwrite the user's editable pose workspace or require changes
to global/Comfy environments. No pose editor is opened by these baking scripts.
