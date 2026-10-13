#!/usr/bin/env python3
"""Build crisp branded assets; prefer the site's original 1600px artwork over the old 192px favicon."""
import base64
import io
import json
from pathlib import Path
from urllib.request import Request, urlopen
from PIL import Image, ImageDraw, ImageEnhance, ImageFilter

ROOT = Path(__file__).resolve().parents[1]
ASSETS = ROOT / "BlasterMCMobile" / "Assets.xcassets"

def load_logo():
    # Original site asset from the user's BlasterMC production package: 1600 x 480 PNG.
    # It contains the golden 3D B followed by the wordmark. Crop the B only.
    sources = [
        "https://blastermc.com/assets/blastermc/v25/identity-premium/brand.png",
        "https://www.blastermc.com/assets/blastermc/v25/identity-premium/brand.png",
    ]
    for url in sources:
        try:
            request = Request(url, headers={"User-Agent": "BlasterMC-iOS-Assets/3.5"})
            with urlopen(request, timeout=9) as response:
                blob = response.read(4_000_000)
                if response.status != 200: continue
                source = Image.open(io.BytesIO(blob)).convert("RGBA")
                if source.width < 1200 or source.height < 400: continue
                # The logo occupies x=65..395, y=0..406. Keep safe breathing room.
                crop = source.crop((45, 0, 399, 430))
                canvas = Image.new("RGBA", (560, 560))
                crop.thumbnail((445, 500), Image.Resampling.LANCZOS)
                canvas.alpha_composite(crop, ((560-crop.width)//2, (560-crop.height)//2))
                print("BrandLogo: high-resolution original source:", source.size)
                return canvas
        except Exception as exc:
            print("BrandLogo: high-resolution retrieval unavailable:", type(exc).__name__)
    print("BrandLogo: using bundled compact monogram fallback")
    compact = (ROOT / "branding" / "logo-compact.base64").read_text().strip()
    image = Image.open(io.BytesIO(base64.b64decode(compact, validate=True))).convert("RGBA")
    return image.resize((560,560), Image.Resampling.LANCZOS)

logo = load_logo()
brand = ASSETS / "BrandLogo.imageset"
brand.mkdir(parents=True, exist_ok=True)
logo.save(brand / "BrandLogo.png")
(brand / "Contents.json").write_text(json.dumps({
    "images": [{"filename":"BrandLogo.png","idiom":"universal"}],
    "info": {"author":"xcode","version":1}
}, indent=2))

# REALM 13 app icon: a custom luminous portal and isometric cube.
# Keep the original BlasterMC B logo as the in-app brand mark, but make the
# installed app icon a distinct piece of artwork instead of a recolored logo.
icons = ASSETS / "AppIcon.appiconset"
icons.mkdir(parents=True, exist_ok=True)
n = 1024
base = Image.new("RGB", (n, n))
pixels = base.load()
for y in range(n):
    fy = y / (n - 1)
    for x in range(n):
        fx = x / (n - 1)
        glow = max(0.0, 1.0 - (((fx - 0.70) ** 2 + (fy - 0.30) ** 2) ** 0.5) * 1.45)
        pixels[x, y] = (
            min(255, round(5 + 18 * fx + 14 * glow)),
            min(255, round(15 + 35 * (1 - fy) + 30 * glow)),
            min(255, round(37 + 62 * (1 - fy) + 40 * glow)),
        )

grid = Image.new("RGBA", (n, n), (0, 0, 0, 0))
grid_draw = ImageDraw.Draw(grid)
for coordinate in range(40, n, 80):
    grid_draw.line((coordinate, 0, coordinate, n), fill=(170, 221, 255, 13), width=1)
    grid_draw.line((0, coordinate, n, coordinate), fill=(170, 221, 255, 13), width=1)
base = Image.alpha_composite(base.convert("RGBA"), grid)

glow_layer = Image.new("RGBA", (n, n), (0, 0, 0, 0))
glow_draw = ImageDraw.Draw(glow_layer)
glow_draw.ellipse((220, 90, 810, 900), fill=(79, 196, 236, 115))
glow_layer = glow_layer.filter(ImageFilter.GaussianBlur(58))
base = Image.alpha_composite(base, glow_layer)

portal = Image.new("RGBA", (n, n), (0, 0, 0, 0))
draw = ImageDraw.Draw(portal)
bbox = (260, 90, 770, 885)
draw.arc(bbox, start=198, end=340, fill=(255, 180, 91, 255), width=44)
draw.arc(bbox, start=20, end=160, fill=(120, 222, 246, 255), width=44)
draw.arc(bbox, start=164, end=194, fill=(220, 241, 255, 240), width=32)
draw.arc(bbox, start=344, end=376, fill=(255, 212, 145, 255), width=30)
# Portal opening and a softly illuminated inner rim.
draw.ellipse((322, 151, 708, 820), fill=(12, 40, 85, 135), outline=(151, 224, 246, 70), width=5)
base = Image.alpha_composite(base, portal)

# Floating voxel fragments.
draw = ImageDraw.Draw(base)
def cube(cx, cy, size, top, left, right):
    half = size // 2
    rise = size // 4
    depth = size // 2
    top_points = [(cx, cy), (cx + half, cy + rise), (cx, cy + rise * 2), (cx - half, cy + rise)]
    left_points = [(cx - half, cy + rise), (cx, cy + rise * 2), (cx, cy + rise * 2 + depth), (cx - half, cy + rise + depth)]
    right_points = [(cx + half, cy + rise), (cx, cy + rise * 2), (cx, cy + rise * 2 + depth), (cx + half, cy + rise + depth)]
    draw.polygon(left_points, fill=left)
    draw.polygon(right_points, fill=right)
    draw.polygon(top_points, fill=top)
    draw.line(top_points + [top_points[0]], fill=(255, 255, 255, 100), width=2)

cube(790, 285, 112, (255, 198, 115, 255), (35, 88, 145, 255), (12, 47, 91, 255))
cube(228, 625, 86, (158, 229, 246, 255), (29, 89, 150, 255), (12, 44, 87, 255))
cube(800, 710, 70, (255, 181, 92, 255), (36, 87, 143, 255), (10, 42, 81, 255))
# Tiny light fragments and premium frame.
draw.ellipse((180, 285, 194, 299), fill=(255, 190, 105, 255))
draw.ellipse((830, 470, 840, 480), fill=(173, 232, 247, 255))
draw.ellipse((735, 180, 743, 188), fill=(255, 255, 255, 230))
draw.rounded_rectangle((25, 25, 999, 999), radius=225, outline=(255, 193, 111, 230), width=7)
draw.rounded_rectangle((43, 43, 981, 981), radius=208, outline=(190, 229, 248, 75), width=2)

base.convert("RGB").save(icons / "AppIcon-1024.png", optimize=True)
(icons / "Contents.json").write_text(json.dumps({
    "images":[{"filename":"AppIcon-1024.png","idiom":"universal","platform":"ios","size":"1024x1024"}],
    "info":{"author":"xcode","version":1}
},indent=2))
print("REALM portal app icon and high-resolution original BlasterMC brand mark generated.")
