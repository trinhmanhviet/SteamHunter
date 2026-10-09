# Reference-driven overhead cleaver demo

User approved the reference timing and requested autonomous implementation, testing,
Android installation and refinement overnight. No further design approval is needed.

## Scope
Build a separate playable 2D Godot training demo using the cleaned Hunyuan hunter.
Render original body and weapon as separate sprites. Use the supplied clip as pose
and timing reference, never as shipped artwork. Leave the main game's combat intact.

The uncharged swing takes approximately 2 seconds: raise .20 s, downswing .10 s,
follow-through 1.10 s, recovery .60 s. Holding input extends the overhead pose with
a small breathing/girding loop; release starts the same fast downswing. Early
release completes raising first. Motion includes a rear heel lift, a forward foot
brace, hip rotation, shoulder counter-rotation, deeper impact crouch and delayed
recovery. Ground and camera remain fixed; never independently normalize frames.

## Interaction
Landscape fullscreen. A large right-hand touch area opens a floating attack stick.
Touch/hold charges; release cuts. Space/mouse are desktop equivalents. One small
automatic demonstration toggle and reset button are anchored to the viewport.
A stationary practice target receives one hit per attack, only at impact, with a
larger damage number after charging. This is an animation study, not a new combo set.

## Verification
Native Godot tests cover indefinite hold, early release, repeated input lockout,
frame-rate independent progression, one-hit-only impact and recovery completion.
Inspect rendered key poses and actual Android screenshots. Package Android and
Windows demos, install Android via ADB, and publish a GitHub prerelease per the
user's standing instruction that builds get releases. Record actual limitations.
