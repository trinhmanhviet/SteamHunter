# Weapon Forge Design

The camp gains a gear screen with three original hunting weapons. The cleaver remains the starting weapon; a long pike and a heavy forge maul are unlocked with parts earned from hunts. The equipped choice persists and appears in the hunter's hands during either hunt. The gear screen also holds the existing forge-rank upgrade, which improves all three weapons.

The cleaver is balanced. The pike reaches farther and attacks with lower damage. The maul has a shorter reach, higher stamina cost, slower strikes, and heavier damage that breaks beast armor sooner. Quick and charged attacks still use the same touch buttons. The weapon changes numeric damage, reach, stamina cost, timing, drawn attack effect, and hunter art. A saved game from version 0.3.1 gains the new fields safely, with the cleaver owned and equipped.

The gear screen uses three cards with the matching original hunter cutouts, plain English and everyday Vietnamese names, cost or equip actions, part count, shared forge upgrade, and a return button. Buying a weapon equips it. Choosing an owned weapon equips it without cost. The hunt menu stays separate so its two options remain large touch targets.

Godot tests cover weapon balance, save migration, buying/equipping, insufficient parts, and the hunter's attack cost. The build is then rendered, exported, installed, and exercised on the connected Android phone.
