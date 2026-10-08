# Clean Hunyuan hunter and heavy-cleaver motion

The selected Hunyuan mesh now has a cleaned UV texture and an authored two-handed heavy-cut study. It is a repeatable art/rig export, not a gameplay integration.

## View

- `../clean_inspection/texture_before_after.png`: identical cameras showing original and cleaned texture, at 512px and native 128px.
- `heavy_cut_preview.gif`: a 2.2-second sequence with stance preparation, overhead hold, quick descent, low impact/follow-through, and recovery.
- `heavy_cut_contact.png`: all 20 selected poses with source-frame/phase labels.
- `rig_skeleton.png`: actual rig projected over the ready stance.
- `hunter_heavy_rig.blend`: editable model, skin weights, IK targets, weapon, camera and source keys.
- `sprites/`: separate body and weapon frames, row-packed atlases, socket/phase/timing JSON and Godot SpriteFrames resources.

The texture cleanup uses a 7px median filter on the 2048px atlas and 22 fixed design colours. Geometry and UV arrays match the source textured GLB. The exported sprite palette adds six weapon colours, for a total of 28. The original source remains available in `../mesh/hunter_textured.glb`; the cleaned sibling is `../mesh/hunter_clean.glb`.

## Rig

The Hunyuan-specific landmarks include the actual lower wrist positions and longer arms. Protected head/hand/sole regions prevent facial distortion and sliding boots. Anatomy-restricted arm weights avoid hip influence; the lower coat's outline and trim follow the same shell as the red cloth. UV seam vertices are joined before binding and weight transitions are smoothed over real mesh edges. Bone heat was evaluated but did not solve all bones on this mesh, so the delivered rig uses deterministic region-restricted segment weights rather than claiming successful automatic heat binding.

Both shin chains target fixed ankle positions and copy the original foot rotation. Lowering the hips and leaning the torso bends the knees while maintaining the soles. Both forearm chains target a shared weapon transform; the hands copy its orientation. The blade has a broad profile, visible steel bevel/spine, brass guard and leather grip. The weapon render uses body depth holdout so nearer hands occlude the grip correctly when the two RGBA layers are composited.

The single camera has a rest calibration of 104px height, body canvas 128px and ground boundary 116. The padded weapon canvas is 256px with offset [-64,-64]; both layers have the same pixels per world unit. No animation frame is independently resized or cropped. Crouching therefore changes the visible height naturally.

## Reproduce

```powershell
.\.tools\hunyuan-env\Scripts\python.exe prototypes\hunyuan_hunter\stylize_texture.py
.\.tools\blender\blender-4.5.4-windows-x64\blender.exe --background --factory-startup --python tools\preview_3d_hunter.py -- prototypes\hunyuan_hunter\mesh\hunter_clean.glb prototypes\hunyuan_hunter\clean_inspection --appearance texture --source-colours linear
.\.tools\blender\blender-4.5.4-windows-x64\blender.exe --background prototypes\hunyuan_hunter\clean_inspection\hunter_inspection.blend --python tools\rig_hunter_heavy.py -- prototypes\hunyuan_hunter\heavy_motion
.\.tools\hunyuan-env\Scripts\python.exe prototypes\hunyuan_hunter\pack_heavy_motion.py
```

## Verification and limits

The exported resources were loaded by Godot in a separate small project: 20 frames per layer and matching 2.2-second timing. Atlases are row-packed below 2048px in either dimension. Every layer has hard alpha and stays inside its canvas; all body alpha bounds end at row 116. Measured wrist-target and sole vertical displacement are below 0.01px across the sampled poses; exact values are in `review.json`.

The pose study intentionally uses a fixed stance. It does not yet include locomotion, dodge, monster reactions or the full Great Cleaver combo set. Source texture lighting/ornament remain in some colour clusters, and gloves/armor still need detailed visual polish before treating the rig as a final production character. Combat event timing will be matched to the existing game actions during integration.
