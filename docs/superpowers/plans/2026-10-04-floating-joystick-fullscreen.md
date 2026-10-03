# Floating Joystick and Fullscreen Layout Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Hide the movement stick until a valid lower-left touch, float it at that touch, and fill wide Android screens without distorted pixel art or misplaced action buttons.

**Architecture:** `virtual_joystick.gd` becomes a viewport-aware touch surface whose visual ring is positioned internally at a clamped touch center. `game_ui.gd` sizes itself from the visible viewport and lays right-side controls out from the right edge. Godot uses expanded viewport scaling so wider phones reveal more world horizontally.

**Tech Stack:** Godot 4.7, GDScript, Godot headless tests, Android export, ADB.

---

### Task 1: Floating joystick behavior

**Files:**
- Modify: `tests/test_mobile_controls.gd`
- Modify: `scripts/virtual_joystick.gd`

- [ ] **Step 1: Write the failing joystick tests**

Create a 960 by 540 stick touch surface, configure its activation fraction to 35% width and 50% height, then assert: idle visuals are hidden; upper-left and right-side touches are rejected; a lower-left touch is captured and shown; touches near the activation-zone edges produce a clamped center; drag strength remains proportional; a non-owner cannot steal or release it; owner release clears input and hides visuals.

- [ ] **Step 2: Run the focused test and verify red**

Run:

```powershell
.\.tools\godot\Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tests/test_mobile_controls.gd
```

Expected: failure on idle visibility or missing activation-zone API.

- [ ] **Step 3: Implement the minimal floating stick**

In `virtual_joystick.gd`, add viewport-sized control bounds, `activation_width_ratio := 0.35`, `activation_height_ratio := 0.50`, `visual_center`, an activation rectangle helper, and center clamping by visual radius. Capture only a press inside that rectangle. Use `visual_center` to calculate direction and draw the ring only while a finger is owned.

- [ ] **Step 4: Run the focused test and verify green**

Run the Task 1 command. Expected: exit code 0 and no `FAIL:` output.

- [ ] **Step 5: Commit the focused change**

Stage `scripts/virtual_joystick.gd` and `tests/test_mobile_controls.gd`, then commit with message `feat: add floating mobile joystick`.

### Task 2: Wide-screen UI layout

**Files:**
- Modify: `tests/test_mobile_controls.gd`
- Modify: `scripts/game_ui.gd`
- Modify: `project.godot`
- Modify: `export_presets.cfg`

- [ ] **Step 1: Write failing wide-layout tests**

Resize the root viewport to 1224 by 540, rebuild the hunt UI, and assert the root uses the visible size, the stick touch surface spans the viewport, the pause button and attack cluster move by the 264-unit width difference, and the health HUD stays at the left edge. Also assert the 960 by 540 layout retains its current approved positions.

- [ ] **Step 2: Run the focused test and verify red**

Run the Task 1 command. Expected: failure because the root remains fixed at 960 by 540 and right controls remain at their old x positions.

- [ ] **Step 3: Implement responsive positioning**

In `game_ui.gd`, derive layout size from `get_viewport().get_visible_rect().size`, keep a 960 by 540 minimum reference, create the stick as a full-screen ignored-input drawing surface, and offset right-side buttons by `layout_width - 960.0`. Keep the HUD on the left. Set `window/stretch/aspect="expand"` in `project.godot`, keep viewport stretch mode, and enable Android edge-to-edge drawing while retaining immersive mode.

- [ ] **Step 4: Run the focused test and verify green**

Run the Task 1 command. Expected: exit code 0 and no `FAIL:` output.

- [ ] **Step 5: Run the complete headless test set**

Run every `tests/test_*.gd` script with the Godot console binary. Expected: every script exits 0 without `FAIL:`, parser errors, or runtime errors.

- [ ] **Step 6: Commit the responsive layout**

Stage `project.godot`, `export_presets.cfg`, `scripts/game_ui.gd`, and `tests/test_mobile_controls.gd`, then commit with message `feat: fill wide Android displays`.

### Task 3: Android build and device verification

**Files:**
- Modify: `export_presets.cfg`
- Create: `build/MistAndIron-debug.apk`
- Create: `build/device-floating-fullscreen.png`

- [ ] **Step 1: Increment the Android build version**

Change Android version code from 11 to 12 and version name from `0.6.1` to `0.6.2`.

- [ ] **Step 2: Export the APK**

Run:

```powershell
.\.tools\godot\Godot_v4.7.2-stable_win64_console.exe --headless --path . --export-debug Android build/MistAndIron-debug.apk
```

Expected: exit code 0 and a signed APK at the export path.

- [ ] **Step 3: Install and launch on the connected phone**

Use the explicit physical-device serial with ADB, install using `install -r`, force-stop the old process, and launch `org.mistandiron.suongvasat`. Expected: install reports `Success` and the main activity becomes foreground.

- [ ] **Step 4: Verify the device output**

Capture a device screenshot to `build/device-floating-fullscreen.png`. Confirm the world reaches both screen edges, right controls remain inset and visible, and no joystick appears while idle. Send a swipe beginning in the lower-left activation zone, capture during the gesture if possible, and confirm the joystick appears around the touch and movement input is accepted.

- [ ] **Step 5: Check Android logs and package version**

Confirm package version `0.6.2`/code `12` and inspect recent logcat output for `FATAL EXCEPTION`, `SCRIPT ERROR`, and parser errors. Expected: correct version and no matching errors.

- [ ] **Step 6: Commit version metadata**

Stage `export_presets.cfg`, then commit with message `build: release Android prototype 0.6.2`.
