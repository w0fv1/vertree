#!/usr/bin/env python3
from __future__ import annotations

from pathlib import Path

from PIL import Image
from PIL import ImageDraw


# ---- Configuration ---------------------------------------------------------

# App icon (launcher / Dock source) configuration.
APP_ICON_SIZE = 1024
APP_ICON_SCALE = 0.722  # content scale relative to canvas size
APP_ICON_BG_COLOR = "#FFFFFF"
APP_ICON_BG_INSET_RATIO = 0.10
APP_ICON_BG_RADIUS_RATIO = 0.223

# Tray / menu bar icon configuration.
TRAY_ICON_SIZE = 32
TRAY_TEMPLATE_SCALE = 0.62  # plain glyph used as template icon
TRAY_GLYPH_SCALE = 0.52  # glyph used for filled-circle menu bar icon
TRAY_GLYPH_OFFSET_X = 1  # small optical centering tweak on macOS
TRAY_BG_INSET = 2
TRAY_BG_COLOR = "#FFFFFF"
TRAY_DILATE_RADIUS = 1  # thicken thin strokes slightly


def _load_cropped_logo(path: Path) -> Image.Image:
    logo = Image.open(path).convert("RGBA")
    alpha = logo.split()[-1]
    bbox = alpha.getbbox()
    if not bbox:
        raise SystemExit(f"logo has no alpha bbox: {path}")
    return logo.crop(bbox)


def _composite_on_canvas(
    cropped: Image.Image,
    size: int,
    content_scale: float,
    *,
    monochrome: bool,
    offset_x: int = 0,
    offset_y: int = 0,
) -> Image.Image:
    canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))

    target = int(round(size * content_scale))
    source_w, source_h = cropped.size
    scale = min(target / source_w, target / source_h)
    new_w = max(1, int(round(source_w * scale)))
    new_h = max(1, int(round(source_h * scale)))
    resized = cropped.resize((new_w, new_h), Image.Resampling.LANCZOS)

    if monochrome:
        mask = resized.split()[-1]
        black = Image.new("RGBA", resized.size, (0, 0, 0, 255))
        black.putalpha(mask)
        resized = black

    x = (size - new_w) // 2
    y = (size - new_h) // 2
    canvas.paste(resized, (x + offset_x, y + offset_y), resized)
    return canvas


def _parse_hex_color(value: str) -> tuple[int, int, int, int]:
    value = value.strip().lstrip("#")
    if len(value) == 6:
        r, g, b = int(value[0:2], 16), int(value[2:4], 16), int(value[4:6], 16)
        return r, g, b, 255
    if len(value) == 8:
        r, g, b, a = (
            int(value[0:2], 16),
            int(value[2:4], 16),
            int(value[4:6], 16),
            int(value[6:8], 16),
        )
        return r, g, b, a
    raise ValueError(f"Unsupported color: {value!r}")


def _add_solid_background(image: Image.Image, rgba: tuple[int, int, int, int]) -> Image.Image:
    if image.mode != "RGBA":
        image = image.convert("RGBA")
    bg = Image.new("RGBA", image.size, rgba)
    bg.alpha_composite(image)
    return bg


