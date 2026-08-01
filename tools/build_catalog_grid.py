from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

text = Path("lib/features/subscriptions/data/catalog/known_services.dart").read_text(
    encoding="utf-8"
)
services: list[tuple[str, str]] = []
name = logo = None
for line in text.splitlines():
    line = line.strip()
    if line.startswith("name:"):
        name = line.split("'", 2)[1]
    elif line.startswith("logoKey:"):
        logo = line.split("'", 2)[1]
        if name and logo:
            services.append((name, logo))
            name = logo = None

print("services", len(services))

cols = 8
cell_w, cell_h = 118, 124
pad = 28
gap = 14
rows = (len(services) + cols - 1) // cols
width = pad * 2 + cols * cell_w + (cols - 1) * gap
height = pad * 2 + 56 + rows * cell_h + (rows - 1) * gap

bg = Image.new("RGBA", (width, height), (36, 22, 24, 255))
draw = ImageDraw.Draw(bg, "RGBA")
for cx, cy, r, a in [
    (120, 80, 220, 40),
    (width - 160, 180, 260, 35),
    (width // 2, height - 100, 300, 28),
]:
    overlay = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    od = ImageDraw.Draw(overlay)
    od.ellipse((cx - r, cy - r, cx + r, cy + r), fill=(230, 127, 115, a))
    bg = Image.alpha_composite(bg, overlay)

dot = Image.new("RGBA", (18, 18), (0, 0, 0, 0))
dd = ImageDraw.Draw(dot)
dd.ellipse((3, 5, 15, 16), outline=(230, 127, 115, 70), width=1)
for y in range(20, height, 74):
    for x in range(18, width, 74):
        bg.paste(dot, (x + (20 if (y // 74) % 2 else 0), y), dot)

try:
    font = ImageFont.truetype("C:/Windows/Fonts/segoeui.ttf", 14)
    title_font = ImageFont.truetype("C:/Windows/Fonts/segoeuib.ttf", 28)
    small = ImageFont.truetype("C:/Windows/Fonts/segoeui.ttf", 12)
except OSError:
    font = ImageFont.load_default()
    title_font = font
    small = font

draw = ImageDraw.Draw(bg)
draw.text((pad, 18), "Каталог сервисов", font=title_font, fill=(255, 248, 245))
draw.text(
    (pad, 52),
    f"{len(services)} готовых подписок — и свои записи",
    font=small,
    fill=(186, 160, 155),
)

logo_dir = Path("assets/service_logos")
for i, (svc_name, logo_key) in enumerate(services):
    r, c = divmod(i, cols)
    x = pad + c * (cell_w + gap)
    y = pad + 70 + r * (cell_h + gap)
    card = Image.new("RGBA", (cell_w, cell_h), (0, 0, 0, 0))
    cd = ImageDraw.Draw(card)
    cd.rounded_rectangle(
        (0, 0, cell_w - 1, cell_h - 1), radius=22, fill=(255, 255, 255, 18)
    )
    cd.rounded_rectangle(
        (0, 0, cell_w - 1, cell_h - 1),
        radius=22,
        outline=(255, 255, 255, 38),
        width=1,
    )
    icon_box = 56
    ix, iy = (cell_w - icon_box) // 2, 14
    cd.rounded_rectangle(
        (ix, iy, ix + icon_box, iy + icon_box),
        radius=16,
        fill=(255, 255, 255, 230),
    )
    logo_path = logo_dir / f"{logo_key}.png"
    if logo_path.exists():
        icon = Image.open(logo_path).convert("RGBA")
        icon.thumbnail((40, 40), Image.Resampling.LANCZOS)
        ox = ix + (icon_box - icon.width) // 2
        oy = iy + (icon_box - icon.height) // 2
        card.paste(icon, (ox, oy), icon)
    label = svc_name if len(svc_name) <= 14 else svc_name[:13] + "…"
    bbox = cd.textbbox((0, 0), label, font=font)
    tw = bbox[2] - bbox[0]
    cd.text(((cell_w - tw) // 2, 78), label, font=font, fill=(255, 245, 240, 235))
    bg.paste(card, (x, y), card)

out = Path("docs/screenshots/catalog_grid.jpg")
bg.convert("RGB").save(out, "JPEG", quality=90, optimize=True)
print("wrote", out, out.stat().st_size, "size", bg.size)
