# Overhead cleaver demo implementation plan

> Execute inline with executing-plans. The user authorized autonomous work and testing.

**Goal:** Deliver and install a playable reference-driven overhead/charge demo.

**Architecture:** Reuse the separate Blender rig, author anatomy-aware key poses,
render body/weapon layers, package sheets and a frame manifest. A small independent
Godot project uses a tested charge/strike state controller and an anchored touch UI.

**Tech Stack:** Blender 4.5.4, Python/Pillow, Godot 4.7.2, Android SDK, ADB, GitHub CLI.

- [x] Add failing native Godot behavior tests plus a minimal controller stub.
- [x] Implement raise/hold/release/strike/settle/recover controller and pass tests.
- [x] Author reference-driven poses in tools/render_overhead_demo.py using the saved
      hunter_heavy_rig.blend, moving feet/hips/torso and separating elbow targets.
- [x] Render and visually inspect key poses first; adjust rig if hands, limbs or
      sword placement fail. Render the full frame set after the pose check.
- [x] Package fixed-size shared-palette body/weapon atlases, metadata, pose board,
      normal and charge GIFs via tools/pack_overhead_demo.py.
- [x] Add independent prototypes/overhead_demo Godot scene, practice target, floating
      right attack stick, desktop equivalents, reset and automatic demo.
- [x] Verify native resources, actual UI events and damage timing. Capture screenshots.
- [x] Export Android/Windows builds. Install org.mistandiron.overheaddemo via ADB,
      test short tap, long charge/release, and target hit on the connected phone.
- [ ] Commit only task-owned source/art (preserve user's untracked clip tool), push,
      create a prerelease with both binaries, and record verification/results.
