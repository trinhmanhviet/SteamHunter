# Approved reference skeleton animation — 0.10.18

The user reviewed twelve skeletal pose sketches drawn over their extracted
Great Sword clip frames, then authorized trying them in the game.

## Retargeting

The existing Blender rig reads `prototypes/reference_skeleton/poses.json`.
Blade direction and trunk lean come from those joint coordinates; the clip's
leftward cut is mirrored to the game's default right-facing hunter. A small table
sets the existing hip, grip and foot controls for the side view. Anatomical bone
lengths, grounded feet, separate weapon/body layers and the corrected greaves
remain constraints. The perspective sketches are not claimed as recovered 3D
motion capture.

Mapping: source 23/24/26/28/29 build the raise and braced hold; 30/31/32 supply
the three downswing cells; 40 supplies follow-through; 68/76/84 supply recovery.
The closing transition returns to the source-23 shouldered stance. This closing
transition is a game adaptation because the clip switches camera after frame 84.

Projected trunk lean is capped at 68 degrees and the straight weapon's downward
angle at 17 degrees to retain anatomy/floor clearance. Hold has about 30 degrees
of forward trunk lean and .47 body-height units between foot targets. Both knees
bend, the hips lower and the arms brace in front of the torso. Impact follows
through into a deeper crouch instead of keeping the body nearly upright.

The first key render exposed unreachable grips. Targets were brought within the
existing arms' reach before the full render, without stretching bones. Across
all 74 final frames, maximum wrist IK error is .00361 native pixels. No body or
weapon layer is clipped. The metal blade's lowest projected point is y=115 with
the ground pivot at y=116, so it remains above the floor.

## Integration and verification

Body atlas, separate sword atlas, forge portrait and blade geometry were promoted
together. Sword length remains 1.4x, hunter canvas/scale remain unchanged, and
runtime damage uses the same displayed strike cells. The 0.10.17 charge-release
fix and 0.10.16 recovery durations are retained.

Fifteen native Godot suites pass, covering blade contact/misses, silhouette gaps,
mirroring, one-hit deduplication, charge release, funded/unfunded combo routes,
recovery, selected boss parts and character proportions. The GIF preview now
samples at 25fps with minimum 40ms delays; it no longer writes zero-delay frames
that some viewers play too slowly. Normal/charge previews total 1.8/3.0 seconds,
including start/end holds and the charge hold.

The Android APK builds successfully. At installation time ADB returned an empty
device list, so installation and phone testing are pending reconnecting the
user's device. See `reference-skeleton-animation-0.10.18-verification.json`.
