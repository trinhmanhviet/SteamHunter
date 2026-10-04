# Ashbell Ram third hunt design

## Goal

Add the third large monster required by the vertical slice as a complete playable hunt in Smoke Moor. Ashbell Ram is an original European dark fantasy steampunk beast whose combat teaches players to read rhythms, move across platforms, and choose between disabling mobility or disabling area attacks.

## Identity and ecology

Ashbell Ram is a heavy soot-dark ram that wandered from old foundry pastures. Hollow bronze horns amplify every impact, while a cracked brass chamber on its chest stores the vibration. It scrapes slag from ruined machinery and rings its horns to warn Mire Rats away from feeding grounds. The generated side-view sprite is original, uses a transparent background, and contains no borrowed game symbols or East Asian motifs.

The hunt ID is `ashbell`. It reuses the Smoke Moor route with a different distribution of herbs and Mire Rats. The encounter begins near the final foundry floor so the existing platforms remain useful for jumping over ground waves.

## Combat language

Ashbell Ram has five attacks:

1. `charge`: a long straight horn rush used at range.
2. `horn_swing`: a close arc with a clear head dip before impact.
3. `toll_blast`: a wide resonance pulse centered on the chest chamber.
4. `hoof_quake`: a ground wave with a safe aerial answer.
5. `rebound`: the second beat of a charge combo, turning after a brief pause and rushing back faster.

Normal attacks use long, readable windups and meaningful recovery. Below half health the ram enters phase two: movement and attack cadence increase, and every third long-range charge can flow into Rebound. After five completed attacks it becomes exhausted for 1.6 seconds, lowers its head, and exposes both break points.

## Breakable parts

- `horn`: breaking it shortens Charge and Horn Swing reach and reduces charge speed. It also prevents the Rebound combo.
- `chamber`: the primary armored part. Breaking it sets `armor_broken`, disables Toll Blast, and removes its wide damage field. The selector falls back to Hoof Quake when Toll Blast would have been chosen.

Both parts support wounds, heavy-hit stagger, separate durability, target markers, and distinct English/Vietnamese labels. Breaking the chamber displays `RESONANCE CHAMBER BROKEN!` / `VỠ KHOANG CHUÔNG!`.

## Integration and verification

`ashbell_ram.gd` follows the same signals and public boss contract as the two existing large monsters. `hunt_catalog.gd` lists `ashbell` after Briarwood with a base reward of seven parts. Camp selection, retry, records, save compatibility, target cycling, reward calculation, and boss HUD continue through the catalog-driven flow.

Headless tests cover the five attack profiles, phase change, exhaustion, each part break effect, catalog entry, live hunt spawn, reward, record, and retry behavior. Android verification installs the next APK, launches it on the connected ASUS phone, and checks package metadata and logcat.
