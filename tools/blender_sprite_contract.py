"""Camera and timing math shared by Blender rendering and offline packaging."""

import math


def ortho_framing(rest_height: float, target_height: int = 104, ground_y: int = 116, canvas=(128, 128)):
    if rest_height <= 0 or target_height <= 0 or target_height >= canvas[1] or not 0 < ground_y < canvas[1]:
        raise ValueError("invalid rest height or sprite framing")
    scale = rest_height * canvas[1] / target_height
    center_z = (ground_y / canvas[1] - 0.5) * scale
    return scale, center_z


def project_ndc(point, canvas=(128, 128)) -> tuple[int, int]:
    """Convert camera NDC to image coordinates; preserve offscreen coordinates."""
    return round(point[0] * canvas[0]), round((1 - point[1]) * canvas[1])


def sample_frames(start: int, end: int, source_fps: float, target_fps: float) -> list[int]:
    if end < start or source_fps <= 0 or not 0 < target_fps <= source_fps:
        raise ValueError("invalid frame range or FPS")
    duration = (end - start + 1) / source_fps
    count = math.ceil(duration * target_fps - 1e-9)
    return [start + round(index * source_fps / target_fps) for index in range(count)]


def srgb_to_linear(component: float) -> float:
    return component / 12.92 if component <= 0.04045 else ((component + 0.055) / 1.055) ** 2.4
