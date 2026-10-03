# Floating joystick and fullscreen layout

## Goal

The Android hunt screen fills wide phone displays without black side bars. Movement uses a hidden floating joystick that appears wherever the player first touches inside the lower-left control zone.

## Floating joystick

- The activation zone covers the left 35% of the visible game viewport and the lower 50% of its height.
- The joystick is invisible while idle.
- The first finger pressed inside the activation zone owns the joystick until that finger is released.
- The joystick center starts at the touch position, then clamps inward so the full visual ring remains visible inside the activation zone and screen bounds.
- Drag distance controls horizontal movement strength. Vertical drag remains visible but does not move the platform character vertically.
- Releasing the owning finger clears movement and hides the joystick immediately.
- Touches outside the activation zone do not activate movement.
- A second finger cannot move or release the joystick. It remains available for attack, heavy attack, jump, dodge, healing, pause, and target selection.
- Leaving the hunt or opening pause releases and hides the joystick.

## Fullscreen behavior

- The project uses an expanded viewport for aspect ratios wider than 16:9.
- Pixel art keeps its original proportions; the renderer reveals more world horizontally instead of stretching the image.
- The game world and camera fill the complete drawable screen, removing the black pillarbox areas.
- The left HUD remains attached to the left safe edge.
- Pause and the action-button cluster remain attached to the right safe edge on every supported aspect ratio.
- Vertical layout and control sizes remain based on the existing 540-unit reference height, which the user has approved.
- Android immersive mode stays enabled. Edge-to-edge drawing is enabled only if it does not place controls under a display cutout or gesture area; safe insets are respected.

## Architecture

`virtual_joystick.gd` owns touch capture, activation-zone validation, center clamping, direction strength, visibility, and release. `game_ui.gd` supplies the current viewport size and lays out the right-side controls from the actual right edge. Project display settings select expanded aspect scaling. Game logic continues to read the existing `move_left` and `move_right` actions.

## Verification

Automated tests cover hidden idle state, activation inside the zone, rejection outside the zone, center clamping near edges, proportional movement, release, finger ownership, simultaneous movement and attack, and layout placement at 16:9 and the connected phone's wide aspect ratio. The Android APK is then exported, installed through ADB, launched on the connected phone, and checked with a device screenshot for full-width rendering and correct floating-joystick behavior.
