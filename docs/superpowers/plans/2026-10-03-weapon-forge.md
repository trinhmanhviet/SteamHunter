# Weapon Forge Implementation Plan

**Goal:** Add persistent weapon choice with three distinct combat styles and matching character art.

**Architecture:** Pure combat rules define weapon stats and prices. Save data owns unlocked and equipped weapons. Camp flow opens a gear page; the hunter receives the equipped id before entering a hunt. Sprite variants are selected by the hunter without changing the creature scripts.

**Tech Stack:** Godot 4.7.2, GDScript, ImageGen art, Android SDK.

1. Write and run failing tests for weapon stat differences and prices.
2. Write and run failing tests for old-save migration, buy/equip behavior, and hunter attack cost.
3. Implement rules and save schema, then the camp gear flow.
4. Add weapon-specific hunter art, timing, reach, stamina and attack marks.
5. Render the gear screen and all three weapon looks. Run the full test suite.
6. Export and sign the Android APK, install it on the connected phone, and verify gear selection, save data, combat, and logs.
