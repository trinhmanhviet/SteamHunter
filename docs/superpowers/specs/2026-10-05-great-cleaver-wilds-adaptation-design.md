# Great Cleaver Wilds Adaptation

## Purpose

This design updates Great Cleaver into the first full combat-focused weapon pass. The target is not to copy Monster Hunter Wilds. The target is to carry the heavy Great Sword fantasy into this game: read the beast, plant your feet, commit to a huge blade, and turn a monster opening into one decisive hit.

The existing mobile combat stick remains the base. It already supports tap, hold, release, upward pull, downward pull, floating placement, and support-button exclusion. This design deepens the move routing behind those gestures.

## Research Notes

Monster Hunter Wilds Great Sword is built around a small set of readable ideas:

- The main route is a charged ground route: Charged Slash, Strong Charged Slash, and True Charged Slash. Each has three charge levels. Holding too long overcharges and weakens the result instead of adding a fourth level. Source: [Redgauge Wilds Great Sword Guide](https://wilds.redgauge.app/en/guides/weapons/great-sword/) and [GamesRadar Great Sword guide](https://www.gamesradar.com/games/monster-hunter/monster-hunter-wilds-great-sword/).
- Tackle lets the hunter accept a hit without being knocked away and keep the charge route moving. Source: [Redgauge Wilds Great Sword Guide](https://wilds.redgauge.app/en/guides/weapons/great-sword/).
- Offset Rising Slash is a timed, chargeable clash against an incoming monster attack. A success opens a follow-up before the biggest route if the monster stays open. Source: [Redgauge Wilds Great Sword Guide](https://wilds.redgauge.app/en/guides/weapons/great-sword/).
- Perfect Guard can turn defense into a punish, and some heavy guards build toward a Power Clash. Source: [Redgauge Wilds Great Sword Guide](https://wilds.redgauge.app/en/guides/weapons/great-sword/) and [GamesRadar Great Sword guide](https://www.gamesradar.com/games/monster-hunter/monster-hunter-wilds-great-sword/).
- Focus Mode helps aim heavy charges, while Focus Strike: Perforate targets wounds and can create an immediate big-hit route. Source: [Redgauge Wilds Great Sword Guide](https://wilds.redgauge.app/en/guides/weapons/great-sword/).

## Adaptation Rule

We use the mechanical roles, not the copyrighted presentation. The in-game names, animation silhouettes, UI text, art, timings, enemy reactions, and combo graph stay original to Mist & Iron.

Monster Hunter terms may appear in this design only as research anchors. Player-facing game text should use the Mist & Iron terms below.

| Research role | Mist & Iron move |
| --- | --- |
| Basic overhead / draw hit | Draw Hew |
| Charged Slash | Charged Hew |
| Strong Charged Slash | Furnace Hew |
| True Charged Slash | Sundering Fall |
| Tackle | Shoulder Brace |
| Offset Rising Slash | Anvil Rise |
| Follow-up Cross Slash | Crossbite |
| Perfect Guard | Iron Guard |
| Focus Strike on wound | Rivet Pierce |
| Focus Mode aim correction | Edge Aim |
| Overcharge penalty | Spent Edge |

## Chosen Approach

### Option A: Keep the current weapon and tune numbers

This is fastest, but the weapon would still feel like a large normal sword. It would not answer the user's request for a proper Great Sword style.

### Option B: Add a full route system to Great Cleaver

This keeps the current touch scheme and adds charge route depth, brace routing, readable counter timing, guard punish, wound piercing, and overcharge. It makes the weapon feel heavy without adding more buttons. This is the recommended approach.

### Option C: Split Great Cleaver into many separate buttons

This would expose every move directly, but it fights the user's earlier feedback that the screen already had too many buttons. It also makes Android play worse.

## Input Design

The right combat stick remains the only Great Cleaver attack surface. Drink, Jump, and Target Cycle stay as support buttons.

| Gesture | Neutral state | While charging | During recovery window |
| --- | --- | --- | --- |
| Tap | Draw Hew or next simple cleave | Release current charge | Buffer next hew |
| Hold | Begin Charged Hew | Keep charging | Continue the charge route if allowed |
| Release hold | Commit current charge tier | Commit current charge tier | Commit buffered route |
| Pull up and release | Anvil Rise | Charge Anvil Rise | Buffer Anvil Rise if recovery allows |
| Pull down | Roll | Shoulder Brace | Shoulder Brace |
| Hold near wound target | Rivet Pierce prompt appears if wound is in range | Rivet Pierce charges in place | No prompt |
| Hold toward monster while charging | Edge Aim adjusts hit zone up, down, or forward | Edge Aim continues | No aim correction after hit frame |

Left stick movement is slowed while charging. Edge Aim permits a small facing and vertical-arc correction, but it cannot spin the hunter instantly. The player still needs to choose the opening early.

## Charge Route

Great Cleaver gains a route index in addition to charge time.

| Route | Move | Role |
| --- | --- | --- |
| 0 | Charged Hew | First committed charged hit |
| 1 | Furnace Hew | Higher damage after Brace or a landed Charged Hew follow-up |
| 2 | Sundering Fall | Highest commitment finisher |

Each charged route has three charge levels:

| Charge level | Feel | Rule |
| --- | --- | --- |
| Level 1 | early release | reliable but modest |
| Level 2 | solid release | default safe payoff |
| Level 3 | flash release | best payoff and strongest hitstop |
| Spent Edge | held too long | drops to Level 2 damage and adds recovery |

The combat stick ring should show three clear beats. At the third beat, a short flash marks the best release window. If the player keeps holding past that window, the ring cracks/dims to show Spent Edge.

## Brace And Guard

Shoulder Brace becomes the route-preserving body check:

- Pull down during a charge to Brace.
- Brace reduces incoming damage, resists knockback, spends stamina, and advances the route by one if it absorbs a hit or is used during a valid route window.
- Brace deals small blunt damage only when the shoulder box actually touches a monster.
- Brace cannot be spammed for invulnerability. It has recovery and stamina cost.

Iron Guard is separate from Brace:

- Hold down from neutral without enough pull distance to roll enters a short guard stance.
- A timed guard during the first guard frames becomes Iron Guard.
- Iron Guard can immediately route into Charged Hew or Furnace Hew depending on the guarded attack strength.
- Repeated successful Iron Guards against boss heavy attacks build a Clash meter. When full, the next heavy guard triggers a short lock animation and a guaranteed knockdown window.

## Counter Route

Anvil Rise is the prediction counter:

- Pull up and hold to charge Anvil Rise.
- Release as a monster attack hurtbox arrives.
- If the blade hit zone and monster attack zone overlap inside the active clash window, the monster is staggered and the player gets Crossbite.
- Crossbite is a fast two-hit step-in slash that sets route index 2 if it lands.
- If Anvil Rise hits only the monster body without clashing with an attack, it is just a rising hit and does not unlock Crossbite.
- Missing Anvil Rise has long recovery.

This preserves the Wilds read-before-the-hit idea while fitting our 2D platform combat.

## Wound Route

Rivet Pierce is the wound punish:

- Boss parts that are repeatedly hit by heavy actions can enter a visible wounded state before they break.
- When a wound is targeted and inside Great Cleaver range, holding the combat stick toward it shows a Rivet Pierce cue.
- Release inside the cue to plant the blade into the wound.
- Holding Rivet Pierce adds repeated small ticks, then a heavy rip-out hit.
- Breaking a wound grants a short knockdown or part stun and opens route index 2.

Small enemies do not need wounds. They should react to Great Cleaver with heavy knockback, bounce, or armor crack behavior instead.

## Animation And Feel

Great Cleaver needs a heavier pose set:

- Carry: blade drags behind the hunter while walking.
- Charge 1: blade rises to shoulder height, feet planted.
- Charge 2: blade comes overhead, smoke/steam flickers from the edge.
- Charge 3: body leans back and the edge flashes once.
- Spent Edge: the blade shakes, glow dims, and the hunter overbalances.
- Charged Hew: forward overhead crash, dust from feet.
- Furnace Hew: same family but lower stance and longer pull-through.
- Sundering Fall: full-body drop, large arc, strong screen shake, largest hitstop.
- Shoulder Brace: low shoulder shove with blade used as counterweight.
- Anvil Rise: grounded upswing, clear clash spark on success.
- Crossbite: two short crossing cuts, faster than the main route.
- Rivet Pierce: blade point drives into a wound, repeated sparks, rip-out.

The current generated blade strip can remain temporary. The next art pass should replace it with a dedicated hunter-and-blade strip so the old small weapon is no longer visible under the overlay.

## Collision And Damage

The current Great Cleaver hit zones should become per-move volumes with clear intent:

| Move | Zone shape | Notes |
| --- | --- | --- |
| Draw Hew | short forward vertical wedge | catches close small enemies |
| Charged Hew | tall forward overhead box | main reliable charge |
| Furnace Hew | wider forward box, slightly lower | designed for boss body parts |
| Sundering Fall | longest forward and downward box | big commitment, strong part damage |
| Shoulder Brace | short body box | only hits if body touches |
| Anvil Rise | forward-up crescent | can clash with incoming attacks |
| Crossbite | two short forward boxes | confirms counter route |
| Rivet Pierce | narrow wound-locked box | requires targeted wound |

Enemy attacks need their own strike volumes with vertical range, not only distance checks. The recent small-enemy fix should become the rule for every contact attack: both horizontal and vertical overlap must be true before damage is applied.

## Boss Integration

The current bosses can support this without a full rewrite:

- Cinderback: shell, head, and legs can receive wound states. Shell wounds reward Rivet Pierce. Charge tells are good Anvil Rise training.
- Thornhart: antlers and hooves can wound before breaking. Hoof attacks are good Iron Guard training.
- Ashbell: horn and bell core wounds create the largest Great Cleaver openings. Toll and ram attacks test Brace versus Iron Guard choices.

Each boss should gain at least one long recovery after a broken part or failed heavy attack so Sundering Fall has a fair window.

## HUD

Great Cleaver HUD needs four compact signals:

- Route pips: three small blade marks near the stamina/resource area.
- Charge ring: already on the combat stick, extended with Level 1/2/3 beats and Spent Edge dim.
- Clash glint: a brief spark on the hunter when Anvil Rise or Iron Guard can succeed.
- Wound cue: a small rivet icon above the target part when Rivet Pierce is available.

No extra attack buttons are added.

## Implementation Scope

This should be implemented in passes:

1. Add charge levels, route index, overcharge, and Edge Aim to the existing Great Cleaver charge.
2. Upgrade Shoulder Brace so it can preserve and advance the route when it absorbs real attacks.
3. Add Anvil Rise and Crossbite, including attack-zone clash checks.
4. Add Iron Guard and the boss Clash meter.
5. Add wound states and Rivet Pierce for boss parts.
6. Replace temporary Great Cleaver overlay with a dedicated pose strip.
7. Tune damage, stamina, hitstop, knockback, and recovery on Android.

## Verification Plan

Focused automated tests:

- Charge levels reach Level 1/2/3 and Spent Edge at the expected times.
- Overcharge reduces the result and increases recovery.
- Brace reduces damage only inside its active absorb frames.
- Brace advances route after a real absorbed hit.
- Anvil Rise unlocks Crossbite only after clashing with an incoming attack zone.
- Anvil Rise body hits do not unlock Crossbite.
- Crossbite landing opens Sundering Fall.
- Iron Guard requires timing and routes into the correct charged follow-up.
- Rivet Pierce appears only for targeted wounded parts inside range.
- Small enemy and boss contact attacks require horizontal and vertical overlap.
- Mobile combat stick still supports movement stick, Drink, Jump, and Target Cycle without touch conflicts.

Manual Android checks:

- The weapon feels slow and heavy, but not stuck.
- The right stick remains learnable without button clutter.
- The third charge flash is readable on a phone screen.
- Heavy hits have visible hitstop and knockback.
- Bosses give enough readable openings for Sundering Fall after part breaks, wound breaks, counters, and guards.

## Approval Question

If this design looks right, the next step is an implementation plan for pass 1 through pass 3 first: charge route, overcharge, Edge Aim, upgraded Brace, Anvil Rise, and Crossbite. Iron Guard, wounds, Rivet Pierce, and final art should follow after the base route feels good in hand.
