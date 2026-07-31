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


def _remove_outer_frame(icon: Image.Image) -> Image.Image:
    """Crop the baked rounded tile so the launcher applies its only mask."""
    inset = round(min(icon.size) * FRAME_CROP_RATIO)
    cropped = icon.crop((inset, inset, icon.width - inset, icon.height - inset))
    return cropped.resize(icon.size, Image.Resampling.LANCZOS)


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
    for target in resources.rglob("*.png"):
        icon_name = ANDROID_NAMES.get(target.name)
        if icon_name is None or icon_name not in icons:
            continue
        with Image.open(target) as existing:
            size = existing.size
        icons[icon_name].resize(size, Image.Resampling.LANCZOS).save(target)


def _replace_ios_icons(root: Path, icons: dict[str, Image.Image]) -> None:
    assets = root / "ios" / "Runner" / "Assets.xcassets"
    for set_name, icon_name in IOS_SETS.items():
        if icon_name not in icons:
            continue
        icon_set = assets / set_name
        contents = json.loads((icon_set / "Contents.json").read_text())
        for entry in contents["images"]:
            filename = entry.get("filename")
            if not filename:
                continue
            target = icon_set / filename
            points = float(entry["size"].split("x", maxsplit=1)[0])
            scale = int(entry["scale"].removesuffix("x"))
            pixels = round(points * scale)
            icons[icon_name].resize(
                (pixels, pixels),
                Image.Resampling.LANCZOS,
            ).save(target)


def regenerate(root: Path, generated: Path) -> None:
    destination = root / "assets" / "icons"
    icons: dict[str, Image.Image] = {}
    for name in ICON_NAMES:
        source = generated / f"subberry_{name}_new.png"
        icon = _remove_outer_frame(Image.open(source).convert("RGB"))
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
