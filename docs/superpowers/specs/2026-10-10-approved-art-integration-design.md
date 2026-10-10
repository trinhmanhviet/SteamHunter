# Promote approved hunter art and remove replaced assets

The user approved the overhead demo and requested removing old art and using the
new set. This authorizes promotion into the main game and deletion of replaced
character/Great Cleaver images, including their generated import sidecars.

Use the approved 74-frame Hunyuan body and separate weapon atlases in `art/`.
A focused visual selector maps the main hunter's action/charge state to those
frames; both layers share scale, ground pivot and mirroring. Preserve combat
routes and hitboxes. Basic draw/charged overhead attacks retain the approved
demo's weight and timing (2 s normal, 1.8 s after releasing held charge), with
hit events aligned to the rendered ground-contact pose. Other attacks use the
new frames adapted to their current hit timing pending their own authored clips.

Replace the forge's Great Cleaver preview with the approved character/weapon.
Other weapon art remains until an approved replacement exists. Remove the old
Great Cleaver 2D factory body folder, old stand-alone blade skins/pose sheets,
and rejected Great Cleaver source images. Keep original master references and
the Hunyuan/Blender generation inputs needed to regenerate the approved set.
Historical docs and generic factory tools may remain, clearly marked obsolete.

Verify ground anchoring, flips, charge, impact pose, body size and forge preview
with native Godot tests. Exercise affected combat routes and actual gameplay
on Android. Build, install and publish v0.10.14 as requested in standing build
instructions. Avoid committing or deleting the user's untracked clip tooling.
