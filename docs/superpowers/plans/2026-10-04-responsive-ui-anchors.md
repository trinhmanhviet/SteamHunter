# Responsive UI Anchors Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Anchor every major UI group to the visible viewport while preserving the approved 960 by 540 layout.

**Architecture:** GameUI derives `right_offset` and `center_offset` from its logical layout width. Screens apply the full offset to right-aligned groups and the half offset to centered groups; left-aligned groups remain unchanged.

**Tech Stack:** Godot 4.7, GDScript, headless scene tests, Android export, ADB.

---

### Task 1: Test responsive anchors

**Files:**
- Modify: `tests/test_mobile_controls.gd`

- [ ] Add wide-viewport assertions for named camp, forge, pause, result, hunt HUD, boss, and action groups.
- [ ] Run the mobile-controls test and confirm failures occur because camp and dialog coordinates are still fixed.

### Task 2: Apply anchor offsets

**Files:**
- Modify: `scripts/game_ui.gd`

- [ ] Add helpers returning `layout_size.x - 960.0` and half that value.
- [ ] Name the major panels and shift every member of each right- or center-aligned group with the appropriate helper.
- [ ] Run the mobile-controls test and confirm all anchor assertions pass.
- [ ] Run all `tests/test_*.gd` scripts and confirm zero failures.

### Task 3: Build and verify Android 0.6.3

**Files:**
- Modify: `export_presets.cfg`
- Create: `build/MistAndIron-debug.apk`
- Create: `build/device-responsive-camp.png`
- Create: `build/device-responsive-gear.png`

- [ ] Increment version code to 13 and version name to 0.6.3.
- [ ] Export the Android debug APK and install it on physical device N9AIOC1546046RZ.
- [ ] Capture the camp and forge screens at 2448 by 1080 and verify right and center anchoring visually.
- [ ] Confirm package version and check logcat for fatal or script errors.
- [ ] Commit the implementation and verification tests.
