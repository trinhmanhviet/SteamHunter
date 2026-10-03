# Four Weapon Combat Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship four playable weapon archetypes with unique action graphs, resources, defensive techniques, mobile controls, forge selection, save migration, and landed-hit integration.

**Architecture:** `weapon_catalog.gd` owns immutable weapon and action data while `rules.gd` exposes stable queries and keeps the old quick/heavy API working. `hunter.gd` owns the runtime action state machine, resource changes, buffering, charge, guard, and counter behavior. Existing `main.gd`, `game_ui.gd`, and `save_store.gd` integrate hit confirmation, mobile presentation, and migration without duplicating weapon rules.

**Tech Stack:** Godot 4.7 GDScript, scene-tree test scripts, Android export preset, ADB verification.

---

### Task 1: Weapon action catalog

**Files:**
- Create: `scripts/weapon_catalog.gd`
- Create: `tests/test_weapon_catalog.gd`
- Modify: `scripts/rules.gd`
- Modify: `tests/test_weapon_rules.gd`

- [x] **Step 1: Write the failing catalog contract test**

Create a scene-tree test which loads `WeaponCatalog`, asserts that `required_ids()` is `["blade", "counter", "twins", "pike"]`, and checks that each weapon has at least eight actions. For every action assert the presence and valid range of `damage`, `reach`, `duration`, `hit_at`, `combo_open`, `stamina`, `resource_gain`, `resource_cost`, `move`, `impact`, `hit_stop`, `knockback`, and `stagger`. Assert every follow-up action exists in the same weapon record.

- [x] **Step 2: Run the new test and verify red**

Run:

```powershell
.\.tools\godot\Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tests/test_weapon_catalog.gd
```

Expected: parser/load failure because `res://scripts/weapon_catalog.gd` does not exist.

- [x] **Step 3: Implement the catalog and compatibility queries**

Create five records in `WeaponCatalog.WEAPONS`: the required `blade`, `counter`, `twins`, and `pike`, plus legacy `maul`. Use the exact action IDs from the design spec. Each record contains `cost`, `resource_name`, `resource_max`, `walk_multiplier`, `art`, `entry`, `heavy`, `directional`, `dodge`, `aerial`, `special`, `followups`, and `actions`. Add `weapon_ids`, `required_ids`, `weapon`, `action_ids`, and `action` query functions that fall back to `blade` safely.

Update `rules.gd` so `weapon_ids`, `weapon_cost`, `action`, `action_ids`, `entry_action`, `followup_action`, `action_damage`, `action_impact`, `attack_damage`, `attack_reach`, `attack_cost`, and `attack_duration` read from the catalog. Map compatibility token `quick` to the light entry and `heavy` to the heavy entry.

- [x] **Step 4: Run catalog and legacy rules tests**

Run both `test_weapon_catalog.gd` and `test_rules.gd`. Expected: exit code 0, no `FAIL:` output.

- [x] **Step 5: Commit the data layer**

Stage the catalog, rules, tests, design spec, and this plan. Commit as `feat: define four weapon action catalogs`.

### Task 2: Save migration and forge roster

**Files:**
- Modify: `scripts/save_store.gd`
- Modify: `scripts/words.gd`
- Modify: `scripts/game_ui.gd`
- Modify: `tests/test_weapon_save.gd`
- Modify: `tests/test_gear_buttons.gd`
- Modify: `tests/test_gear_portraits.gd`

- [x] **Step 1: Write failing migration and five-card tests**

Change the save expectations so decoded schema-2 data gains `counter:false` and `twins:false`, preserves every existing ownership flag, and keeps an owned new weapon equipped. Change forge tests to expect all five IDs and recursively find `Portrait_<id>` below the horizontal card content.

- [x] **Step 2: Run the three affected tests and verify red**

Run `test_weapon_save.gd`, `test_gear_buttons.gd`, and `test_gear_portraits.gd`. Expected: missing ownership keys and missing counter/twins controls.

- [x] **Step 3: Implement schema 3 and responsive horizontal forge cards**

Set `SCHEMA_VERSION` to 3 and clean all IDs returned by `Rules.weapon_ids()`, forcing only `blade` to owned when absent. Add English and Vietnamese names/descriptions for `counter` and `twins`. Put the five 272 by 310 cards in a horizontally scrolling `Control` with 18 pixels between cards; load the catalog art path and use a tint for the two new weapons until dedicated animation sheets are added. Keep the whole gear panel centered with `_center_offset()`.

- [x] **Step 4: Run migration, forge, mobile layout, and flow tests**

Expected: all affected tests exit 0 and wide viewport assertions remain valid.

- [x] **Step 5: Commit save and forge integration**

Commit as `feat: add four-archetype forge roster`.

### Task 3: Hunter action state machine

**Files:**
- Modify: `scripts/hunter.gd`
- Create: `tests/test_weapon_actions.gd`
- Modify: `tests/test_weapon_hunter.gd`
- Modify: `tests/test_hunter.gd`

- [ ] **Step 1: Write failing action-state tests**

Test these public behaviors with real Hunter nodes: `start_action` spends action stamina; `confirm_hit` grants catalog resource once; a light input inside `combo_open` buffers the declared follow-up; Great Blade charge produces more damage and Resolve; Long Counter Blade prevents damage during its counter window and starts `counter_riposte`; Twin Blades reject `overdrive_flurry` without Tempo and spend Tempo with it; Fortress Lance guard reduces damage and opens `counter_thrust`; dodge and airborne light select their branch actions.

