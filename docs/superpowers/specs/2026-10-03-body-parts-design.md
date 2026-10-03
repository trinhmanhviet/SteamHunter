# Body Parts and Wounds — Design Slice

This slice implements the part-hunting rule in the complete design with placeholder marks. It preserves the two existing hunts, three weapon styles, save data and the current art.

## Player experience

When near a large beast, the HUD shows one selected part. A new touch button cycles between two parts; Q does the same on keyboard. A thin brass ring over the beast marks the selected spot. A quick strike or heavy strike must reach that spot, so the hunter still needs to move, face the beast and sometimes jump. The boss bar remains hidden until the existing encounter distance.

Repeated hits expose a wound on an unbroken part. The HUD says it is open and the ring changes color. The next heavy hit on that spot deals extra damage and interrupts the beast's action once. The wound then closes. Breaking a part is permanent for the hunt, shows a short message and changes a specific boss move. A broken part cannot grant repeat break rewards.

## First two beasts

| Beast | Part | Break threshold | Position from body origin | Effect |
|---|---|---:|---|---|
| Cinderback | Back vent / Lỗ hơi | 50 | Above the back | Burst loses damage and reach; existing `armor_broken` reward behavior stays |
| Cinderback | Tail / Đuôi | 80 | Behind the beast | Tail sweep loses damage and reach; one extra part on victory |
| Thornhart | Antlers / Sừng | 65 | In front and high | Thorn attack loses damage and reach; existing `armor_broken` reward behavior stays |
| Thornhart | Hoof / Móng | 80 | At the rear leg | Charge slows and loses reach; one extra part on victory |

Quick hits add 35% of their health damage to part break progress; heavy hits add 100%. A wound opens after 45 part-progress points if the part is still intact. A heavy hit into an open wound adds 35% damage to the beast, forces at least 0.9 seconds of recovery, and resets wound progress. Part progress persists after wound closure. Breaking a part closes its wound. Health damage always applies once per landed hit; part progress is separate.

Default programmatic hits still target the primary part, so existing scripts/tests that call `receive_hit(amount, kind)` keep working. The hunter attack path supplies the selected ID and checks reach to that part. Invalid IDs cause no part progress, but damage still hits the beast only if main has already checked its encounter range; the UI never emits invalid IDs.

## UI and controls

The button sits above the right attack buttons and appears with the boss bar. Its label is the selected part followed by a cycle arrow. Beside the boss bar a compact line shows progress or “wound open”/“broken”. English and everyday Vietnamese strings are stored in `words.gd`. The marker is drawn in code and requires no new image. UI covers neither the hunter nor the target spot at the beginning of a hunt.

## Architecture and verification

`body_parts.gd` is pure state with `apply_hit`, `status`, and `broken_count`. Each beast owns its part definitions, point positions and move effects. `main.gd` owns the player's selected part and hit routing. `GameUI` only displays part status and emits cycle intent. Headless tests check repeated hit/wound/break rules, each beast's move reduction, the chosen part's real hit route, UI cycling, and reward count. The Android smoke check enters both hunts, changes the target button, and inspects the boss encounter screen and logcat. A complete manual hunt remains a separate gate.
