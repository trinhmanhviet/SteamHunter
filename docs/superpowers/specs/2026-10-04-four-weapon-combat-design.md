# Four representative weapon combat systems

## Goal

Replace the shared quick/heavy prototype with four distinct, playable hunting archetypes. Each required weapon has eight or nine named actions, multiple combo branches, unique commitment, a resource loop, a defensive or advanced technique, and data that controls hit timing, reach, stamina, hit stop, stagger, knockback, and cancel windows.

The existing `blade` and `pike` IDs remain valid so old saves continue to work. They become the Heavy Great Blade and Fortress Lance roles. New IDs are `counter` and `twins`. The existing `maul` remains available as a legacy bonus weapon.

## Shared input language

- Light: basic chain and draw attack.
- Heavy: weapon-specific committed attack. Great Blade retains hold and release charge.
- Direction plus light: advancing branch.
- Light after dodge: dodge follow-up.
- Light while airborne: aerial attack.
- Special: brace, counter stance, overdrive, or guard stance.
- Inputs during the final cancel window are buffered and begin after recovery. Early inputs cannot cancel commitment.
- Leaving combat for long enough sheathes the weapon. The next light input uses the draw attack.

## Heavy Great Blade (`blade`)

Actions: Draw Hew, Low Cleave, Rising Cleave, Shoulder Brace, Charged Hew, Sundering Fall, Roll Reaper, and Aerial Drop.

Light chains Draw Hew → Low Cleave → Rising Cleave. Heavy charge has three payoff bands; releasing near full charge grants Resolve. Heavy after Charged Hew spends Resolve on Sundering Fall. Special during charge performs Shoulder Brace, which resists interruption but still takes reduced damage. Dodge and aerial branches use Roll Reaper and Aerial Drop. Slow recovery, strong hit stop, high part and stagger contribution define the weapon.

## Long Counter Blade (`counter`)

Actions: Draw Cut, Flow Cut, Returning Cut, Forward Thrust, Focus Arc, Counter Guard, Counter Riposte, Roll Draw, and Aerial Sweep.

Light chains build Focus. Direction plus light enters Forward Thrust. Heavy spends Focus on Focus Arc. Special opens a short Counter Guard; a correctly timed incoming hit prevents damage and launches Counter Riposte. A missed counter has long recovery. Successful timing restores some Focus, letting advanced players maintain pressure.

## Twin Blades (`twins`)

Actions: Draw Cross, Left Fang, Right Fang, Wheel Cut, Rushing Cross, Retreating Fan, Roll Slice, Aerial Scissors, and Overdrive Flurry.

Fast light chains build Tempo. Direction plus light advances with Rushing Cross, while heavy after the chain exits with Retreating Fan. Special spends Tempo to enter a short Overdrive Flurry that drains stamina and commits the player in place. Roll Slice and Aerial Scissors preserve mobility. Individual hits are light; sustained pressure and positioning produce the damage.

## Fortress Lance (`pike`)

Actions: Draw Thrust, Mid Thrust, High Thrust, Driving Thrust, Shield Bash, Wide Sweep, Guard Set, Counter Thrust, and Hop Thrust.

Light chains three thrust heights. Direction plus light uses Driving Thrust. Heavy branches to Shield Bash and Wide Sweep. Holding Special raises Guard Set, reducing frontal damage while draining guard meter and stamina. A blocked hit opens Counter Thrust. Light after dodge uses Hop Thrust. Movement is slow while drawn, but reach, guard stability, and quick thrust recovery let the hunter stay close.

## Combat data

Each action record contains damage, reach, duration, hit frame, combo-open time, stamina cost, resource gain/cost, movement impulse, impact class, hit stop, knockback, and stagger contribution. A weapon record contains entry actions, follow-up graph, resource name, maximum resource, walk multiplier, guard behavior, and art path. `rules.gd` keeps compatibility functions for existing game code and delegates to the catalog.

## Hunter state and hit confirmation

HunterController owns current action, buffered token, combo timer, resource, draw state, guard/counter windows, and hit stop. It emits the existing strike signal with the action ID. Main converts the action impact class to part damage semantics and calls `confirm_hit`, which applies resource gain and hit stop only on a landed hit. Incoming damage first checks counter or guard state before health loss.

## UI, save, and forge

The hunt HUD shows the current weapon resource and adds a Special touch button. Keyboard uses `I` for Special. The forge becomes a horizontal card scroller so all five weapons remain reachable on a phone. Save cleaning adds new ownership flags without removing old `blade`, `pike`, or `maul` ownership and falls back safely when a weapon ID is invalid. English and Vietnamese use short, plain labels.

## Verification

Data tests require eight or more actions for each of the four representative archetypes, distinct timings and movement roles, valid combo references, and complete action fields. Hunter tests cover combo buffering, charge bands, resource gain and spend, perfect counter, lance guard, twin overdrive, draw/dodge/aerial branches, commitment, and hit confirmation. Save and forge tests cover migration and all cards. The APK is installed on the connected ASUS phone and one action/resource loop is exercised for each weapon without script errors.
