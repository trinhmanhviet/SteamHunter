# Great Cleaver Route Pass One Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make Great Cleaver's mobile combat stick support a three-step charged route, overcharge penalty, route-preserving Shoulder Brace, and Anvil Rise into Crossbite.

**Architecture:** `scripts/hunter.gd` remains the single runtime owner for charge state, route state, and defensive/counter outcomes. `scripts/weapon_catalog.gd` declares the two original moves and their damage data; `scripts/main.gd` supplies the current boss attack volume when damage is applied. `scripts/blade_combat_stick.gd` gains only an upward held gesture, retaining the existing floating touch surface and support-button exclusion.

**Tech Stack:** Godot 4.7, GDScript scene-tree tests, Android touch controls.

---

### Task 1: Route charge levels and spent-edge release

**Files:**
- Modify: `tests/test_blade_gesture_flow.gd`
- Modify: `tests/test_weapon_actions.gd`
- Modify: `scripts/hunter.gd`
- Modify: `scripts/weapon_catalog.gd`

- [ ] **Step 1: Write the failing route and overcharge tests**

Add these assertions after the existing full-charge assertion in `tests/test_blade_gesture_flow.gd`:

```gdscript
_check(blade.blade_route_index == 0, "a fresh Great Cleaver starts on the first charge route")
blade.advance_blade_charge(0.23)
_check(blade.blade_charge_stage() == 1 and not blade.blade_charge_spent(), "first beat is usable")
blade.advance_blade_charge(0.68)
_check(blade.blade_charge_stage() == 3 and not blade.blade_charge_spent(), "third beat is the best release")
blade.advance_blade_charge(0.20)
_check(blade.blade_charge_spent(), "holding beyond the third beat spends the edge")
_check(blade.release_blade_charge(), "spent charge still releases")
_check(blade.current_action == "charged_hew" and blade.attack_charge == 0.70, "spent edge falls back to level-two power")
```

Add a test in `tests/test_weapon_actions.gd` that confirms a landed `charged_hew` sets `blade_route_index` to `1`, then a new held charge releases `furnace_hew`, and a landed `furnace_hew` sets the index to `2`.

- [ ] **Step 2: Run the two tests to verify they fail**

Run:

```powershell
.\.tools\godot\Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tests/test_blade_gesture_flow.gd
.\.tools\godot\Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tests/test_weapon_actions.gd
```

Expected: the new state/method references fail because the route and spent-edge behavior do not exist.

- [ ] **Step 3: Add only the route data and runtime needed by the tests**

In `scripts/hunter.gd`, add `blade_route_index := 0` and `blade_charge_overcharged := false`. Make `release_blade_charge()` select `charged_hew`, `furnace_hew`, or `sundering_fall` from the route index, use `[0.0, 0.38, 0.70, 1.0]` for normal release, and use `0.70` when `blade_charge_overcharged` is true. Add:

```gdscript
func blade_charge_spent() -> bool:
	return blade_charge_overcharged

func _blade_route_action() -> String:
	return ["charged_hew", "furnace_hew", "sundering_fall"][clampi(blade_route_index, 0, 2)]
```

Set `blade_charge_overcharged` once charge reaches `1.10`; reset it whenever a charge starts or releases. In `confirm_hit()`, set the index to `1` after `charged_hew`, to `2` after `furnace_hew`, and reset it to `0` after `sundering_fall`.

In `scripts/weapon_catalog.gd`, add `furnace_hew` between `charged_hew` and `sundering_fall` with a heavier, lower hit: `_a(31, 158.0, 0.80, 0.52, 0.67, 31.0, 0.0, 0.0, 4.0, "heavy", 0.110, 151.0, 67.0, 22)`. Give it a heavy follow-up to `sundering_fall`.

- [ ] **Step 4: Run the focused tests to verify they pass**

Run the two commands from Step 2. Expected: exit code 0 and no `FAIL:` lines.

- [ ] **Step 5: Commit the first vertical slice**

```powershell
git add scripts/hunter.gd scripts/weapon_catalog.gd tests/test_blade_gesture_flow.gd tests/test_weapon_actions.gd
git commit -m "feat: add Great Cleaver charge route"
```

### Task 2: Shoulder Brace absorbs a real hit and preserves the route

**Files:**
- Modify: `tests/test_blade_gesture_flow.gd`
- Modify: `tests/test_weapon_actions.gd`
- Modify: `scripts/hunter.gd`

- [ ] **Step 1: Write the failing Brace tests**

Add tests that set `blade_route_index = 0`, begin `shoulder_brace`, call `take_hit(20)`, and assert health loses 10 or less, `current_action` stays `shoulder_brace`, and `blade_route_index == 1`. Add a second test that starts and finishes Brace without calling `take_hit()` and asserts the route index stays unchanged.

- [ ] **Step 2: Run the focused test to verify it fails**

Run:

```powershell
.\.tools\godot\Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tests/test_weapon_actions.gd
```

Expected: the absorbed hit does not yet advance the Great Cleaver route.

- [ ] **Step 3: Implement a one-hit Brace absorb window**

In `scripts/hunter.gd`, add `blade_brace_absorbed := false`. Reset it when `shoulder_brace` begins. In the blade Brace branch of `take_hit()`, only when `blade_brace_absorbed` is false, set it true, advance `blade_route_index = mini(2, blade_route_index + 1)`, apply 40% of incoming damage with `interrupt = false`, and retain the action. Any later hit during the same Brace receives the existing ordinary damage path.

- [ ] **Step 4: Run the focused tests to verify they pass**

