# Bastion Pike Combat Stick

## Purpose

Bastion Pike is the fourth vertical-slice weapon converted to a floating right-side combat stick. It preserves the measured, defensive reach role of a shielded lance while using an original mobile gesture grammar.

## Input

- Tap: Thrust chain.
- Pull up and release: Driving Thrust.
- Pull down and release: Guarded Hop.
- Hold then release: Shield Bash.
- Hold then pull down: Guard Set.

Drink and Jump remain separate support buttons, excluded from the combat-stick region. The target selector stays above that region.

## Role

The weapon controls space with a long thrust reach, spends Stability when blocking, and turns a blocked hit into Counter Thrust. It gives up fast movement for the ability to remain near a monster during dangerous attacks. The hold-down guard gesture intentionally requires commitment before a block.

## Verification

Gesture tests cover every command and the support-button exclusion. HUD tests verify the right stick replaces the previous four attack controls. The live flow test verifies Guard Set reaches the hunter controller and creates guard time.
