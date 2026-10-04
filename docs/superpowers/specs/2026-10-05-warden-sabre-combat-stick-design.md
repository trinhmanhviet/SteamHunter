# Warden Sabre Combat Stick

## Purpose

Warden Sabre is the second mobile weapon converted from a button cluster to a floating right-side combat stick. It keeps a mobile, timing-focused counter role while using an original gesture grammar and original action names.

## Input

- Tap: Cut, including the draw cut and flowing chain.
- Pull up and release: Lift, which selects the forward thrust branch.
- Pull down and release: Dodge.
- Hold then release: Focus Arc, spending Focus for a strong committed arc.
- Hold then pull down: Counter Guard. A successful timed guard flows into the existing riposte action.

The movement stick stays in the lower-left zone. Drink and Jump retain their support buttons and are excluded from the right-side combat zone. The part selector moves above the combat region.

## Role

Cuts restore Focus and keep short recovery windows. The player can cash out Focus through Focus Arc, or commit to Counter Guard to intercept an incoming hit. Unlike Great Cleaver, this weapon is rewarded for continuous pressure and timing rather than a single predicted burst.

## Verification

Gesture tests cover cut, thrust, dodge, Focus Arc, Counter Guard, and button exclusion. UI tests cover the replacement of the four attack buttons, hint display, and cleanup on leaving a hunt. Flow tests route the counter command through the live controller.
