# Cinderback break behavior

## Intent

The furnace-backed lizard gives a visible combat reward for hitting a chosen part. Each broken part removes its associated attack from the live move list, so targeting remains meaningful after the damage bonus has passed.

## Moves and breaks

| State | Available moves | Result |
| --- | --- | --- |
| Intact | Rush, Tail Sweep, Vent Burst | Full basic rhythm |
| Vent broken | Rush, Tail Sweep | Vent Burst is unavailable |
| Tail broken | Rush, Vent Burst | Tail Sweep is unavailable |
| Both broken | Rush | The hunter has earned a predictable finishing phase |

The legacy attack profiles remain available for data and UI inspection, but the broken move cannot be selected in combat.

## Recovery window

After every fourth completed attack, Cinderback spends 1.3 seconds exhausted before returning to its normal rhythm. The sprite lowers during that state so the opening can be read without relying only on a timer.
