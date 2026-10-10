# Hunter Pose Workspace Implementation Plan

> **For agentic workers:** Use executing-plans inline for this approved trial.

**Goal:** Deliver an immediately usable Blender file with three Great Cleaver
poses, direct manipulation controls, intact rigid leg armor, and a short
Vietnamese guide. The Android build is outside this trial.

**Architecture:** Reuse the approved model, sword, side camera, and corrected
foot contacts. Correct native leg IK orientation, extract the existing armor
surfaces into rigid bone attachments, and expose existing controls in a saved
workspace. Ship editable poses and reproducible native/pixel previews.

**Tech Stack:** Bundled Blender 4.5.4, its Python API, isolated Pillow/NumPy.

### Task 1 — Reproduce and correct leg rotation

- [x] Add `tests/check_pose_workspace.py`: on the prior held scene verify that
  the front shin's original front direction does not turn away from the side
  camera. Run it against the old scene and observe the reported failure.
- [x] Inspect rest bone axes and native IK settings; configure a hinge-oriented
  leg with stable pole/rotation. Preserve sword transforms and grip contacts.
- [x] Check the held and finishing poses and a moved-foot sample: no knee flip,
  no large axial twist, forefoot contact and wrist reach remain valid.

### Task 2 — Prepare editable workspace

- [x] Create `tools/prepare_hunter_pose_workspace.py`: separate existing metal
  leg surfaces by shin/knee and anatomical side, preserving UVs, and attach each
  rigidly to its joint. Check attachment edge lengths across poses.
- [x] Expose colored foot, hip, sword, and torso controls; lock irrelevant axes
  for side-view posing, add readable pose markers and three saved key poses.
- [x] Set camera view, material display, control selection, timeline and a
  Vietnamese help text in `prototypes/hunter_pose_workspace/hunter_pose.blend`.
- [x] Add launcher `tools/open_hunter_pose.cmd` and a short guide. No installer
  or global dependency changes.

### Task 3 — Verify and show results

- [x] Run `tests/check_pose_workspace.py` against the prepared file, including
  control movement, armor rigidity, hand grip and saved pose checks.
- [x] Render three poses at native pixel scale and 4x inspection scale; inspect
  armor visibility, knee/ankle shape and approved blade endpoints.
- [x] Smoke test the saved UI controls/export workflow and verify the file
  reopens with packed textures and helpers available.
- [x] Show the pose sheet, provide launcher/file links and concise controls;
  commit and push only this trial's files after successful verification.

## Review

Scope is the approved Blender trial, with three key poses. Existing game assets
and the APK remain separate from it until the visual results are reviewed. User
clip-tool files and older preview drafts are preserved.
