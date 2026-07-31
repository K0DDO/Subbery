from __future__ import annotations

import argparse
import json
from pathlib import Path

import numpy as np
from PIL import Image, ImageFilter


ICON_NAMES = (
    "dark_glass",
    "dark_minimal",
    "dark_neon",
    "light_glass",
    "light_minimal",
    "light_neon",
)

FRAME_CROP_RATIO = 0.055

# Adaptive icons only keep the inner ~66% of the foreground, so the default icon
# needs far more breathing room than the masked legacy and iOS rasters.
ADAPTIVE_SCALE = 0.52
LEGACY_SCALE = 0.80
IOS_SCALE = 0.88

ICON_PLATES = {
    "dark_glass": ((0x18, 0x07, 0x0E), (0x35, 0x08, 0x16), False),
    "dark_minimal": ((0x11, 0x06, 0x09), (0x25, 0x09, 0x10), False),
    "dark_neon": ((0x14, 0x01, 0x05), (0x2B, 0x03, 0x0B), False),
    "light_glass": ((0xFC, 0xB7, 0x9D), (0xFF, 0xD0, 0xBE), True),
    "light_minimal": ((0xFD, 0xDC, 0xCF), (0xFF, 0xEE, 0xE5), True),
    "light_neon": ((0xFC, 0xCD, 0xB9), (0xFF, 0xE1, 0xD3), True),
}

IOS_SETS = {
    "AppIcon.appiconset": "dark_glass",
    "DarkMinimal.appiconset": "dark_minimal",
    "DarkNeon.appiconset": "dark_neon",
    "LightGlass.appiconset": "light_glass",
    "LightMinimal.appiconset": "light_minimal",
    "LightNeon.appiconset": "light_neon",
}

ANDROID_NAMES = {
    "ic_launcher.png": "dark_glass",
    "ic_launcher_dark_minimal.png": "dark_minimal",
    "ic_launcher_dark_neon.png": "dark_neon",
    "ic_launcher_light_glass.png": "light_glass",
    "ic_launcher_light_minimal.png": "light_minimal",
    "ic_launcher_light_neon.png": "light_neon",
    "ic_launcher_foreground.png": "dark_glass",
}

ADAPTIVE_NAMES = frozenset({"ic_launcher.png", "ic_launcher_foreground.png"})


def _remove_outer_frame(icon: Image.Image) -> Image.Image:
    """Crop the baked rounded tile so the launcher applies its only mask."""
    inset = round(min(icon.size) * FRAME_CROP_RATIO)
    cropped = icon.crop((inset, inset, icon.width - inset, icon.height - inset))
    return cropped.resize(icon.size, Image.Resampling.LANCZOS)


def _logo_on_clean_plate(
    icon: Image.Image,
    base_color: tuple[int, int, int],
    center_color: tuple[int, int, int],
    light: bool,
) -> Image.Image:
    """Keep the berry S and leaves, replacing the framed tile with a clean plate."""
    source = np.asarray(icon.convert("RGB"), dtype=np.int16)
    red = source[:, :, 0]
    green = source[:, :, 1]
    blue = source[:, :, 2]
    height, width = red.shape
    y, x = np.ogrid[:height, :width]

    # The decorative frame also contains bright red pixels. Restrict extraction
    # to the central logo ellipse so its corners and perimeter cannot enter mask.
    logo_region = (
        ((x - width * 0.5) / (width * 0.43)) ** 2
        + ((y - height * 0.5) / (height * 0.50)) ** 2
        <= 1
    )
    red_green_gap = 45 if light else 22
    red_blue_gap = 30 if light else 12
    berry_seed = (
        (red > 78)
        & (red - green > red_green_gap)
        & (red - blue > red_blue_gap)
        & logo_region
    )
    leaf_seed = (
        (green > 65)
        & (green - red > 8)
        & (green - blue > 18)
        & logo_region
    )
    mask = Image.fromarray(
        ((berry_seed | leaf_seed).astype(np.uint8) * 255),
        mode="L",
    )
    mask = mask.filter(ImageFilter.MaxFilter(45))
    mask = mask.filter(ImageFilter.GaussianBlur(9))

    base = np.array(base_color, dtype=np.float32)
    center = np.array(center_color, dtype=np.float32)
    distance = np.sqrt(
        ((x - width * 0.5) / (width * 0.72)) ** 2
        + ((y - height * 0.52) / (height * 0.72)) ** 2
    )
    glow = np.clip(1 - distance, 0, 1)[:, :, None]
    plate = Image.fromarray(
        np.clip(base + (center - base) * glow, 0, 255).astype(np.uint8),
        mode="RGB",
    ).convert("RGBA")

    logo = icon.convert("RGBA")
    logo.putalpha(mask)
    return Image.alpha_composite(plate, logo).convert("RGB")


def _plate_color(icon: Image.Image) -> tuple[int, int, int]:
    """Sample the artwork border so added padding stays invisible."""
    pixels = np.asarray(icon, dtype=np.uint8)
    band = round(min(icon.size) * 0.02) or 1
    edges = np.concatenate(
        (
            pixels[:band].reshape(-1, 3),
            pixels[-band:].reshape(-1, 3),
            pixels[:, :band].reshape(-1, 3),
            pixels[:, -band:].reshape(-1, 3),
        )
    )
    return tuple(int(value) for value in np.median(edges, axis=0))


