# Hunter pose workspace trial — 2026-10-11

The user approved a trial of a prepared Blender file, with three Great Cleaver
poses and direct controls, instead of developing a separate application.

## Delivered

- `prototypes/hunter_pose_workspace/hunter_pose.blend`: self-contained textures,
  original character/sword, hold/cut/end poses at frames 1/15/30.
- `tools/open_hunter_pose.cmd`: bundled Blender launcher, isolated preferences.
- `tools/hunter_pose_ui.py`: session-local controls/presets/reset/export panel.
- `tools/prepare_hunter_pose_workspace.py`: reproducible preparation from the
  tracked v0.10.18 rig and archived pose controls; no reliance on untracked drafts.
- Native game-scale PNGs and 4x views, `pose_review.png`, `workspace.png`, short
  Vietnamese guide and machine-readable verification.

## Rig corrections

The old front shin's original front axis turned toward +X (0.9836), away from
the -X side camera. Position-only knee pole selection failed to constrain axial
rotation. A forward rest knee bend and aligned bone rolls now define the correct
hinge, with a fixed native pole angle and poles following the hip/foot controls.

Four metal surface pieces were extracted without changing their UVs. Each is
rigidly attached to its shin. The adjacent cloth shares the same attachment at
the boundary: an initial 1.76px seam error was reproduced and corrected.

Feet have forefoot controllers; ankle targets are their children, so rotating a
heel keeps its forefoot fixed. Sword movement drives both hand targets.

## Verification

`tests/check_pose_workspace.py` failed on the original held scene for the known
shin twist, then passed on the prepared scene. It checks three poses for axial
twist, wrist reach, foot contact, approved sword transform, rigid armor edge
lengths, closed armor/cloth seams, moved-foot stability and packed images.

Native GUI operator smoke testing verified preset selection, control selection,
reset, translation with automatic key persistence, heel rotation preserving the
forefoot, and exporting actual transparent PNGs. `ui_verification.json` records
the checks. `workspace.png` captures the working Blender interface.

The 12 existing Python rig/sprite contract tests also passed. Native automatic
key insertion emits messages for locked transform channels; unlocked channel
changes and their persistence are verified. Blender reports a small allocator
shutdown diagnostic after replacing mesh data in the preparation process; scene
reopening and deformation checks succeed.

## Limits

These are three editable key poses, not a finished combat animation. The middle
cut reuses the supplied video frame 31; the two sword endpoints retain the user
accepted positions. Arbitrary extreme edits can exceed limb reach or occlude
armor. The trial does not update the production sprite atlases or Android APK.
