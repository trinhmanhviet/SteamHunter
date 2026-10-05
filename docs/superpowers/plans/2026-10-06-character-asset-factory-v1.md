# Character Asset Factory v1 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a local Qwen Image 2.1 character-asset pipeline that generates, normalizes, validates, and packs stable 128px game sprites.

**Architecture:** `tools/character_factory.py` owns definition parsing, ComfyUI transport, frame normalization, QA, and packing through small pure helpers. `tools/character_factory_workflow.py` builds an API-format Qwen Image 2.1 graph with uploaded master and pose reference files. The character definition and pose templates are independent data, so new hunters and animation lists need no code changes.

**Tech Stack:** Python 3, Pillow, ComfyUI HTTP API, Qwen Image 2.1, JSON, Godot texture regions.

---

### Task 1: Definition validation

**Files:**
- Create: `tools/character_factory.py`
- Create: `art/characters/great_cleaver_hunter/character.json`
- Test: `tests/test_character_factory.py`

- [ ] **Step 1: Write the failing test**

```python
def test_load_definition_rejects_missing_ground_line(tmp_path):
    definition = {"character": "Hunter01", "sprite_size": [128, 128]}
    path = tmp_path / "character.json"
    path.write_text(json.dumps(definition), encoding="utf-8")
    with pytest.raises(ValueError, match="ground_y"):
        load_definition(path)
```

- [ ] **Step 2: Run test to verify it fails**

Run: `py -3 -m pytest tests/test_character_factory.py -q`

Expected: FAIL because `load_definition` does not exist.

- [ ] **Step 3: Write minimal implementation**

```python
def load_definition(path: Path) -> dict:
    definition = json.loads(path.read_text(encoding="utf-8"))
    for key in ("character", "sprite_size", "ground_y", "pivot", "palette_colors", "animations"):
        if key not in definition:
            raise ValueError(key)
    return definition
```

- [ ] **Step 4: Run test to verify it passes**

Run: `py -3 -m pytest tests/test_character_factory.py -q`

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add tools/character_factory.py art/characters/great_cleaver_hunter/character.json tests/test_character_factory.py
git commit -m "feat: add character factory definitions"
```

### Task 2: Deterministic frame normalization and QA

**Files:**
- Modify: `tools/character_factory.py`
- Test: `tests/test_character_factory.py`

- [ ] **Step 1: Write the failing test**

```python
def test_normalize_frame_aligns_visible_feet_and_limits_palette(tmp_path):
    source = write_offset_rgba_sprite(tmp_path / "source.png", feet_y=109, colors=40)
    image = normalize_frame(source, canvas=(128, 128), target_height=104, ground_y=116, palette=master_palette())
    assert visible_bbox(image).bottom == 117
    assert len(image.getcolors(maxcolors=33)) <= 32
