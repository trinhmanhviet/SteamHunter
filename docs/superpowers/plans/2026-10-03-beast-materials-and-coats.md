# Beast Materials and Coats Implementation Plan

**Goal:** Make each large beast yield unique persistent trophies and turn those trophies into useful hunting coats.

**Architecture:** Hunt catalog maps hunts to trophy keys. Save data validates inventory and coat ownership. Pure rules own prices and protection values. Camp gear UI displays a separate coat tab, while hunter stats read the equipped coat at hunt start.

**Tech Stack:** Godot 4.7.2, GDScript, ImageGen bitmap art, Android SDK.

1. Write failing tests for trophy rewards, old-save migration, coat recipes, and combat effects.
2. Implement catalog, save schema, and pure coat rules; run tests green.
3. Write failing end-to-end tests for hunt rewards and coat purchase/equip; connect game flow and gear UI.
4. Add three original coat illustrations and show them in cards; render and inspect the gear screen.
5. Run the full test suite, export and sign APK, install on the phone, and inspect the armor tab and Android logs.
