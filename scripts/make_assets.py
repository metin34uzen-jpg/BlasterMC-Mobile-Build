#!/usr/bin/env python3
"""Build crisp branded assets; prefer the site's original 1600px artwork over the old 192px favicon."""
import base64
import io
import json
from pathlib import Path
from urllib.request import Request, urlopen
from PIL import Image, ImageDraw, ImageEnhance

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

icons = ASSETS / "AppIcon.appiconset"
icons.mkdir(parents=True, exist_ok=True)
n = 1024
base = Image.new("RGB", (n,n))
pix = base.load()
for y in range(n):
    for x in range(n):
        u = max(0.0,min(1.0,(x/n)*0.5+(y/n)*0.5))
        pix[x,y] = (round(26+24*u),round(26+19*u),round(36+14*u))
draw=ImageDraw.Draw(base)
draw.rounded_rectangle((45,45,979,979),radius=230,outline=(166,101,36),width=8)
draw.rounded_rectangle((60,60,964,964),radius=220,outline=(87,62,38),width=3)
emblem = logo.resize((880,880), Image.Resampling.LANCZOS)
base.paste(emblem,((n-880)//2,(n-880)//2),emblem)
base.save(icons / "AppIcon-1024.png", optimize=True)
(icons / "Contents.json").write_text(json.dumps({
    "images":[{"filename":"AppIcon-1024.png","idiom":"universal","platform":"ios","size":"1024x1024"}],
    "info":{"author":"xcode","version":1}
},indent=2))
print("iOS gold B icon and high-resolution splash/logo assets generated.")
