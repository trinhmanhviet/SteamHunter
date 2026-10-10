# Current hunter art pipeline

Production uses the approved Hunyuan -> Blender -> 2D overhead set from Great
Cleaver Demo 0.1.0. The old four-pose body, stand-alone sword skins and rejected
Great Cleaver source images have been retired from art/.

## Active assets

- art/characters/hunter/body_atlas.png: 74 body frames, 128px cells.
- art/characters/hunter/overhead_frames.json: paired regions and phase lists.
- art/weapons/great_cleaver/overhead_atlas.png: weapon frames, 384px cells.
- art/characters/hunter/great_cleaver_portrait.png: approved forge preview.

Body pivot is [64,116], weapon pivot [192,244]. Both layers share world scale and
mirror around the actor origin. Weapon images include the body depth mask so the
nearer hand remains in front of the blade. Never normalize each frame by its
changing visible bounding box.

## Rebuild and promote

Run the saved base rig through tools/render_overhead_demo.py, pack the layers
with tools/pack_overhead_demo.py, then run tools/promote_hunter_art.py. Exact
Blender and isolated Python commands are in prototypes/overhead_demo/README.md.
The legacy generate_great_cleaver_poses.py entry now only promotes this approved
set, so it cannot regenerate the retired art. Generic 2D factory helpers remain
available for other assets but are not this hunter's active pipeline.

The current authored motion is one overhead attack and a charge loop. Other
Great Cleaver moves use the new poses aligned to their existing hit timing until
their own references are authored. Other weapon classes, monsters and environments
retain current art where no approved replacement exists. Original master images
and Hunyuan/Blender generation inputs remain available for regeneration.
