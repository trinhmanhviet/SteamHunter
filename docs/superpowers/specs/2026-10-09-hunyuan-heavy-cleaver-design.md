# Hunyuan Hunter Texture and Heavy Cleaver Motion

The user approved the Hunyuan hunter and requested the next proposed step: clean the pixel texture, rig the character, and give the Great Cleaver anticipation, a lowered stance, a committed cut and recovery. Keep the existing native 128px body framing and separate padded weapon layer. Present before/after texture renders, posed rig, animated preview and exported assets after each substantive stage.

## Texture

Apply deterministic cleanup within the previously approved pixel pipeline: remove isolated texture noise with a small median filter and map the UV atlas to a compact design palette. Preserve mesh vertices, UV positions, the face, blond hair, red coat, blue armor and cream scarf. Export a sibling cleaned GLB. Compare actual before/after renders at the same camera. The cleanup is a technical palette/filter pass; it must not repaint the character or regenerate its identity.

## Rig and motion

Use anatomy matched to the Hunyuan mesh rather than reusing the older TRELLIS proportions. Bind the head, fingers and soles rigidly where appropriate; keep lower red coat panels attached to the hips so the knees do not stretch the coat. Constrain both wrists to a shared weapon transform. Use two leg IK chains and fixed foot targets, so pelvis lowering and forward lean bend the knees without sliding the soles. Choose pole orientations from actual evaluated knee positions.

Animate a single 66-frame study at 30 source FPS: ready stance, anticipation, overhead charge and hold, a short committed descent, impact, follow-through and deliberate recovery. Export at a 6-FPS base plus authored fast-action frames. Use a constant camera and scale; crouching naturally shortens the silhouette without per-frame normalization. Make the weapon broad and long with visible steel edge, brass guard and leather handle. Use body holdout when rendering the weapon layer so near hands can occlude the grip.

## Output and checks

Write texture comparisons, rig scene, PNG sequences, separate body/weapon sheets, two hand socket coordinates, weapon tip, durations, phase names, GIF and Godot SpriteFrames resources under the Hunyuan prototype. Check sole displacement, wrist IK error, clipping, hard alpha and shared palette across the actual exported frames. Load both Godot resources in a small isolated validation project. This request completes the art/motion study; gameplay integration and Android release follow after seeing the result.
