# Reference idle, running and stationary charge — 0.10.20

The user requested running with the sword on the back and a held idle when
stopping, then supplied two Great Sword idle images and one diagonal carry
reference. The character and weapon keep their original project designs.

## Implemented

- 12-cell run with alternating support/swing legs, opposite arms and a rigid
  spine attachment crossing one shoulder toward the opposite hip in 3D.
- Braced idle with separated feet, a low two-handed grip and a 48-degree
  upward blade in front. Four short draw cells lead to it after stopping.
- Ready/raise/recovery now begin/end in this idle. Held charge, release, three
  strike cells and follow-through retain their accepted images and geometry.
- Movement drives run cadence. Charge stops horizontal travel, ignores facing
  movement and prevents jumping; gravity remains normal if already airborne.
- Running, idle and drawing have no active sword damage. Combat takes priority.

## Verification

17 Godot suites pass, including movement cadence, stop-to-idle, charge input
blocking and unchanged combat timing/contact behavior. 20 Python tests and the
actual locomotion export check pass. All 51 protected combat cells are identical
to the accepted version; ready, first raise, final recovery and idle decode to
the same pictures in both layers. The established canonical blade outline is
retained. All 91 cells pack without clipping; locomotion maximum wrist error is
0.00306px, combat transitions maximum 0.00392px.

Android version 0.10.20, code 38, is installed on the connected ASUS phone.
Right/left runs, stopping, idle and charge after movement were recorded and
visually inspected. During a stationary touch charge, a simultaneous held right
direction key was injected; the hair marker moved only 0.75 physical pixels due
to the pose's small breathing change, consistent with the native exact-position
test. A charged cut registered one 48-damage contact with a Mire Rat. The app
log has no script errors. Installed and release APK hashes match.

APK SHA256: `792679abb855cf778cf4ca82f478adb5827b989adf7ef2fa53d74e0fc6ee2574`

The user's local pose edits and clip-tool files are preserved. Additional
shoulder/head/knee/sword-end editor handles remain the next editor requirement.
