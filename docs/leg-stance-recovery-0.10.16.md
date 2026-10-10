# Great Cleaver 0.10.16 — leg armor and recovery

## Scope and reference

Use the user's MonsterHunterWildsGreatSwordTu clip and extracted raise, overhead,
impact and recovery poses. Correct the existing asset and timings, with no new
animation system or additional moves. The side view retains the front leg bracing
and rear knee bending as the blade descends. The longer blade's floor angle and
approved two-hand grip are retained.

## Leg armor

The old skin weights blended shin armor across foot, shin and thigh, warping the
greave as the knee/ankle bent. Boots now follow the foot, the middle of each greave
follows its own shin, and only narrow ankle/knee sections blend between joints.
The existing hip/foot targets have been adjusted to reduce the excessive rear
heel lift and over-compressed crouch. Knee poles are aligned with forward bends.

All 74 body/weapon frames have been rendered again. Maximum wrist IK error is
0.00304 native pixels; atlas canvases, hunter scale and 1.4x weapon length remain
the same. No body/weapon frame is clipped. Key poses were visually compared with
the previous render and the supplied clip frames before promotion.

## Recovery

Previously, the same animation was stretched to each action's remaining time:
some recovered in about .2 seconds, while others took over 1.7 seconds. Every
action using this overhead sprite set now uses a fixed post-hit sequence:

- Contact frame: 1/30 second.
- Follow-through: .22 second.
- Return to stance: .48 second.
- Total after contact: .733333 second; the ordinary draw cut totals 1 second.

Combo input opens during the last .12 second and the queued move starts after
recovery finishes. Existing startup/hit timings, impact hit-stop, charge hold,
blade contact and target deduplication remain in effect. Shoulder Brace retains
its own body-action timing. These are gameplay timing adjustments, not a claim
that the original clip has the same duration.

The preview and standalone demo source use the same new timings. Previously
released standalone demo APK 0.1.0 is historical and has not been replaced.

## Verification

Eight Python rig checks, fourteen native Godot combat/art suites and eighteen
standalone cycle assertions pass. The recovery suite verifies identical frame
progression at equal post-hit offsets across ten GS actions, including a frame
boundary that previously differed due to floating point subtraction.

On the connected phone, two distant cuts produced no contact events. After
approaching a Mire Rat, the charged cut produced one 48-damage contact and killed
it. The recorded session has no SCRIPT ERROR. The installed APK SHA256 matches
the release APK; results are in `leg-stance-recovery-0.10.16-verification.json`.
