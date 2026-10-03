# Save Foundation Implementation Plan

**Goal:** Preserve the 0.4.x player's progress while adding a versioned save shape and recovery from interrupted or corrupt writes, so later story, materials, and records can be stored safely.

**Architecture:** `SaveStore` remains independent from scenes. `decode` migrates older JSON into schema 2; `encode` writes only validated values. Saving writes a `.tmp` file, keeps the previous valid save as `.bak`, and replaces the main file. Loading tries the main file, then `.bak`, then defaults. The existing `parts`, `forge_level`, `weapons`, and `equipped` fields remain live until the forge model changes.

**Tech Stack:** Godot 4.7.2, GDScript, local JSON in `user://`.

---

### Task 1: Schema and migration

**Files:** `scripts/save_store.gd`, `tests/test_save.gd`

- [x] Add failing assertions for `schema_version == 2`, a chapter value, completed hunt IDs, per-hunt records, inventory counts, discovery flags, and display/audio settings. Check that the existing four-field phone save decodes with the same language, parts, forge level and hunt count.
- [x] Run `test_save.gd` and confirm failure before implementation.
- [x] Add schema 2 defaults and validation: nonnegative counts, known equipped weapon, bounded chapter/settings, safe collection types. Keep unknown material IDs as nonnegative inventory entries for future updates. Do not infer completed hunt IDs from the old aggregate `hunts_won` count.
- [x] Run `test_save.gd`; confirm roundtrips and legacy migration pass.

### Task 2: Write and recovery

**Files:** `scripts/save_store.gd`, `tests/test_save_io.gd`

- [x] Add a test using a path under `res://build/` that saves twice, confirms a backup contains the previous good state, corrupts the main file, and confirms load returns the backup. Test a nonexistent path returns defaults.
- [x] Run the test red.
- [x] Write `.tmp`, flush and close, copy a valid old save to `.bak`, then replace the main file. If the replacement fails, leave the backup readable. On load, accept only a JSON dictionary and use `.bak` if main is missing/corrupt.
- [x] Run `test_save_io.gd` and all earlier save tests; test-owned files in `build/` were cleaned up.

### Task 3: Android compatibility

- [x] Run all 19 Godot tests and two Python audio tests. Export 0.5.0 (versionCode 8); metadata and v2/v3 signature verified.
- [x] Install over the connected ASUS without clearing data. The legacy save kept Vietnamese, parts, forge level and hunt count. A language change migrated it to schema 2 and left the exact legacy JSON in `.bak`; switching back and restarting kept Vietnamese. Both hunts opened; inspected logcat showed no script errors or crashes. No test fixture was written to the phone.