def _add_rounded_rect_bg_underlay(
    image: Image.Image,
    *,
    inset: int,
    radius: int,
    fill: tuple[int, int, int, int],
) -> Image.Image:
    if image.mode != "RGBA":
        image = image.convert("RGBA")
    canvas = Image.new("RGBA", image.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(canvas)
    w, h = canvas.size
    rect = (inset, inset, w - inset, h - inset)
    draw.rounded_rectangle(rect, radius=radius, fill=fill)
    canvas.alpha_composite(image)
    return canvas


def _add_rounded_rect_background(
    image: Image.Image,
    *,
    rect_inset: int,
    radius: int,
    fill: tuple[int, int, int, int],
) -> Image.Image:
    if image.mode != "RGBA":
        image = image.convert("RGBA")
    canvas = image.copy()
    draw = ImageDraw.Draw(canvas)
    w, h = canvas.size
    rect = (rect_inset, rect_inset, w - rect_inset, h - rect_inset)
    draw.rounded_rectangle(rect, radius=radius, fill=fill)
    canvas.alpha_composite(image)
    return canvas


def _add_circle_bg_underlay(
    image: Image.Image,
    *,
    inset: int,
    fill: tuple[int, int, int, int],
) -> Image.Image:
    if image.mode != "RGBA":
        image = image.convert("RGBA")
    canvas = Image.new("RGBA", image.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(canvas)
    w, h = canvas.size
    rect = (inset, inset, w - inset, h - inset)
    draw.ellipse(rect, fill=fill)
    canvas.alpha_composite(image)
    return canvas


def _dilate_alpha(image: Image.Image, *, radius: int) -> Image.Image:
    """
    Very small alpha dilation (no SciPy): thickens thin shapes by expanding alpha.
    """
    if radius <= 0:
        return image
    if image.mode != "RGBA":
        image = image.convert("RGBA")

    r, g, b, a = image.split()
    src = a.load()
    w, h = a.size
    out_a = Image.new("L", (w, h), 0)
    dst = out_a.load()

    for y in range(h):
        for x in range(w):
            m = 0
            for dy in range(-radius, radius + 1):
                yy = y + dy
                if yy < 0 or yy >= h:
                    continue
                for dx in range(-radius, radius + 1):
                    xx = x + dx
                    if xx < 0 or xx >= w:
                        continue
                    v = src[xx, yy]
                    if v > m:
                        m = v
                        if m == 255:
                            break
                if m == 255:
                    break
            dst[x, y] = m

    return Image.merge("RGBA", (r, g, b, out_a))


def _punch_out_alpha(base: Image.Image, mask: Image.Image) -> Image.Image:
    """
    Make base transparent where mask is opaque (mask uses its alpha channel).
    """
    if base.mode != "RGBA":
        base = base.convert("RGBA")
    if mask.mode != "RGBA":
        mask = mask.convert("RGBA")

    base_r, base_g, base_b, base_a = base.split()
    m = mask.split()[-1]  # alpha

    base_a_l = base_a.load()
    m_l = m.load()
    w, h = base.size
    for y in range(h):
        for x in range(w):
            a = base_a_l[x, y]
            cut = m_l[x, y]
            if cut:
                base_a_l[x, y] = max(0, a - cut)

    out = Image.merge("RGBA", (base_r, base_g, base_b, base_a))
    return out


def main() -> None:
    repo_root = Path(__file__).resolve().parents[1]
    logo_path = repo_root / "assets/img/logo/logo.png"
    app_icon_path = repo_root / "assets/icon/app_icon.png"
    dock_imageset_dir = repo_root / "macos/Runner/Assets.xcassets/DockIcon.imageset"
    tray_template_path = repo_root / "assets/img/logo/tray_template.png"
    tray_colored_path = repo_root / "assets/img/logo/tray_colored.png"

    cropped = _load_cropped_logo(logo_path)

    # The launcher icon is now generated by `flutter_launcher_icons`.
    # This script only produces the canonical 1024x1024 source image (with padding/background),
    # plus tray and runtime Dock refresh assets.
    size = APP_ICON_SIZE
    out = _composite_on_canvas(cropped, size, APP_ICON_SCALE, monochrome=False)
    # Dock icon background: macOS-style rounded-rect app icon with a white plate.
    app_icon_bg = _parse_hex_color(APP_ICON_BG_COLOR)
    bg_inset = max(1, int(round(size * APP_ICON_BG_INSET_RATIO)))
    bg_size = size - 2 * bg_inset
    radius = max(1, int(round(bg_size * APP_ICON_BG_RADIUS_RATIO)))
    out = _add_rounded_rect_bg_underlay(
        out,
        inset=bg_inset,
        radius=radius,
        fill=app_icon_bg,
    )
    app_icon_path.parent.mkdir(parents=True, exist_ok=True)
    out.save(app_icon_path)

    # Provide a named image set for runtime Dock icon refresh (NSImage(named:)).
    dock_imageset_dir.mkdir(parents=True, exist_ok=True)
    dock_png = dock_imageset_dir / "dock_icon_1024.png"
    Image.open(app_icon_path).save(dock_png)

    tray_template = _composite_on_canvas(
        cropped,
        TRAY_ICON_SIZE,
        TRAY_TEMPLATE_SCALE,
        monochrome=True,
    )
    tray_template_path.parent.mkdir(parents=True, exist_ok=True)
    tray_template.save(tray_template_path)

    # Menu bar icon: white circle background with a transparent (cut-out) glyph.
    # Keep glyph a bit smaller than Dock so it looks balanced in the menu bar.
    tray_glyph_mask = _composite_on_canvas(
        cropped,
        TRAY_ICON_SIZE,
        TRAY_GLYPH_SCALE,
        monochrome=True,
        offset_x=TRAY_GLYPH_OFFSET_X,  # nudge right to better optical centering in the menu bar
    )
    tray_glyph_mask = _dilate_alpha(tray_glyph_mask, radius=TRAY_DILATE_RADIUS)
    tray_bg = Image.new("RGBA", (TRAY_ICON_SIZE, TRAY_ICON_SIZE), (0, 0, 0, 0))
    tray_bg = _add_circle_bg_underlay(
        tray_bg,
        inset=TRAY_BG_INSET,
        fill=_parse_hex_color(TRAY_BG_COLOR),
    )
    tray_glyph = _punch_out_alpha(tray_bg, tray_glyph_mask)
    tray_colored_path.parent.mkdir(parents=True, exist_ok=True)
    tray_glyph.save(tray_colored_path)

    print("Generated:")
    print(f"- {app_icon_path}")
    print(f"- {dock_imageset_dir}")
    print(f"- {tray_template_path}")
    print(f"- {tray_colored_path}")


if __name__ == "__main__":
    main()
