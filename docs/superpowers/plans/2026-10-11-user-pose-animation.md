# User Pose Animation Implementation Plan

> **For agentic workers:** Execute inline using executing-plans.

**Goal:** Use the user's three edited poses for the Great Cleaver animation,
verify grip/armor/sword collision and publish/install the Android build.

**Architecture:** Archive the user's editable Blender file without overwriting
it. Reuse the existing 74-cell phase layout, body/sword layers and Godot timing.
Author the charge, release and contact around the three user keys, retaining
the reference clip's overhead path. Fit unreachable grips with the smallest
anatomical adjustment justified by measured reach. Export geometry from the
same visible metal, pack and promote together after verification.

**Tech Stack:** Bundled Blender/Godot, isolated Python, existing ADB/GitHub tools.

### Tasks

- [x] Archive the saved user scene and record pose data; inspect shoulder-to-grip
  distance before deciding how to correct hand gaps.
- [x] Write/run a failing check for hand reach in the source poses; create
  `tools/render_user_pose_animation.py` with phase sampling and fitted grips.
- [x] Render key frames first and inspect them, then export all 74 paired layers.
- [x] Pack atlases and GIFs with existing packer; show the animation result.
- [x] Promote the verified art; run the existing 16 relevant Godot suites.
- [x] Build v0.10.19, install on ADB, test stationary holds and physical contact.
- [x] Commit/push source, publish APK/GIF/phone video release and verify hashes.

### Next pose-tool session

The user requested controls at both shoulders, head, both knees, sword tip and
pommel in addition to existing hip/torso/feet. These are future editor controls,
not extra moves for this animation. Tip/pommel manipulation must preserve sword
length and the grip relationship. Preserve the user's pose file.
