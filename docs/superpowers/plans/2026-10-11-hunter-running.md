# Hunter Running and Forward Idle Implementation Plan

> **For agentic workers:** Execute inline using executing-plans.

**Goal:** Add a readable run cycle with the Great Cleaver on the back, and a
forward-pointing held idle after stopping, while retaining accepted combat art.

**Architecture:** Reuse the current fixed-camera rig with rigid armor. Render a
12-cell run, forward idle and four stopping/draw cells as separate layers. Append
these cells after the 74 accepted combat cells in the existing atlases. Select
locomotion only when no attack or charge is active; movement determines cadence.
No delayed input or damage is introduced by sheathing/drawing visuals.

**Reference correction:** The user supplied two idle images and one diagonal
back-carry image. Idle must brace wide legs with the hilt low and blade angled
upward in front. The back attachment runs from one shoulder toward the opposite
hip in 3D. Re-author only ready/raise/recovery around this idle; retain the
accepted hold, release, strike and follow-through cells byte-for-byte. Charge
must stop horizontal movement and ignore jump/facing movement input.

**Tech Stack:** Bundled Blender/Godot, isolated Python, existing ADB/GitHub tools.

### Art

- [x] Write/run failing `tests/test_run_cycle.py` for opposite foot phases,
  continuous wrapping, planted stance and swing clearance.
- [x] Create `tools/run_cycle.py` and `tools/render_hunter_locomotion.py`.
  The stride alternates feet with raised swing knees, opposite arm swings,
  modest torso lean and rigid spine-mounted weapon.
- [x] Render idle, two contacts and passing pose first; inspect blade mounting,
  knee/ankle orientation, armor and hands. Show the result.
- [x] Bake all cells; export body/weapon with body depth holdout and metadata.
  Pack a loop GIF, append to combat sheets and verify old decoded cells unchanged.

### Runtime

- [x] Write/run failing `tests/test_hunter_locomotion.gd`: moving cycles run
  cells, stopping reaches held idle, attack/charge overrides movement and left
  facing mirrors both layers. Running/idle cannot emit sword damage.
- [x] Add metadata selection/state to `scripts/hunter.gd`/`cleaver_art.gd`.
  Use actual horizontal speed to advance run phase, a .16s draw after stopping,
  and preserve weapon routing/charge/recovery semantics.
- [x] Run the new tests and existing relevant combat/character suites.

### Delivery

- [x] Build/install 0.10.20, test run/stop/left-right and a charge after running
  on the connected phone, inspect video and check APK/log/hash.
- [x] Commit/push scoped files and publish APK/GIF/video release.

## Scope checks

The current user-edited Blender workspace is preserved. No pose editor is
opened during this asset bake, so its requested extra controls remain a separate
next-editor requirement. This task adds running/idle art, not new attacks.
