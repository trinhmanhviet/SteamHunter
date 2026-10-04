# Weapon Tuning Implementation Plan

**Goal:** Turn monster trophies into persistent weapon branches that exploit original monster weaknesses.

**Architecture:** Rules own tuning recipes and damage/status math; the hunt catalog owns monster defense profiles; save data owns per-weapon branch unlocks; main applies the selected tuning to confirmed boss hits; the forge UI owns a separate tuning page.

**Tech Stack:** Godot 4.7.2, GDScript, headless scene tests, Movie Maker visual capture, Android SDK.

### Task 1: Data and persistence

- [ ] Write failing tests for branch recipes, elemental matchups, status scaling, and legacy migration.
- [ ] Add catalog defenses, tuning rules, and save schema 5.
- [ ] Run pure rules and save tests green.

### Task 2: Forge and live combat

- [ ] Write failing flow and UI tests for crafting, free switching, live loadout, and snare proc.
- [ ] Add the tuning forge page and main flow.
- [ ] Apply raw, heat, shock, and snare effects to boss hits and show the equipped branch on the HUD.
- [ ] Run tuning, weapon, monster, and main-flow tests green.

### Task 3: Release

- [ ] Render and inspect English and Vietnamese tuning panels.
- [ ] Run every test with no failure or script/parser error.
- [ ] Export version 0.10.0, install and launch it on Android, verify metadata and logs.
- [ ] Commit, push `main`, verify remote HEAD, and leave a clean workspace.
