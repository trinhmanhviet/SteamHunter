# Blender Sprite Prototype

## Approved scope

The user approved starting the small 3D-to-2D experiment proposed on October 7. Produce a neutral character reference, prepare local image-to-3D tooling, and render one humanoid rig with an original heavy-cleaver motion at 128 x 128. Keep outputs in `prototypes/blender_hunter`, on `codex/3d-sprite-prototype`, until the user reviews the art. The user then explicitly selected ChatGPT ImageGen for the character art: designs must be simple, visually distinct, and fit the game's world.

## Production contract

Use a single orthographic camera and constant world-to-pixel scale across all clips. Calibrate the rest height to 104 pixels and world ground to image row 116. Never crop or resize each animation frame independently: crouching and raising arms must change the visible bounds naturally. Render transparent body frames separately from weapon frames using one rig and matching camera. Project two explicit grip sockets and weapon tip, including a 2D orientation and front/back order for each frame. Quantize every frame with one palette and hard alpha. Export PNG sequences, sprite sheets, animation metadata, a Godot SpriteFrames resource, a static contact sheet, and an animated preview.

## Dependency strategy

Use portable Blender 4.5 LTS in `.tools/blender`, verified against the official SHA256. Investigate TRELLIS Windows dependencies in `.tools/trellis-source`, without installing into the existing embedded ComfyUI Python 3.12 / Torch 2.9.1 environment. That plugin explicitly warns about embedded Python compatibility. A working fixture rig provides renderer validation only; it is not evidence that AI mesh topology, deformation, or visual quality has passed.

## Motion and image requirements

Begin with idle and one original two-handed heavy-cleaver swing: anticipation, raised charge, committed descent, impact, and recovery. Store source timing at 30 FPS and output timing per frame; sample at 6 FPS for this experiment, with provision for shorter impact frames. The mesh creation reference is one front A-pose, without weapon, long coat tails, hair occluding arms, or baked directional shadows. Preserve the hunter's blond hair, red coat, blue armor, and cream scarf.

The selected ImageGen reference is `prototypes/blender_hunter/reference/master_apose_imagegen.png`. It uses a plain white background after transparent-output attempts retained glow outside the silhouette. Its provenance is recorded beside the image. This reference has not been converted to a mesh, rigged, or approved as final game art.

## Acceptance and uncertainty

The renderer must run twice deterministically, keep ground/socket alignment, preserve the same rig across frames, and export both body and weapon layers. The user reviews the native-size animated output before replacing any runtime art. A model generated from the master must separately pass silhouette and deformation checks; TRELLIS and Mixamo are not assumed to solve those automatically. If the generated mesh cannot be rigged cleanly, stop that route and report the mesh problem with an image.
