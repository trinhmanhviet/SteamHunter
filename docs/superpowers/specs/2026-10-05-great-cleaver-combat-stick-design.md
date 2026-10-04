# Great Cleaver Combat Stick

## Purpose

Great Cleaver is the first weapon rebuilt around a compact mobile control scheme. It keeps the deliberate prediction-and-commitment role of a huge blade, but uses an original drag language and original move names.

## Input

The left lower region remains a floating movement stick. The right lower region is a floating combat stick that appears under the player’s touch. The stick excludes the small Drink and Jump buttons, which remain available in the support cluster.

- Tap or release without a pull: **Cut**. It starts the draw hew or the next cleave.
- Pull upward and release: **Lift**. It selects the rising cleave branch.
- Pull downward and release: **Roll**. It spends stamina to reposition.
- Hold for 0.18 seconds: **Charge**. The stick ring fills while the hunter is charging.
- Release a Charge: **Charged Hew**. Charge duration sets its bonus damage.
- Pull downward while charging: **Brace**. It cancels the charge into the short defensive body check.
- Hold again inside the late Charged Hew window with a full Resolve mark: **Sundering Fall**. Pull downward instead to replace that finisher with Brace.

The boss part selector stays in the upper-right corner for this weapon so it is outside the combat-stick region.

## Combat role

The weapon has slow, high-reach cleaves and is rewarded for using readable openings. A fully charged hit earns Resolve, and Resolve permits the committed Sundering Fall finisher. Brace is an escape route from a charge or a late Charged Hew that trades damage for a short damage-reduction window. The hunt opens with a brief gesture hint; the deeper charged-cut route is learned through its visible Resolve mark and recovery window.

## Integration

`blade_combat_stick.gd` recognizes touches, draw state, support-button exclusion rectangles, and emits named commands. `game_ui.gd` installs it only for `blade`; all other weapons retain the previous button cluster while their controls are developed later. `main.gd` routes the commands to explicit Hunter methods. `hunter.gd` owns the charge and action state so keyboard controls and mobile gestures share the same combat rules.

## Verification

Focused tests cover held charge, release into Charged Hew, Brace, touch-zone ownership, support-button exclusion, and wide-screen sizing. Existing mobile, action, HUD, tuning, save, hunt, and monster tests remain part of the complete suite. Android verification uses the real connected device because the Windows headless movie renderer crashes while recording the pixel-art scene.
