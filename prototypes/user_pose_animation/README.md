# User-authored Great Cleaver animation — 0.10.19

`user_poses.blend` archives the user's three saved edits at frames 1/15/30.
The editable workspace file is not overwritten by baking or promotion.

`tools/render_user_pose_animation.py` preserves the user's sword angles and
body/foot poses, with a minimal 4–6px grip adjustment at the three keys to fit
both arms without stretching. A subpixel correction plants the front foot.
The lifted rear leg remains as authored by the user.

The existing phase contract is retained: 74 cells, ready/raise, 12 held cells,
rear-to-overhead release, three strike cells, follow-through and recovery.
The blade rises over the head before the committed cut. Held charge stays in
the rear pose, with subtle body breathing rather than advancing into the cut.

## Files

- `fitted_keys.png`: the three user's poses after grip fitting.
- `motion/`: separate body/sword frames, editable baked scene, projected blade
  geometry and timing-correct previews.
- `assets/`: packed body/weapon atlases and the matching frame manifest.
- `motion/review.json`: clipping, hand contact and export verification.

## Reproduce

Use the bundled Blender on `user_poses.blend` with
`tools/render_user_pose_animation.py -- prototypes/user_pose_animation/motion`.
Run the existing packer with `DIRECTORY` set to this `motion` folder and
`ASSETS` to this `assets` folder. Promotion accepts that asset directory and
an explicit source description. No global or Comfy dependencies are changed.

Next editor session: shoulder, head, knee, sword tip and pommel handles were
requested. Those handles are not implemented by this animation bake.
