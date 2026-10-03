# Responsive UI anchors

## Goal

Every interface group keeps a stable relationship to the visible viewport on 16:9 and wider Android screens. No panel remains tied to the left side merely because its original coordinates were authored for 960 by 540.

## Anchor rules

- The hunt status panel, material count, potion count, and language button stay attached to the left edge.
- The hunt action buttons and pause button stay attached to the right edge.
- The camp hunt-selection panel stays 28 reference units from the right edge.
- The camp title block follows the viewport center while preserving its original 16:9 position.
- The forge screen, pause dialog, and hunt-result dialog stay centered as complete groups.
- The boss display and transient hunt message follow the viewport center while preserving their existing offset from the 16:9 center so they do not collide with the left HUD.
- Vertical positions and all control sizes remain unchanged.
- A 960 by 540 viewport produces the approved current layout with no coordinate changes.

## Implementation

The game UI calculates two horizontal offsets from the logical viewport: a full right-edge offset and a half-width center offset. Each screen applies one of these offsets to every element in a group. Named panel nodes make the anchor contract testable and help future layout work.

## Verification

The mobile UI test renders the interface in 960 by 540 and 1224 by 540 subviewports. It verifies the camp selection panel at the right edge, the forge panel at the center, the pause and result dialogs at the center, the hunt controls at the right edge, and the left HUD at its original position. The Android APK is installed and visually checked on the connected 2448 by 1080 phone.