Run `test_weapon_actions.gd` and `test_blade_gesture_flow.gd`. Expected: both exit 0.

- [ ] **Step 5: Commit Brace routing**

```powershell
git add scripts/hunter.gd tests/test_blade_gesture_flow.gd tests/test_weapon_actions.gd
git commit -m "feat: route Great Cleaver Brace absorbs"
```

### Task 3: Anvil Rise, Crossbite, and boss attack-volume clash

**Files:**
- Modify: `tests/test_blade_combat_stick.gd`
- Modify: `tests/test_blade_gesture_flow.gd`
- Modify: `tests/test_great_cleaver_hitboxes.gd`
- Modify: `tests/test_weapon_flow.gd`
- Modify: `scripts/blade_combat_stick.gd`
- Modify: `scripts/main.gd`
- Modify: `scripts/hunter.gd`
- Modify: `scripts/weapon_catalog.gd`

- [ ] **Step 1: Write the failing input and clash tests**

In `tests/test_blade_combat_stick.gd`, hold a touch, drag it above the `DODGE_PULL` distance, release it, and assert the last command is `"anvil_rise"`. In `tests/test_blade_gesture_flow.gd`, add assertions for `start_anvil_rise()`, `try_anvil_clash(Rect2(...))`, and `current_action == "crossbite"` after a matching monster attack rectangle; add a separate body-only assertion that calls no clash helper and confirms no Crossbite route is granted. In `tests/test_great_cleaver_hitboxes.gd`, assert `anvil_rise` reaches `Vector2(86, -146)` and `crossbite` reaches `Vector2(112, -72)`.

- [ ] **Step 2: Run the focused tests to verify they fail**

Run:

```powershell
.\.tools\godot\Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tests/test_blade_combat_stick.gd
.\.tools\godot\Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tests/test_blade_gesture_flow.gd
.\.tools\godot\Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tests/test_great_cleaver_hitboxes.gd
```

Expected: upward held gesture and clash methods/actions are missing.

- [ ] **Step 3: Add the two original moves and their hit zones**

In `scripts/weapon_catalog.gd`, add actions:

```gdscript
"anvil_rise": _a(23, 146.0, 0.66, 0.34, 0.46, 24.0, 0.0, 0.0, 0.0, "heavy", 0.085, 108.0, 46.0),
"crossbite": _a(28, 136.0, 0.50, 0.24, 0.34, 19.0, 0.0, 0.0, 38.0, "heavy", 0.090, 122.0, 54.0)
```

Add `anvil_rise` as the result of the new `"anvil_rise"` command. In `Hunter`, implement `start_anvil_rise()` as `start_action("anvil_rise")`. Add a `Rect2` world-space clash box based on the Anvil hit zone at its hit frame; `try_anvil_clash(attack_rect)` succeeds only while the current action is `anvil_rise`, the strike is active, and the rectangles overlap. On success it calls `_force_action("crossbite")` and sets `blade_route_index = 2` only after Crossbite subsequently confirms a hit. Add Anvil and Crossbite hit zones to `_great_cleaver_hit_zone()`.

In `scripts/blade_combat_stick.gd`, distinguish upward held/released from a short upward pull: while charging, an upward pull sets `anvil_primed`; on release emit `"anvil_rise"` when primed. Keep a quick upward pull as `"lift"` so the prior directional attack remains reachable.

In `scripts/main.gd`, create the boss attack rectangle from the active attack reach and vertical range before calling `hunter.take_hit`. Call `hunter.try_anvil_clash(attack_rect)` first; if it returns true, play the hit sound and do not apply boss damage for that attack. This makes a clash require overlap with an actual monster attack, never a body hit.

- [ ] **Step 4: Run the focused tests and integration flow**

Run the three commands from Step 2, then:

```powershell
.\.tools\godot\Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tests/test_weapon_flow.gd
```

Expected: every script exits 0 with no `FAIL:`, parser errors, or runtime errors.

- [ ] **Step 5: Commit counter-route support**

```powershell
git add scripts/blade_combat_stick.gd scripts/hunter.gd scripts/main.gd scripts/weapon_catalog.gd tests/test_blade_combat_stick.gd tests/test_blade_gesture_flow.gd tests/test_great_cleaver_hitboxes.gd tests/test_weapon_flow.gd
git commit -m "feat: add Great Cleaver Anvil Rise counter"
```

### Task 4: Regression run and Android build handoff

**Files:**
- Verify: `tests/test_*.gd`
- Verify: `build/MistAndIron-debug.apk`

- [ ] **Step 1: Run all game tests**

Run every `tests/test_*.gd` script using `Godot_v4.7.2-stable_win64_console.exe --headless --path . --script`. Expected: all scripts exit 0 without `FAIL:`, `SCRIPT ERROR`, or parser errors.

- [ ] **Step 2: Build the Android debug APK**

Run the existing Godot Android export to produce `build/MistAndIron-debug.apk`. Expected: the APK exists and has a new modification time after the export.

- [ ] **Step 3: Install when an ADB device is available**

Query `F:\_Work\AndroidSDK\Sdk\platform-tools\adb.exe devices`. If one device has state `device`, install `build\MistAndIron-debug.apk` with replace-existing enabled. If no device is listed, keep the verified APK for the next connection.

- [ ] **Step 4: Push and publish the user-requested release**

Commit the implementation if any changes remain, push `main` to `https://github.com/trinhmanhviet/SteamHunter`, then create the next GitHub release with `build/MistAndIron-debug.apk` attached.
