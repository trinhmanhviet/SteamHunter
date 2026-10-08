"""Anatomy and protected skin regions for the approved Hunyuan hunter mesh."""

import numpy as np
from itertools import product


def nearby_seeds(points, seeds, radius):
    """Find adjacent cloth vertices with a small spatial grid, usable in bundled Blender Python."""
    cells = {}
    for point in points[seeds]:
        key = tuple(np.floor(point / radius).astype(int))
        cells.setdefault(key, []).append(point)
    cells = {key: np.array(value) for key, value in cells.items()}
    offsets = tuple(product((-1, 0, 1), repeat=3))
    result = np.zeros(len(points), dtype=bool)
    for index, point in enumerate(points):
        base = np.floor(point / radius).astype(int)
        for offset in offsets:
            candidates = cells.get(tuple(base + offset))
            if candidates is not None and np.any(np.sum((candidates - point) ** 2, axis=1) < radius * radius):
                result[index] = True
                break
    return result

LANDMARKS = {
    "hips": ((0, 0, .49), (0, 0, .57), None),
    "spine": ((0, 0, .57), (0, 0, .75), "hips"),
    "neck": ((0, 0, .75), (0, 0, .835), "spine"),
    "head": ((0, 0, .835), (0, 0, .98), "neck"),
}
for suffix, sign in (("R", -1), ("L", 1)):
    LANDMARKS.update({
        f"upper_arm.{suffix}": ((sign * .16, .015, .760), (sign * .215, -.03, .605), "spine"),
        f"forearm.{suffix}": ((sign * .215, -.03, .605), (sign * .25, -.065, .455), f"upper_arm.{suffix}"),
        f"hand.{suffix}": ((sign * .25, -.065, .455), (sign * .25, -.075, .405), f"forearm.{suffix}"),
        f"thigh.{suffix}": ((sign * .075, 0, .49), (sign * .10, 0, .275), "hips"),
        f"shin.{suffix}": ((sign * .10, 0, .275), (sign * .12, 0, .075), f"thigh.{suffix}"),
        f"foot.{suffix}": ((sign * .12, 0, .075), (sign * .12, -.065, .025), f"shin.{suffix}"),
    })


def compute_weights(points, colours=None):
    """Return normalized weights from rest-world coordinates divided by actor height."""
    points = np.asarray(points, dtype=float)
    if points.ndim != 2 or points.shape[1] != 3:
        raise ValueError("points must be N x 3")
    names = list(LANDMARKS)
    distances = []
    for head, tail, _parent in LANDMARKS.values():
        start, end = np.array(head), np.array(tail)
        segment = end - start
        t = np.clip(((points - start) @ segment) / (segment @ segment), 0, 1)
        distances.append(np.sum((points - (start + t[:, None] * segment)) ** 2, axis=1))
    distances = np.stack(distances, axis=1)
    # Legs and arms must not borrow weights from the opposite side across the camera depth.
    for index, name in enumerate(names):
        if name.endswith(".L"):
            distances[points[:, 0] < -.025, index] = 1e6
        elif name.endswith(".R"):
            distances[points[:, 0] > .025, index] = 1e6
    arm_boundary = .16 + np.clip((.60 - points[:, 2]) / .20, 0, 1) * .045
    arms = (np.abs(points[:, 0]) > arm_boundary) & (points[:, 2] > .46) & (points[:, 2] < .80)
    hands = (np.abs(points[:, 0]) > .195) & (points[:, 2] < .485) & (points[:, 2] > .345)
    for suffix, sign in (("R", -1), ("L", 1)):
        side = points[:, 0] * sign > 0
        allowed = {f"upper_arm.{suffix}", f"forearm.{suffix}", f"hand.{suffix}"}
        for index, name in enumerate(names):
            if name not in allowed:
                distances[(arms | hands) & side, index] = 1e6
    nearest = np.argsort(distances, axis=1)[:, :3]
    weights = np.zeros_like(distances)
    selected_distances = np.take_along_axis(distances, nearest, axis=1)
    inverse = 1 / np.maximum(selected_distances, .0004) ** 2
    np.put_along_axis(weights, nearest, inverse / inverse.sum(axis=1, keepdims=True), axis=1)

    def rigid(mask, name):
        weights[mask] = 0
        weights[mask, names.index(name)] = 1

    coat = np.zeros(len(points), dtype=bool)
    if colours is not None:
        colours = np.asarray(colours, dtype=float)
        maximum, minimum = colours.max(axis=1), colours.min(axis=1)
        saturation = (maximum - minimum) / np.maximum(maximum, 1e-8)
        red_hue = (colours[:, 1] - colours[:, 2]) / np.maximum(maximum - minimum, 1e-8) / 6
        red = (colours[:, 0] == maximum) & (maximum > .3) & (saturation > .6) & (red_hue < .045) & (red_hue >= 0)
        boundary = .17 + np.clip((.60 - points[:, 2]) / .20, 0, 1) * .045
        metal = (colours[:, 2] > colours[:, 0] * 1.1) & (maximum > .30)
        panel = (points[:, 2] > .32) & (points[:, 2] < .60) & (np.abs(points[:, 0]) <= boundary) & ~metal & ~arms & ~hands
        seeds = red & panel
        if np.any(seeds):
            # Include trim/outline vertices near the red cloth, even across a UV seam.
            coat[panel] = nearby_seeds(points[panel], seeds[panel], .015)
        # The coat is an outer shell around the legs; its dark outline/trim must
        # follow the same transform as its red panels, independent of UV colour.
        shell = (points[:, 2] > .325) & (points[:, 2] < .595) & (
            (np.abs(points[:, 0]) > .135) | (points[:, 1] < -.065) | (points[:, 1] > .075))
        coat |= shell & ~arms & ~hands
    # Hard boot/face/palm bindings prevent sliding soles and rubbery facial features.
    rigid(points[:, 2] >= .855, "head")
    for suffix, sign in (("R", -1), ("L", 1)):
        side = points[:, 0] * sign > 0
        rigid(side & (points[:, 2] < .13), f"foot.{suffix}")
        rigid(side & hands, f"hand.{suffix}")
    rigid(coat, "hips")
    return names, weights
