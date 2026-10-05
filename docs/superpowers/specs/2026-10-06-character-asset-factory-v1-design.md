# Character Asset Factory v1

## Goal

Produce stable, original 128 × 128 pixel character frames for Mist & Iron from a locked master character, pose templates, and Qwen Image 2.1 reference editing. The first production target is the Great Cleaver hunter.

## Problem

Generating each combat pose from a text prompt produces a different person in each frame. A fixed seed does not reliably preserve hair, face, proportions, clothing, weapon geometry, or palette.

## Scope

Factory v1 builds a reusable local toolchain. It accepts a character definition JSON and emits per-frame PNGs, a packed sprite sheet, Godot animation metadata, a master palette, and a QA report. It generates only the animations named in the definition. Great Cleaver starts with idle, charge, strike, and recovery, then can grow through the same manifest.

## Architecture

### 1. Master character

The master is a Qwen Image 2.1 side-view PNG plus derived reference crops: identity, equipment, and weapon. The side master is the mandatory reference for every generated frame. Character definition locks the identity description, clothing, weapon, native canvas, target height, ground line, pivot, palette size, and animation manifest.

### 2. Frame generation

The generator uploads the master references and a pose template to ComfyUI. The Qwen Image 2.1 `TextEncodeQwenImage21` node receives them as image references. Each prompt explicitly tells Qwen to preserve identity, equipment placement, proportions, weapon design, and palette while using the final reference only for pose. Frame requests use right-facing side view and transparent-ready plain imagery.

The local workflow uses the installed `qwen_image_2.1_int8_convrot.safetensors`, `qwen3vl_8b_int8_convrot.safetensors`, and `qwen_image_2.1_vae_bf16.safetensors`. It remains a plain ComfyUI API graph so the Python process can submit, wait, download, and retry without UI actions.

### 3. Normalization and QA

Post-processing removes the background alpha, finds the visible bounding box, scales the figure to target height, aligns its feet to the configured ground line, applies the locked master palette, and pixel-quantizes the result. QA rejects frames with a wrong canvas, invalid/empty alpha bounds, unsupported palette count, figure height outside tolerance, feet outside tolerance, or alpha touching the border. Each rejected frame retries up to the manifest limit, and its report names the failed checks.

### 4. Exports

The factory writes files under `art/characters/<character-id>/`:

```text
reference/master_side.png
reference/identity.png
reference/equipment.png
reference/weapon.png
poses/<animation>/<frame>.png
frames/<animation>/<frame>.png
sprites/<character-id>_spritesheet.png
sprites/<character-id>_animations.json
sprites/<character-id>_palette.png
reports/<character-id>_qa.json
```

The JSON metadata records frame rectangles, FPS, pivot, ground line, and animation order. Godot will read the packed texture in a subsequent integration pass; the asset tool has no runtime dependency on Godot.

## Great Cleaver Definition

- Canvas: 128 × 128.
- Target hunter height: 104 px, tolerance ±2 px.
- Ground line and pivot Y: 116.
- Pivot X: 64.
- Palette: maximum 32 colors from the locked master.
- Direction: right.
- Initial animation manifest: idle, charge, heavy_strike, recovery; one frame each while the game uses four combat states.

## Acceptance Criteria

1. A command can validate a definition without contacting ComfyUI.
2. A command can normalize and QA existing source frames deterministically.
3. Factory output uses one locked palette and a shared ground/pivot across every accepted frame.
4. The ComfyUI graph supports one to ten reference images with Qwen Image 2.1.
5. A failed quality check is reported and retried independently of other frames.
6. The packer emits a sprite sheet and JSON map that Godot can consume.