- [ ] **Step 2: Run the action test and verify red**

Expected: `start_action`, `confirm_hit`, and special state APIs are missing.

- [ ] **Step 3: Implement action runtime and backward compatibility**

Add runtime fields `current_action`, `buffered_token`, `combo_elapsed`, `weapon_resource`, `weapon_drawn`, `idle_combat_time`, `guard_time`, `counter_time`, `resolve`, and `hit_confirmed`. `start_action` validates stamina/resource and starts catalog timing. `request_action(token, directional, airborne)` resolves draw, dodge, directional, aerial, special, heavy, and follow-up branches. `advance_action(delta)` emits one strike at the action hit frame and begins a buffered follow-up after recovery. `confirm_hit` grants resource and hit stop once. `take_hit` resolves perfect counter, lance guard, Great Blade brace, invincibility, then ordinary damage in that order. Keep `start_attack("quick"|"heavy", charge)` for older callers and tests.

- [ ] **Step 4: Run hunter tests and refactor while green**

Expected: `test_weapon_actions.gd`, `test_weapon_hunter.gd`, `test_hunter.gd`, and `test_healing.gd` all exit 0.

- [ ] **Step 5: Commit the combat controller**

Commit as `feat: add weapon combo and defense state machine`.

### Task 4: Landed-hit combat integration

**Files:**
- Modify: `scripts/main.gd`
- Modify: `scripts/body_parts.gd`
- Modify: `tests/test_part_targeting.gd`
- Create: `tests/test_hit_confirmation.gd`

- [ ] **Step 1: Write failing integration tests**

Test that light action IDs map to light part damage, Great Blade finishers map to heavy part damage, and `hunter.confirm_hit(action_id)` runs only after a rat or boss actually receives the strike.

- [ ] **Step 2: Run both tests and verify red**

Expected: resource stays unchanged after a landed action because main never confirms it, and action IDs are treated as light by the old body-part branch.

- [ ] **Step 3: Integrate action impact and confirmation**

In `_on_hunter_struck`, translate the action ID through `Rules.action_impact(kind, hunter.weapon_type)` before calling `boss.receive_hit`. Track whether any target received damage and call `hunter.confirm_hit(kind)` once for the swing. Keep direct legacy `quick` and `heavy` test calls valid.

- [ ] **Step 4: Run hit, boss, and body-part tests**

Expected: hit confirmation, body parts, Cinderback, and Thornhart tests all exit 0.

- [ ] **Step 5: Commit world combat integration**

Commit as `feat: connect weapon actions to monster hit zones`.

### Task 5: Mobile special control and resource HUD

**Files:**
- Modify: `project.godot`
- Modify: `scripts/game_ui.gd`
- Modify: `scripts/words.gd`
- Modify: `tests/test_mobile_controls.gd`
- Create: `tests/test_weapon_hud.gd`

- [ ] **Step 1: Write failing control and HUD tests**

Assert that `show_hunt` creates `Action_special`, preserves the existing right-side hierarchy, and creates a resource label/bar whose text and fill update from the Hunter weapon resource. Assert leaving the hunt clears held `special` input.

- [ ] **Step 2: Run the UI tests and verify red**

Expected: `Action_special` and resource controls are absent.

- [ ] **Step 3: Add the input and responsive presentation**

Add keyboard input action `special` on physical key I. Put the Special touch control between Heal and Heavy without covering Attack, Dodge, Jump, Target, or Pause. Add localized `SPECIAL`, `RESOLVE`, `FOCUS`, `TEMPO`, and `GUARD` labels. Extend `update_hud` to show `hunter.resource_name()` and the current/max value.

- [ ] **Step 4: Run all UI and localization tests**

Expected: mobile controls, HUD, forge, and camp tests exit 0 at reference and wide aspect sizes.

- [ ] **Step 5: Commit touch combat UI**

Commit as `feat: add mobile weapon special controls`.

### Task 6: Full verification, Android build, device smoke test, and push

**Files:**
- Modify: `export_presets.cfg`
- Create: `build/MistAndIron-debug.apk` (ignored build artifact)

- [ ] **Step 1: Bump Android version**

Set version name to `0.7.0` and version code to `14`.

- [ ] **Step 2: Run the complete automated suite**

Run every `tests/test_*.gd` with the Godot console binary. Expected: each exits 0 with no `FAIL:`, `SCRIPT ERROR`, or parser error.

- [ ] **Step 3: Export and install the APK**

Run:

```powershell
.\.tools\godot\Godot_v4.7.2-stable_win64_console.exe --headless --path . --export-debug Android build/MistAndIron-debug.apk
F:\_Work\AndroidSDK\Sdk\platform-tools\adb.exe install -r build\MistAndIron-debug.apk
```

Expected: export succeeds and ADB prints `Success`.

- [ ] **Step 4: Smoke test on the connected ASUS phone**

Launch `org.mistandiron.suongvasat`, exercise each weapon from the forge and one hunt, capture a forge screenshot, then inspect logcat for `FATAL EXCEPTION`, `SCRIPT ERROR`, and `Parse Error`. Expected: none found; version dump reports code 14 and name 0.7.0.

- [ ] **Step 5: Commit and push the verified slice**

Commit remaining tracked changes as `release: ship four weapon combat slice`, push `main` to `origin`, and verify `git ls-remote origin refs/heads/main` matches local `HEAD`.
