# Mobile hunt controls

The user chose a landscape platform hunt with MOBA style touch controls. A circular left joystick replaces the two movement arrows. Drag distance sets horizontal walking speed and the stick returns to center when released. Vertical stick motion is retained visually; platform movement uses its horizontal value. A touch on the joystick must not block another finger from attacking or jumping.

The right thumb area places a large basic strike button near the lower right corner. Smaller heavy strike, dodge, and jump buttons form an arc to its left and above. The potion is above that arc; pause remains at the top right. These controls use the game's own brass and dark steel appearance and text labels. Keyboard controls continue to work on desktop.

Each control owns one touch index from press through release. A second finger cannot steal it. Releasing, leaving a hunt, or hiding the UI clears held actions, especially the charge attack. Automated tests cover analog strength, dead zone, independent touches, release, and layout. The exported Android build is checked on the connected phone.
