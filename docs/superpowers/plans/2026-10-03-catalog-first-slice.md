# Catalog First Slice Implementation Plan

**Goal:** Move the two working hunts from branch-specific setup into validated hunt data while keeping the Android game playable. This is the first system step toward the complete game design; it uses existing art and no new images.

**Architecture:** `HuntCatalog` owns scene scripts and placement data for each hunt. `main.gd` asks the catalog for the selected record, constructs the world/foes from that record, and leaves reward calculation in the catalog. A future region director can replace the current single-stage construction without changing stable hunt IDs or save data.

**Tech Stack:** Godot 4.7.2, GDScript, Android SDK/ADB.

---

### Task 1: Make the two hunt records complete

**Files:** `scripts/hunt_catalog.gd`, `tests/test_hunt_catalog.gd`

- [x] Extend the test to check that every listed hunt contains `biome`, `boss_script`, `small_script`, `herb_x`, `small_x`, `boss_x`, `base_reward`, name keys, and that each resource path loads. Assert unknown ID returns an empty record rather than silently choosing the moor.
- [x] Run `\.tools\godot\Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tests/test_hunt_catalog.gd`; confirm the new assertions fail.
- [x] Add each field to both records. Keep their current positions: moor herbs 385/1375/2380, small foes 605/1060/1640/2190; forest herbs 415/1350/2330, small foes 570/1120/1700/2240; boss x 2700. Set script paths to the existing Cinderback/Rat and Thornhart/Boar scripts. Make `get_hunt` return `{}` for unknown IDs and `reward` return zero for them.
- [x] Run the catalog test and confirm it passes. Existing IDs and reward values remain stable.

### Task 2: Consume data when starting a hunt

**Files:** `scripts/main.gd`, `tests/test_game_loop.gd`, `tests/test_forest_hunt.gd`

- [x] Add test assertions that `start_hunt("missing")` does not replace the current valid selection and that both real hunts spawn the boss and small foe classes specified by their catalog records.
- [x] Run the two game-loop tests and confirm at least the new catalog-driven assertion fails before changing `main.gd`.
- [x] In `start_hunt`, choose a valid ID, fetch the hunt record once, and use it for biome, herb/small positions, boss placement and script construction. Keep UI IDs and rewards unchanged. Avoid extra runtime string `load` calls by preloading the four script classes in the catalog records.
- [x] Run both tests; confirm moor and forest start, win, return, and retry still work.
- [x] Make the camp list scroll and generate its buttons from the same catalog; check both languages and stable hunt IDs in `tests/test_camp_catalog.gd`.

### Task 3: Verify on the connected Android device

**Files:** exported `build/MistAndIron-debug.apk`; no source art edits.

- [x] Run all 18 Godot test scripts and the two Python audio tests; all passed.
- [x] Export the Android debug APK as 0.4.2 (versionCode 7). APK metadata and v2/v3 signature verified.
- [x] Install over `org.mistandiron.suongvasat` on `N9AIOC1546046RZ`, preserving app data. Open camp, enter Smoke Moor, pause/return, enter Briarwood, return after defeat, switch to Vietnamese, and restart. The language persisted; no Godot script errors or Android crashes appeared in the inspected log window.
- [x] Capture device screenshots of camp in both languages and both hunts. This was an entry/return smoke test, not a full manual playthrough.

### Next system slices

After this self-contained slice: save schema with atomic writes/migration, a proper hunt director/regions, body parts and tracks, forge/inventory, then the remaining content catalog. Art finalization waits until those mechanics pass on the phone, as required by the complete design.
