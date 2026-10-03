# Briarwood Hunt Design

The next content slice adds a second complete hunt to the existing Android game. The player chooses either the smoky moor or the thorn forest from camp. Both hunts share the hunter, touch controls, save data, and forge. Each has its own setting, small foe, large beast, attack rhythm, and reward.

The new forest hunt uses original generated art: a damp European wood with ruined stonework and brass steam pipes, a thorn-covered boar, and Thornhart, a giant mossy stag with antlers and a pressure vessel. In Vietnamese, the forest is **Rừng Gai** and the beast is **Hươu Gai**. Names and UI use common Vietnamese words. No designs or marks from an existing game are used.

At camp, two large buttons name the hunts. Choosing one launches its stage directly. The moor keeps its current Cinderback and mire rats. The forest uses boars and Thornhart. Thornhart alternates a charge, an antler sweep, and a thorn burst. Its antlers can break under heavy strikes, reducing the burst and adding a reward part. A hunter defeat permits retrying the same hunt; victory returns parts to persistent stock.

The existing stage and game flow accept a hunt identifier. A small catalog owns the two hunts' names and reward values. The UI receives the catalog data, while each beast retains its own movement and combat rules. Tests cover catalog lookup, forest spawning, Thornhart phase and break behavior, and retry selection. The Android build is then installed and checked on the connected phone.
