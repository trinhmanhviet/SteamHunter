# Mist & Iron Implementation Plan

> **For agentic workers:** Implement tasks in order and run the listed check before moving on. This workspace starts empty, so initialize Git in place.

**Goal:** Create a playable Android side-scrolling pixel-art monster-hunting game with original content and English/Vietnamese UI.

**Architecture:** Godot scenes split camp, hunt, hunter, creatures, and UI. Shared data scripts own loot, forging, localization, and save state. Art is drawn specifically for this project.

**Tech Stack:** Godot 4.7.2, GDScript, Python/Pillow for original pixel art, Android SDK.

---

### Task 1: Project and toolchain

- [ ] Initialize Git and add Godot project settings, Android landscape settings, input map, and ignore rules.
- [ ] Download the official Godot editor and matching Android export templates into local tooling or user cache.
- [ ] Verify `godot --headless --path . --editor --quit` imports and parses the empty project.

### Task 2: Art and stage

- [ ] Draw an original hunter, camp, moor tiles, small foe, Cinderback, attacks, and UI icons as pixel art.
- [ ] Build a camp scene and a platforming hunting stage with collision, camera, parallax, and route markers.
- [ ] Verify scenes import without errors and render at the intended pixel resolution.

### Task 3: Hunter and controls

- [ ] Add failing headless tests for stamina spending, invulnerability timing, and attack damage rules.
- [ ] Implement movement, jump, dodge, quick attack, charged attack, health, stamina, and hit feedback.
- [ ] Add keyboard and touch input. Verify combat rules and scripted movement smoke check.

### Task 4: Creatures and hunt

- [ ] Add failing tests for attack telegraph timing, phase change, armor break, and loot reward.
- [ ] Implement small roaming foe and Cinderback behavior, hitboxes, boss HUD, and defeat flow.
- [ ] Verify the hunt can be completed and retried.

### Task 5: Camp, forge, languages, save

- [ ] Add failing tests for localized strings, forging costs, and save roundtrip.
- [ ] Implement English/Vietnamese UI, camp flow, inventory, forging, and local save.
- [ ] Verify an earned part persists after restarting and can pay for an upgrade.

### Task 6: Android delivery

- [ ] Configure package identity, icons, touch layout, export preset, and debug signing.
- [ ] Export an installable APK using matching templates and the available Android SDK.
- [ ] Run complete headless tests and inspect APK metadata. If a device is available, install and run it.