def _padded(icon: Image.Image, scale: float) -> Image.Image:
    """Inset the artwork on its own plate color to survive launcher masks."""
    canvas = Image.new("RGB", icon.size, _plate_color(icon))
    inner = (round(icon.width * scale), round(icon.height * scale))
    canvas.paste(
        icon.resize(inner, Image.Resampling.LANCZOS),
        ((icon.width - inner[0]) // 2, (icon.height - inner[1]) // 2),
    )
    return canvas


def _wordmark_with_alpha(source: Image.Image) -> Image.Image:
    rgb = np.asarray(source.convert("RGB"), dtype=np.int16)
    maximum = rgb.max(axis=2)
    minimum = rgb.min(axis=2)
    saturation = maximum - minimum

    # Generated checkerboards are neutral and bright. Brand pixels are red/green.
    seed = ((saturation > 24) & (maximum > 65)).astype(np.uint8) * 255
    mask = Image.fromarray(seed, mode="L")
    mask = mask.filter(ImageFilter.MaxFilter(9))
    mask = mask.filter(ImageFilter.MinFilter(7))
    mask = mask.filter(ImageFilter.GaussianBlur(1.2))

    rgba = source.convert("RGBA")
    rgba.putalpha(mask)
    bounds = mask.getbbox()
    if bounds is None:
        raise ValueError("Generated wordmark contains no detectable foreground.")
    left, top, right, bottom = bounds
    padding = 24
    crop = (
        max(0, left - padding),
        max(0, top - padding),
        min(rgba.width, right + padding),
        min(rgba.height, bottom + padding),
    )
    return rgba.crop(crop)


def _replace_android_icons(root: Path, icons: dict[str, Image.Image]) -> None:
    resources = root / "android" / "app" / "src" / "main" / "res"
    variants = {
        name: {
            ADAPTIVE_SCALE: _padded(icon, ADAPTIVE_SCALE),
            LEGACY_SCALE: _padded(icon, LEGACY_SCALE),
        }
        for name, icon in icons.items()
    }
    for target in resources.rglob("*.png"):
        icon_name = ANDROID_NAMES.get(target.name)
        if icon_name is None or icon_name not in icons:
            continue
        scale = ADAPTIVE_SCALE if target.name in ADAPTIVE_NAMES else LEGACY_SCALE
        with Image.open(target) as existing:
            size = existing.size
        variants[icon_name][scale].resize(size, Image.Resampling.LANCZOS).save(target)


def _replace_ios_icons(root: Path, icons: dict[str, Image.Image]) -> None:
    assets = root / "ios" / "Runner" / "Assets.xcassets"
    for set_name, icon_name in IOS_SETS.items():
        if icon_name not in icons:
            continue
        icon_set = assets / set_name
        artwork = _padded(icons[icon_name], IOS_SCALE)
        contents = json.loads((icon_set / "Contents.json").read_text())
        for entry in contents["images"]:
            filename = entry.get("filename")
            if not filename:
                continue
            target = icon_set / filename
            points = float(entry["size"].split("x", maxsplit=1)[0])
            scale = int(entry["scale"].removesuffix("x"))
            pixels = round(points * scale)
            artwork.resize((pixels, pixels), Image.Resampling.LANCZOS).save(target)


def regenerate(root: Path, generated: Path) -> None:
    destination = root / "assets" / "icons"
    icons: dict[str, Image.Image] = {}
    for name in ICON_NAMES:
        source = generated / f"subberry_{name}_new.png"
        icon = _remove_outer_frame(Image.open(source).convert("RGB"))
        icon = _logo_on_clean_plate(icon, *ICON_PLATES[name])
        icons[name] = icon
        icon.save(destination / f"subberry_{name}.png")

    for theme in ("dark", "light"):
        source = Image.open(generated / f"subberry_wordmark_{theme}_new.png")
        wordmark = _wordmark_with_alpha(source)
        wordmark.save(destination / f"subberry_wordmark_{theme}.png")

    _replace_android_icons(root, icons)
    _replace_ios_icons(root, icons)


def regenerate_launcher(root: Path) -> None:
    """Rebuild launcher resources from the six committed borderless artworks."""
    destination = root / "assets" / "icons"
    icons = {
        name: Image.open(destination / f"subberry_{name}.png").convert("RGB")
        for name in ICON_NAMES
    }
    _replace_android_icons(root, icons)
    _replace_ios_icons(root, icons)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "generated",
        type=Path,
        nargs="?",
        help="Directory containing the generated *_new.png source images.",
    )
    parser.add_argument(
        "--launcher-only",
        action="store_true",
        help="Only sync launcher resources from the committed icon artworks.",
    )
    args = parser.parse_args()
    root = Path(__file__).resolve().parents[1]
    if args.launcher_only:
        regenerate_launcher(root)
        return
    if args.generated is None:
        parser.error("generated directory is required unless --launcher-only is used")
    regenerate(root, args.generated.resolve())


if __name__ == "__main__":
    main()
