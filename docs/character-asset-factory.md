# Character Asset Factory

Factory assets are layered so a character pose never contains a weapon. `character.json` records the common canvas, ground line, locked palette, pose frames, and attachment point for each hand-held item.

## Create an approved master

```powershell
py -3 tools\create_character_master.py art\characters\great_cleaver_hunter\character.json
```

This makes the master and reference crops. Review the master before generating poses.

## Generate body poses

```powershell
py -3 tools\run_character_factory.py art\characters\great_cleaver_hunter\character.json
```

The runner uploads the selected references to local ComfyUI, retries rejected frames, writes raw and accepted frames, packs a sprite sheet, produces a Godot `SpriteFrames` resource, and writes a checker-backed preview. `attachment_points.right_hand` is exported in the animation JSON so gameplay can position any compatible weapon skin on the same pose.

## Weapon skins

Weapon art belongs below `art/weapons/<weapon>/`. Each weapon contract declares a canvas, named grip pixel, and available skins. The Great Cleaver base and Ember skin share a grip at `[28, 45]`; replacing a skin never changes body art.
