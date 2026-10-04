# Weapon Tuning and Monster Weaknesses

## Purpose

Monster trophies become weapon preparation choices instead of passive counters in the inventory. Every owned weapon can keep several tuning branches and equip one branch before a hunt. The system stays original by using workshop tuning, material routing, and a shared snare buildup rather than copying named weapons, trees, or effects from another game.

## Tuning branches

- **Plain:** free baseline with no modifier.
- **Tempered:** costs iron parts and adds reliable raw damage against every creature.
- **Ember:** costs ash plates and adds heat damage. Thornhart is weak to heat; Cinderback resists it.
- **Briar:** costs thorn antlers and builds a snare status. Ashbell is vulnerable; Thornhart resists its own toxin.
- **Resonant:** costs bell cores and adds shock damage. Cinderback is weak to shock; Ashbell resists it.

Each weapon owns branches independently. Crafting a branch once keeps it permanently; switching between owned branches is free. Element and status output are scaled by each weapon's existing `element_scale` and `status_scale`, so Twin Blades build status quickly while the Great Blade favors raw tuning.

## Monster defenses

Each hunt catalog record stores heat and shock multipliers, a snare multiplier, and a snare threshold. Direct element bonuses are resolved at hit time. Briar hits fill a hunt-local meter; reaching the threshold interrupts the monster into a readable stagger and resets the meter. The HUD flashes the status proc.

## Interface and persistence

The forge gains a separate **Tuning** page beside Weapons and Coats. All five choices remain visible without a scrollbar. Cards show the branch effect, exact recipe, and whether it is equipped. Save schema 5 stores owned and equipped tuning per weapon and migrates every older save to Plain without losing existing progress.

## Verification

Pure tests cover recipes, elemental matchup math, weapon scaling, status buildup, and save migration. Flow tests cover buying, switching, carrying tuning into a hunt, and triggering snare. UI tests cover both languages and card visibility. The full suite, rendered panel, Android export, install, metadata, and runtime logs close the slice.
