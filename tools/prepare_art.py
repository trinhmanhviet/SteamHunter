"""Turn project-owned ImageGen source art into game-sized transparent assets."""

from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "art" / "source"
ART = ROOT / "art"


def background(source_name: str, output_name: str) -> Image.Image:
    image = Image.open(SOURCE / source_name).convert("RGB")
    width, height = image.size
    target_ratio = 16 / 9
    if width / height > target_ratio:
        crop_width = round(height * target_ratio)
        left = (width - crop_width) // 2
        image = image.crop((left, 0, left + crop_width, height))
    else:
        crop_height = round(width / target_ratio)
        top = (height - crop_height) // 2
        image = image.crop((0, top, width, top + crop_height))
    image = image.resize((960, 540), Image.Resampling.LANCZOS)
    image.save(ART / output_name, optimize=True)
    return image


def sprite(source_name: str, output_name: str, max_width: int, max_height: int) -> Image.Image:
    image = Image.open(SOURCE / source_name).convert("RGBA")
    alpha = image.getchannel("A")
    bbox = alpha.point(lambda n: 255 if n > 28 else 0).getbbox()
    if bbox is None:
        raise ValueError(f"No opaque content in {source_name}")
    image = image.crop(bbox)
    image.thumbnail((max_width, max_height), Image.Resampling.LANCZOS)
    edge = image.getchannel("A").point(lambda n: 255 if n >= 112 else 0)
    image.putalpha(edge)
    image.save(ART / output_name, optimize=True)
    return image


def preview(camp: Image.Image, hero: Image.Image, rat: Image.Image, boss: Image.Image, platform: Image.Image):
    image = camp.convert("RGBA")
    image.alpha_composite(platform, (304, 325))
    image.alpha_composite(hero, (241, 352))
    image.alpha_composite(rat, (430, 397))
    image.alpha_composite(boss, (586, 323))
    image.convert("RGB").save(ART / "art_preview.png", optimize=True)


def main() -> None:
    camp = background("camp_generated.png", "camp_back.png")
    background("moor_generated.png", "moor_back.png")
    hero = sprite("hunter_generated.png", "hunter.png", 132, 126)
    boss = sprite("cinderback_generated.png", "cinderback.png", 270, 145)
    rat = sprite("rat_generated.png", "mire_rat.png", 114, 66)
    platform = sprite("platform_generated.png", "platform.png", 330, 90)
    preview_hero = Image.open(ART / "characters/hunter/great_cleaver_portrait.png").convert("RGBA")
    preview(camp, preview_hero, rat, boss, platform)
    print("Prepared six ImageGen assets and a scene preview in", ART)


if __name__ == "__main__":
    main()
