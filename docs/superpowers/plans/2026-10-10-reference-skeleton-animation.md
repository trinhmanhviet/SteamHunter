# Apply approved reference skeletons

> Execute inline using the existing Blender render pipeline. User approved the
> twelve frame sketches and asked to try them in the game; no additional approval
> is required. Preserve their clip tool and video files.

**Goal:** Give the Great Cleaver a braced charge and committed overhead cut using
the approved reference poses.

**Approach:** Read `prototypes/reference_skeleton/poses.json` for blade direction
and trunk lean. Retarget the twelve perspective sketches through a small table of
existing grip/hip/foot controls in `tools/render_overhead_demo.py`. Anatomical bone
lengths, separate sword skin, solid greaves and grounded soles remain constraints.
The three downswing cells use source frames 30/31/32. Recovery closes into a
shouldered ready pose; the clip changes camera after frame 84, so that closing
transition is a game adaptation. No new animation framework or runtime combat
feature is introduced.

Follow-up correction: charge freezes at source frame 26 with the sword behind
the head. Cells 6..8 (sources 28/29 and the transition into them) are a separate
release stage, played only after letting go; charged contact is at 5/30s.

- [x] Author the control table and render key poses into `build/reference-retarget-keys`.
- [x] Inspect grip reach, knees, feet, sword/floor clearance and compare old/new charge.
- [x] Render/promote corrected rear hold and release stage; show previews.
- [x] Verify rear-hold regression, blade contacts, charge release and combo timing.
- [x] Build the final Android 0.10.18 after the correction.
- [x] Install/test on Android; device reconnected, Great Cleaver equipped, hash verified.
- [x] Push and publish the APK, animation preview and Android gameplay release.

Verified release: https://github.com/trinhmanhviet/SteamHunter/releases/tag/v0.10.18
Final source commit: d9346f3090ce6d7bbb775c31e06af8d233e9efc2.

Commands: use the project's isolated Blender and Python, then Godot native tests.
Key render: `.tools/blender/blender-4.5.4-windows-x64/blender.exe -b prototypes/hunyuan_hunter/heavy_motion/hunter_heavy_rig.blend --python tools/render_overhead_demo.py -- build/reference-retarget-keys --keys`.
Full render uses `prototypes/hunyuan_hunter/overhead_motion` as output, followed by
`tools/pack_overhead_demo.py` and `tools/promote_hunter_art.py`.
Native suites: great_cleaver_art, blade_sweep, blade_contact_flow,
great_cleaver_hitboxes, blade_charge_release, blade_gesture_flow, weapon_actions,
weapon_flow, cleaver_recovery, part_targeting, character_proportions and game_loop.
On Android test stationary holds of several lengths and an actual blade contact;
verify the installed APK hash against the released artifact.
