# Briarwood Hunt Implementation Plan

**Goal:** Add a second original, playable Android hunt with separate art, foes, boss moves, and camp selection.

**Architecture:** Keep shared hunter and UI. A hunt id chooses the stage art and encounter. Separate beast scripts own their attacks; a catalog owns names and rewards.

**Tech Stack:** Godot 4.7.2, GDScript, ImageGen bitmap art, Android SDK.

1. Write failing tests for catalog data, Thornhart phases and antler break, and forest encounter selection; run each and confirm expected failure.
2. Add catalog, Thornhart, and boar scripts with the minimal behavior needed to pass tests.
3. Add Briarwood background and creature art to a forest stage variant. Wire two camp hunt buttons, retry, boss HUD name, and rewards through the selected hunt id.
4. Import the project, run all tests, render both hunts, export and sign a new APK.
5. Install on the connected phone and verify both hunt buttons, forest scene, combat controls, boss encounter, and error log.
