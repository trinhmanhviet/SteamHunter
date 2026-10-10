"""Promote the approved layered overhead render into production game assets."""
import json
import shutil
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]


def main():
    approved = ROOT / "prototypes/overhead_demo/assets"
    body_dir = ROOT / "art/characters/hunter"
    weapon_dir = ROOT / "art/weapons/great_cleaver"
    body_dir.mkdir(parents=True, exist_ok=True)
    weapon_dir.mkdir(parents=True, exist_ok=True)
    shutil.copy2(approved / "body.png", body_dir / "body_atlas.png")
    shutil.copy2(approved / "weapon.png", weapon_dir / "overhead_atlas.png")
    manifest = json.loads((approved / "frames.json").read_text())
    manifest["source"] = "Approved reference skeleton retarget; braced charge and committed overhead cut (0.10.18)"
    manifest["body_texture"] = "res://art/characters/hunter/body_atlas.png"
    manifest["weapon_texture"] = "res://art/weapons/great_cleaver/overhead_atlas.png"
    (body_dir / "overhead_frames.json").write_text(json.dumps(manifest, indent=2), encoding="utf-8")
    frame = manifest["frames"][0]
    merged = Image.new("RGBA", (384, 384))
    for layer, offset in (("body", (128, 128)), ("weapon", (0, 0))):
        atlas = Image.open(approved / (layer + ".png")).convert("RGBA")
        x, y, w, h = frame[layer]
        merged.alpha_composite(atlas.crop((x, y, x + w, y + h)), offset)
    merged.crop(merged.getbbox()).save(body_dir / "great_cleaver_portrait.png")
    print("Promoted approved body, weapon, frame manifest and forge portrait.")


if __name__ == "__main__":
    main()
