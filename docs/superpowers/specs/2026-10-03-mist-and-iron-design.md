# Mist & Iron / Sương và Sắt — Game Design

## Goal

Build an original Android side-scrolling, 2D pixel-art monster-hunting action game. Its hunt, gather, forge, and return loop should evoke the broad appeal of a monster-hunting game while using original names, silhouettes, art, maps, writing, and sound. No Monster Hunter characters, creatures, marks, UI, or assets are used.

## Setting and tone

The world is a damp European-inspired frontier of stone keeps, timber workshops, brass pipes, gauges, and hand-built steam gear. The first hunting ground is a misty moor with broken iron works. The visual palette is slate blue, moss green, warm brass, and ember orange. Graphics are deliberately pixelated at a low internal resolution.

The title is **Mist & Iron** in English and **Sương và Sắt** in Vietnamese. Vietnamese game text uses familiar everyday words rather than Sino-Vietnamese terms. There are no East Asian costume, architecture, weapon, or naming motifs.

## Core loop

1. At camp, choose a hunt, view gear and stock, and enter the moor.
2. Traverse platforms, fight smaller beasts, and pick up useful scraps.
3. Read the large beast's windups, dodge, strike openings, and break its armored part.
4. On victory, receive parts, return to camp, forge an upgrade, and try a tougher hunt.

The first shipped content includes a camp, a connected hunting stage, small roaming foes, one large multi-phase beast, a weapon upgrade, a hunt record, and local save data. More beasts and places can use the same encounter and loot interfaces.

## Combat

The player can run, jump, dodge with brief invulnerability, use a quick strike, and hold then release a heavy strike. Attacks spend stamina and include startup, active, and recovery timing. A clear flash and sound cue mark hit or armor break. A wounded hunter can return and retry without losing all progress.

The first large beast, the **Cinderback** / **Lưng Than**, is an original furnace-backed lizard with glowing vents and iron-like scales. Its moves are a rush, a tail sweep, and a vent burst. Telegraphs use animation and ground markers. Breaking the back vent weakens the burst and awards an extra part.

## Controls and UI

Landscape Android uses a left virtual stick and right buttons for jump, dodge, quick strike, and heavy strike. Desktop keyboard controls allow development and accessibility. Touch targets are large. HUD shows health, stamina, boss health, and the current objective. Camp and pause menus support English and Vietnamese.

## Architecture

Godot 4.7.2 and GDScript. Individual scenes and scripts own camp flow, hunter movement and combat, enemy behavior, stage hazards, HUD, touch input, inventory/crafting, localization, and save data. Pixel art is created for this project and checked into the repository. Game logic with deterministic outcomes gets headless tests; visual and device behavior gets editor/headless and Android export checks.

## Delivery

Provide the Godot source project, original art source, and an installable Android APK. Verify project import, script parsing, game startup, key game loop, and Android export. Without a connected Android device, state that device play was not verified.
