# Hunyuan Heavy Cleaver Art and Motion Plan

> Execute in this session using executing-plans. The texture/rig proposal has been approved by the user; do not ask again or dispatch agents into shared Blender state.

**Goal:** Produce cleaner Hunyuan hunter art and a reviewable heavy-cleaver animation with fixed feet and two-hand grip.

**Architecture:** A prototype texture cleanup script preserves geometry/UVs and produces a palette-controlled sibling GLB. A pure skin-weight helper and Blender rig script create protected facial/sole regions, leg IK, shared hand/weapon targets and authored timing. A packer exports real rendered layers and review images.

**Tech Stack:** isolated Hunyuan Python environment, NumPy/Pillow/trimesh, portable Blender 4.5.4, Godot 4.7.

- [x] Clean the UV texture, export sibling GLB and render/show before/after views. Geometry/UV equality verified.
- [x] Write checks for head/sole/coat/hand protection and normalization, then implement the weighting helper.
- [x] Build the matched Hunyuan rig, foot targets, wrist targets and visible heavy blade materials.
- [x] Author ready/anticipation/charge/impact/recovery motion with lowered hips, torso lean and fixed soles.
- [x] Render and review the rig/layers; fix glove/coat classification, outline bindings and weight discontinuities. Bone heat was tested and failed on some bones; use anatomy-restricted segment weights with protected regions and mesh-edge smoothing.
- [x] Export sprites, variable frame durations, phase/socket metadata, preview GIF and contact sheet. Row-pack the two atlases for small texture dimensions.
- [x] Verify actual sole/wrist displacement, clipping/palette and native Godot resource timing. 20 frames, 2.2 seconds, 28 colours; sole/wrist errors below 0.01px; no clipping; all feet at boundary 116.
- [x] Record limitations and save repeatable commands. Commit and push after the final diff check.