```

- [ ] **Step 2: Run test to verify it fails**

Run: `py -3 -m pytest tests/test_character_factory.py -q`

Expected: FAIL because `normalize_frame` does not exist.

- [ ] **Step 3: Write minimal implementation**

```python
def normalize_frame(source, canvas, target_height, ground_y, palette):
    image = Image.open(source).convert("RGBA")
    cropped = image.crop(visible_bbox(image))
    scaled = cropped.resize((round(cropped.width * target_height / cropped.height), target_height), Image.Resampling.NEAREST)
    result = Image.new("RGBA", canvas)
    result.alpha_composite(quantize_to_palette(scaled, palette), ((canvas[0] - scaled.width) // 2, ground_y - scaled.height + 1))
    return result
```

- [ ] **Step 4: Run test to verify it passes**

Run: `py -3 -m pytest tests/test_character_factory.py -q`

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add tools/character_factory.py tests/test_character_factory.py
git commit -m "feat: normalize and validate character frames"
```

### Task 3: Qwen Image 2.1 API graph and reference upload

**Files:**
- Create: `tools/character_factory_workflow.py`
- Modify: `tools/character_factory.py`
- Test: `tests/test_character_factory_workflow.py`

- [ ] **Step 1: Write the failing test**

```python
def test_build_frame_workflow_uses_master_references_and_pose():
    graph = build_frame_workflow(["master.png", "identity.png", "weapon.png", "pose.png"], "hold the heavy blade overhead", 9)
    encoder = graph["5"]["inputs"]
    assert encoder["image_1"] == ["10", 0]
    assert encoder["image_4"] == ["13", 0]
    assert "Do not redesign" in encoder["prompt"]
```

- [ ] **Step 2: Run test to verify it fails**

Run: `py -3 -m pytest tests/test_character_factory_workflow.py -q`

Expected: FAIL because `build_frame_workflow` does not exist.

- [ ] **Step 3: Write minimal implementation**

```python
def build_frame_workflow(reference_names, pose_instruction, seed):
    encoder = {"clip": ["2", 0], "prompt": locked_prompt(pose_instruction), "negative_prompt": NEGATIVE, "resolution": 1024}
    for index, name in enumerate(reference_names, start=1):
        node_id = str(9 + index)
        encoder[f"image_{index}"] = [node_id, 0]
    return qwen_graph(encoder, reference_names, seed)
```

- [ ] **Step 4: Run test to verify it passes**

Run: `py -3 -m pytest tests/test_character_factory_workflow.py -q`

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add tools/character_factory.py tools/character_factory_workflow.py tests/test_character_factory_workflow.py
git commit -m "feat: add qwen frame workflow"
```

### Task 4: Pack accepted frames and publish Great Cleaver sources

**Files:**
- Create: `tools/generate_great_cleaver_poses.py`
- Create: `art/characters/great_cleaver_hunter/poses/idle/00.png`
- Create: `art/characters/great_cleaver_hunter/poses/charge/00.png`
- Create: `art/characters/great_cleaver_hunter/poses/heavy_strike/00.png`
- Create: `art/characters/great_cleaver_hunter/poses/recovery/00.png`
- Create: `art/characters/great_cleaver_hunter/sprites/great_cleaver_hunter_animations.json`
- Test: `tests/test_character_factory.py`

- [ ] **Step 1: Write the failing test**

```python
def test_pack_sheet_writes_ordered_regions_and_metadata(tmp_path):
    output = pack_sheet(frame_paths=four_frames(tmp_path), animations={"idle": 1, "charge": 1, "heavy_strike": 1, "recovery": 1}, output_dir=tmp_path)
    data = json.loads(output.metadata.read_text())
    assert data["frames"]["charge"][0]["x"] == 128
    assert Image.open(output.sheet).size == (512, 128)
```

- [ ] **Step 2: Run test to verify it fails**

Run: `py -3 -m pytest tests/test_character_factory.py -q`

Expected: FAIL because `pack_sheet` does not exist.

- [ ] **Step 3: Write minimal implementation**

```python
def pack_sheet(frame_paths, animations, output_dir):
    sheet = Image.new("RGBA", (128 * len(frame_paths), 128))
    metadata = {"frames": {}}
    for index, path in enumerate(frame_paths):
        sheet.alpha_composite(Image.open(path).convert("RGBA"), (128 * index, 0))
        metadata[animation_for(path)].append({"x": 128 * index, "y": 0, "w": 128, "h": 128})
    sheet.save(output_dir / "great_cleaver_hunter_spritesheet.png")
    (output_dir / "great_cleaver_hunter_animations.json").write_text(json.dumps(metadata, indent=2))
```

- [ ] **Step 4: Run test to verify it passes**

Run: `py -3 -m pytest tests/test_character_factory.py -q`

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add tools/generate_great_cleaver_poses.py art/characters/great_cleaver_hunter tests/test_character_factory.py
git commit -m "feat: pack Great Cleaver factory assets"
```
