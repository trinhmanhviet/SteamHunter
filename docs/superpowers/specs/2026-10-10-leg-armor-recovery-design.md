# Leg armor, stance and consistent recovery

User requested fixing leg armor/stance and inconsistent overhead recovery speeds.
Follow the supplied MonsterHunterWildsGreatSwordTu clip and its raise/overhead/
impact/recovery references. Limit changes to the existing rig and action timings;
do not invent additional moves, controllers or asset systems.
The loaded rig blends shin armor across foot/shin/thigh, while the extreme hip
drop and rear heel lift make the stance read as kneeling rather than bracing.
Rebind the lower leg with rigid shin/boot sections and narrow ankle/knee joints.
Use a balanced ready stance and a shallower committed crouch, preserving the
approved arms and 1.4x sword; adjust grip height/angle to retain floor contact.

All GS actions currently shown with the overhead set will use one post-hit timing:
contact 1/30 s, settle .22 s, recover .48 s (total .733333 s). Combo buffering opens
late in recovery and does not skip it. Keep the active blade contact timing and
per-target hit deduplication. Shoulder Brace keeps its separate body-action timing.

Test segment bindings and equal recovery frame progression across actions. Review
key poses before the full render, then verify collision regressions and Android
gameplay. Build/install/release 0.10.16 with the user's existing files preserved.
