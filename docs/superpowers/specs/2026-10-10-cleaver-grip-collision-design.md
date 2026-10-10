# Great Cleaver grip, +40% length and actual contact

User requested fixing hands pressed into chest, lengthening the sword by 2/5,
removing provisional slash lines and making damage require blade/monster contact.
User's standing autonomous implementation/build/install authorization applies.

Move the two-hand grip in front of the torso, open the elbow pose, keep distinct
hand positions along the handle and validate the poses before full rendering.
Scale the weapon's longitudinal axis by 1.4, preserving blade width and character
size. Adjust the lowered angle so the longer tip does not penetrate the floor.

Export the actual projected metal blade polygon, pivot and rotation per frame.
Interpolate the blade through the short active downswing and subdivide the sweep
into small steps, avoiding one large fan that would count empty space as contact.
Test against polygons extracted from each monster sprite's alpha silhouette,
including its scale, transform and flip. Apply damage at most once per monster
per swing. Charge, idle and recovery do not create an active damage sweep.
Retain non-Great-Cleaver combat logic and existing selected-part reward behavior.

Remove the provisional line rendering. Test silhouette holes/empty pixels,
near-misses, real overlaps, mirrored targets, airborne gaps, fast sweeps and hit
deduplication. Visually inspect hands, sword length and floor contact, then run
the main game on Android and publish/install 0.10.15 with the user's clip tool intact.
