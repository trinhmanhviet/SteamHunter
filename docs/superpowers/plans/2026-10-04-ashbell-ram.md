# Ashbell Ram Third Hunt Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add Ashbell Ram as the third large monster and a complete playable Smoke Moor hunt.

**Architecture:** A focused boss script implements the shared boss signal/part contract while keeping its five-move state machine local. The existing hunt catalog remains the single source for spawning, names, route placement, retry, and rewards; main and UI only gain localized break labels.

**Tech Stack:** Godot 4.7 GDScript, generated transparent pixel art, scene-tree tests, Android export and ADB.

---

### Task 1: Boss behavior contract

**Files:** `scripts/ashbell_ram.gd`, `tests/test_ashbell_ram.gd`, `art/ashbell_ram.png`

- [x] Write a failing test for health, five attack profiles, phase two, exhaustion, horn break effects, chamber break effects, and target positions.
- [x] Run the test and confirm it fails because the boss script is absent.
- [x] Implement the shared boss API, five attacks, charge/rebound combo, phase and exhaustion state, wound/break routing, telegraphs, collision, and scaled generated sprite.
- [x] Run the boss test and existing Cinderback/Thornhart tests green.

### Task 2: Catalog and live hunt

**Files:** `scripts/hunt_catalog.gd`, `scripts/words.gd`, `scripts/main.gd`, `tests/test_hunt_catalog.gd`, `tests/test_ashbell_hunt.gd`

- [x] Write failing catalog and live-flow assertions for `ashbell`, its scripts, route, names, reward, completion record, and retry.
- [x] Run them and confirm the missing hunt fails.
- [x] Add the catalog record, English/Vietnamese text, part names, and chamber break flash selection.
- [x] Run catalog, camp, targeting, game-loop, and Ashbell hunt tests green.

### Task 3: Android release and source sync

**Files:** `export_presets.cfg`, ignored `build/MistAndIron-debug.apk`

- [x] Run every `tests/test_*.gd` script with no failure or script/parser error.
- [x] Increment Android version code/name, export, install, launch, verify metadata, and inspect logcat.
- [x] Commit all source and asset changes, push `main`, verify remote HEAD, and leave a clean workspace.
