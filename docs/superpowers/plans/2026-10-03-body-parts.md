# Body Parts Implementation Plan

**Goal:** Add targeted wounds and two breakable parts to both current large beasts, with a touch control and real changes to their attacks.

**Architecture:** A reusable state object calculates part progress and wound effects. Boss scripts map part IDs to locations and move changes. Main checks player reach and routes hits; UI shows and cycles the selected part. Existing `receive_hit(amount, kind)` calls keep targeting the primary part.

**Tech Stack:** Godot 4.7.2, GDScript, Android APK.

---

### Task 1: Shared part state

**Files:** `scripts/body_parts.gd`, `tests/test_body_parts.gd`

- [ ] Test invalid IDs, quick/heavy progress, wound opening, heavy wound strike, one-time break, and status snapshots; run red.
- [ ] Implement a part state object with deterministic `apply_hit` and `status` results; run green.

### Task 2: Two beasts and material rewards

**Files:** `scripts/cinderback.gd`, `scripts/thornhart.gd`, `scripts/hunt_catalog.gd`, `tests/test_beast.gd`, `tests/test_thornhart.gd`, `tests/test_hunt_catalog.gd`

- [ ] Add failing tests for each secondary break and its weakened move. Check reward rises once for the secondary break.
- [ ] Move primary break calculation to shared part state, add secondary part, part positions, wound recovery, and attack profile methods. Keep old primary break signal/property and health/phase behavior.
- [ ] Run boss and catalog tests green.

### Task 3: Player targeting and UI

**Files:** `scripts/main.gd`, `scripts/game_ui.gd`, `scripts/words.gd`, `project.godot`, `tests/test_part_targeting.gd`, `tests/test_part_ui.gd`

- [ ] Test cycling IDs, route a heavy hit to a chosen part at reachable position, prevent hit outside reach, and display both language labels; run red.
- [ ] Add touch button and Q key, brass target ring, HUD part state, and selected-part hit routing. Wire break and wound messages.
- [ ] Run focused tests then all Godot/Python tests.

### Task 4: Device build

- [ ] Raise APK version, export and verify signature/metadata.
- [ ] Install over the connected ASUS without clearing data. Enter each hunt, exercise target button, inspect screenshot and logcat. Preserve the saved language and progress.
