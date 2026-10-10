# Great Cleaver 0.10.15: grip and blade contact

## Art

Hands move in front of the torso rather than being pressed into the chest. The
grip has separate hand positions, forward elbow poles and anatomical wrist sides
after accounting for the weapon pivot's 180-degree facing rotation. All 74 frames
were rendered again. Maximum IK wrist error is 0.00323 native pixels.

The weapon's long axis is scaled by exactly 1.4; width and hunter size are retained.
The lowered angle is adjusted for the longer blade, keeping it above the floor.
All rendered layers remain inside their original fixed canvases.

## Damage contact

The renderer exports metal blade geometry, origin and angle. The game uses the
same frame indexes as the visible sword, and sweeps between displayed poses with
small subdivisions (at most 2 degrees / 2 native pixels of translation). One huge
fan-shaped hull is deliberately not used. Broad bounding boxes only reject distant
targets; they never grant damage.

Targets are exact opaque-pixel rectangles merged into sprite silhouettes, so
transparent padding and internal holes cannot be hit. Their transform, scale and
flip are included. A blade must overlap this silhouette during the active swing.
Each target can receive one hit per swing. Charge, idle and recovery do not create
damage. Shoulder Brace uses the visible body silhouette rather than metal.

The old Great Cleaver padded reach/height checks are removed from live damage.
Non-GS weapon routes retain their existing behavior. Selected boss-part reward
logic is preserved; this change does not introduce individual part colliders.
The temporary straight slash lines are removed from hunter rendering.

## Verification

Native Godot tests cover transparent gaps/holes, sprite flips/regions, fast blade
sweeps, empty areas near the handle, actual hits, near misses, one-hit deduplication,
airborne gaps, selected-part progression, other weapon routes and character scale.

On the connected Android phone, an out-of-range cut produced zero contact events.
After approaching a Mire Rat, a charged cut produced one contact event and defeated
the rat. The 12-second screen recording and app log contained no script errors.
The installed APK's SHA256 is checked against the release file in verification JSON.
