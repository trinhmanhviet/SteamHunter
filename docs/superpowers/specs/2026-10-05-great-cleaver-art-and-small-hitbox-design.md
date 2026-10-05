# Great Cleaver art and small-enemy strike height

## Great Cleaver presentation

The Great Cleaver uses a four-pose original pixel-art strip: carry, overhead charge, committed cleave, and low recovery. It renders as a separate oversized sprite over the hunter, so the weapon can change pose without replacing the hunter's body sprite.

| State | Pose |
| --- | --- |
| Sheathed or moving | Carry |
| Holding a charge / early attack | Overhead charge |
| Hit frame onward | Committed cleave |
| Late recovery | Low recovery |

This reinforces the weapon's slow commitment and long reach while retaining its own naming, resource flow, and mobile gesture routing.

## Great Cleaver hit zones

The heavy blade now evaluates a forward 2D hit zone for each action instead of treating every swing as a single horizontal line. Rising Cleave reaches high targets, Aerial Drop reaches down to the ground, and Sundering Fall has the longest forward zone. The rear edge stays tight, so a target behind the hunter is not hit by a forward cleave.

## Small-enemy strike volume

Small enemies can only damage the hunter while both are within 82 horizontal pixels and 28 vertical pixels. This keeps ground bites from hitting a hunter who is on a platform above or jumping over the creature.
