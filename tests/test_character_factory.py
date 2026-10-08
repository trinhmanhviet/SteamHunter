import json
import shutil
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from PIL import Image

from tools.character_factory import extract_palette, load_definition, normalize_frame, pack_sheet, qa_frame, visible_bbox, write_godot_spriteframes


class CharacterFactoryDefinitionTests(unittest.TestCase):
    def test_load_definition_rejects_missing_ground_line(self):
        directory = Path(__file__).resolve().parents[1] / ".test-tmp-character-factory"
        shutil.rmtree(directory, ignore_errors=True)
        directory.mkdir()
        try:
            path = directory / "character.json"
            path.write_text(json.dumps({"character": "Hunter01", "sprite_size": [128, 128]}), encoding="utf-8")

            with self.assertRaisesRegex(ValueError, "ground_y"):
                load_definition(path)
        finally:
            shutil.rmtree(directory, ignore_errors=True)

    def test_normalize_frame_aligns_feet_and_uses_locked_palette(self):
        source = Image.new("RGBA", (80, 100), (0, 0, 0, 0))
        colors = [(230, 80, 60, 255), (120, 180, 230, 255), (245, 220, 160, 255), (35, 55, 85, 255)]
        for y in range(15, 75):
            for x in range(20, 60):
                source.putpixel((x, y), colors[(x + y) % len(colors)])

        result = normalize_frame(
            source,
            canvas=(128, 128),
            target_height=104,
            ground_y=116,
            palette=[(230, 80, 60), (120, 180, 230)],
        )

        bbox = visible_bbox(result)
        self.assertEqual(bbox[3], 117)
        self.assertEqual(bbox[3] - bbox[1], 104)
        self.assertLessEqual(len(result.getcolors(maxcolors=4)), 3)

    def test_qa_frame_rejects_a_figure_touching_the_canvas_border(self):
        frame = Image.new("RGBA", (128, 128), (0, 0, 0, 0))
        for y in range(12, 116):
            frame.putpixel((0, y), (230, 80, 60, 255))

        errors = qa_frame(frame, target_height=104, ground_y=116, palette_colors=32)

        self.assertIn("alpha touches canvas border", errors)

    def test_qa_frame_accepts_a_normalized_compliant_frame(self):
        source = Image.new("RGBA", (80, 100), (0, 0, 0, 0))
        for y in range(15, 75):
            for x in range(20, 60):
                source.putpixel((x, y), (210, 77, 57, 255))
        normalized = normalize_frame(source, canvas=(128, 128), target_height=104, ground_y=116, palette=[(210, 77, 57)])

        errors = qa_frame(normalized, target_height=104, ground_y=116, palette_colors=32)

        self.assertEqual(errors, [])

    def test_pack_sheet_writes_ordered_regions_and_metadata(self):
        directory = Path(__file__).resolve().parents[1] / ".test-tmp-character-factory"
        shutil.rmtree(directory, ignore_errors=True)
        directory.mkdir()
        try:
            animations = {}
            for index, name in enumerate(("idle", "charge", "heavy_strike", "recovery")):
                frame_path = directory / f"{name}.png"
                Image.new("RGBA", (128, 128), (index * 40, 80, 160, 255)).save(frame_path)
                animations[name] = [frame_path]

            sheet_path, metadata_path = pack_sheet(
                animations,
                directory,
                "hunter01",
                pivot=(64, 116),
                ground_y=116,
                attachment_points={"right_hand": {"idle/00": {"position": [72, 70], "rotation": 0.2}}},
            )
            metadata = json.loads(metadata_path.read_text(encoding="utf-8"))

            with Image.open(sheet_path) as sheet:
                self.assertEqual(sheet.size, (512, 128))
            self.assertEqual(metadata["animations"]["charge"]["frames"][0]["x"], 128)
            self.assertEqual(metadata["pivot"], [64, 116])
            self.assertEqual(metadata["attachment_points"]["right_hand"]["idle/00"]["position"], [72, 70])
        finally:
            shutil.rmtree(directory, ignore_errors=True)

    def test_extract_palette_keeps_most_common_visible_colors(self):
        image = Image.new("RGBA", (8, 1), (0, 0, 0, 0))
        for x in range(5):
            image.putpixel((x, 0), (230, 80, 60, 255))
        for x in range(5, 7):
            image.putpixel((x, 0), (120, 180, 230, 255))
        image.putpixel((7, 0), (245, 220, 160, 255))

        palette = extract_palette(image, 2)

        self.assertEqual(palette, [(230, 80, 60), (120, 180, 230)])

    def test_extract_palette_ignores_nearly_transparent_edge_colors(self):
        image = Image.new("RGBA", (9, 1), (0, 0, 40, 1))
        for x in range(6):
            image.putpixel((x, 0), (210, 77, 57, 255))
        for x in range(6, 8):
            image.putpixel((x, 0), (112, 172, 222, 255))

        palette = extract_palette(image, 3)

        self.assertNotIn((0, 0, 40), palette)
        self.assertIn((210, 77, 57), palette)

    def test_extract_palette_groups_near_identical_outline_shades(self):
        image = Image.new("RGBA", (177, 1), (0, 0, 0, 0))
        cursor = 0
        for shade in range(16):
            for _ in range(10):
                image.putpixel((cursor, 0), (0, 0, 32 + shade, 255))
                cursor += 1
        for _ in range(9):
            image.putpixel((cursor, 0), (210, 77, 57, 255))
            cursor += 1
        for _ in range(8):
            image.putpixel((cursor, 0), (112, 172, 222, 255))
            cursor += 1

        palette = extract_palette(image, 3)

        self.assertTrue(any(red > 180 and green < 100 for red, green, _ in palette))
        self.assertTrue(any(blue > 180 and green > 120 for _, green, blue in palette))

    def test_write_godot_spriteframes_exports_animation_regions(self):
        directory = Path(__file__).resolve().parents[1] / ".test-tmp-character-factory"
        shutil.rmtree(directory, ignore_errors=True)
        directory.mkdir()
        try:
            metadata_path = directory / "animations.json"
            metadata_path.write_text(json.dumps({
                "frame_size": [128, 128],
                "animations": {
                    "idle": {"frames": [{"x": 0, "y": 0, "w": 128, "h": 128}]},
                    "charge": {"frames": [{"x": 128, "y": 0, "w": 128, "h": 128, "duration": 0.4}]},
                },
            }), encoding="utf-8")

            tres_path = write_godot_spriteframes(metadata_path, "res://art/characters/hunter/sprites/hunter_spritesheet.png", directory / "hunter.tres", fps=6)
            content = tres_path.read_text(encoding="utf-8")

            self.assertIn('type="SpriteFrames"', content)
            self.assertIn('name": &"charge"', content)
            self.assertIn("region = Rect2(128, 0, 128, 128)", content)
            self.assertIn('"duration": 0.4', content)
        finally:
            shutil.rmtree(directory, ignore_errors=True)


if __name__ == "__main__":
    unittest.main()
