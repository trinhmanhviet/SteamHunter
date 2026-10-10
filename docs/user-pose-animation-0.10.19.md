# User-authored poses in game — 0.10.19

The user edited three key poses in the prepared Blender workspace and approved
turning them into the Great Cleaver animation. Their saved scene was archived
separately and retained as the art reference.

## Grip fitting and motion

Measured shoulder-to-wrist target distances exceeded the existing arm lengths
by 2.8–16.2% at some keys. Instead of stretching limbs, the sword's pivot is
projected to the nearest point inside both arm reach discs in the side plane.
At the three main keys, adjustment lengths are about 4.14, 6.07 and 4.72 native
pixels. Sword angles and the authored body/foot poses remain unchanged; the
front toe receives a correction of less than half a pixel to plant it.

Four geometry tests cover already-reachable grips, one-boundary projections,
two-boundary intersections and impossible grips. The full export's maximum
wrist error is 0.00368px across all 74 frames. Existing rigid leg plates and
shared cloth seams are preserved. Body and sword are rendered separately with
holdout on every body/armor mesh, then packed into the existing 28-color format.

The overhead path and 74-cell phase layout are retained. Hold remains behind
the body; release moves over the head before the three strike cells. Contact
and the .22s/.48s follow-through/recovery timing remain unchanged. Blade
collision geometry is exported from the same metal meshes as the sword sprite.

## Game and phone verification

Sixteen relevant Godot suites and sixteen Python geometry/rig/sprite tests pass.
The Android build is version 0.10.19, code 37. It was installed on the connected
ASUS phone and Great Cleaver was explicitly equipped before testing.

Stationary holds of 850/1400/2300ms released their cuts. An approached charged
cut registered one physical contact for 48 damage and killed a Mire Rat. The
captured log has no script errors. Phone screenshots and video were inspected
for the rear hold, forward cut and recovery. Installed/release APK hashes match:

`98e6b27ce1142e5455f0e984cdf6727e5b2aa2b2472423b2be05719caa8e4bf9`

The workspace's latest local pose edits remain separate from this bake. The
next editor session should add shoulder/head/knee/tip/pommel controls; these
are recorded requirements, not shipped controls in 0.10.19.
