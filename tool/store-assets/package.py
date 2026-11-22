#!/usr/bin/env python3
"""Validate exact store dimensions, build the local gallery, and package exports.

Uses only the Python standard library. Run from the repository root after the
Flutter export harness and opaque.swift. Does not publish or upload anything.
"""
import hashlib
import html
import json
from pathlib import Path
import struct
import subprocess
import zipfile

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "store-assets/v3"
DEVICES = {
    "apple/iphone": ("iPhone · Dynamic Island", 1206, 2622),
    "apple/iphone-large": ("iPhone · large display", 1320, 2868),
    "apple/iphone-face-id-large": ("iPhone · Face ID large display", 1242, 2688),
    "apple/iphone-home-button-large": ("iPhone · Home Button large display", 1242, 2208),
    "apple/ipad-13": ("iPad · 13-inch", 2752, 2064),
    "google-play/phone": ("Android · phone", 1080, 1920),
    "google-play/tablet-7": ("Android · 7-inch tablet", 1920, 1080),
    "google-play/tablet-10": ("Android · 10-inch tablet", 2560, 1440),
}
SLUGS = ["01-soon", "02-since", "03-live-countdown", "04-make-it-yours",
         "05-reminders", "06-share-or-display", "07-background-library"]
EXACT = {
    "campaign/apple/header-and-search-results/header.png": (3840, 1646),
    "campaign/apple/header-and-search-results/search-results.png": (3840, 2560),
    "campaign/apple/header-and-search-results/universal.png": (5244, 2950),
    "campaign/google-play/feature-graphic.png": (1024, 500),
    "campaign/google-play/app-icon.png": (512, 512),
    "brand/icon-512.png": (512, 512),
    "brand/icon-1024.png": (1024, 1024),
}


def png_info(file):
    data = file.read_bytes()
    assert data[:8] == b"\x89PNG\r\n\x1a\n", f"Invalid PNG: {file}"
    w, h, depth, color, *_ = struct.unpack(">IIBBBBB", data[16:29])
    assert depth == 8, f"Expected 8-bit PNG: {file}"
    return {"width": w, "height": h, "pngColorType": color,
            "bytes": len(data), "sha256": hashlib.sha256(data).hexdigest()}


def validate():
    expected = dict(EXACT)
    for kind in ["screenshots", "campaign"]:
        for device, (_, w, h) in DEVICES.items():
            for slug in SLUGS:
                expected[f"{kind}/{device}/{slug}.png"] = (w, h)
    for path, dims in expected.items():
        assert (OUT / path).is_file(), f"Missing export: {path}"
        meta = png_info(OUT / path)
        assert (meta["width"], meta["height"]) == dims, f"Wrong dimensions: {path}"
    images = []
    for file in sorted(OUT.rglob("*.png")):
        path = file.relative_to(OUT).as_posix()
        meta = png_info(file)
        if path == "campaign/google-play/app-icon.png":
            assert meta["pngColorType"] == 6, "Play icon must be 32-bit RGBA"
            assert meta["bytes"] <= 1024 * 1024, "Play icon exceeds 1 MB"
        else:
            assert meta["pngColorType"] == 2, f"Export still has an alpha channel: {path}"
        if path.startswith(("campaign/google-play/", "screenshots/google-play/")):
            assert meta["bytes"] <= 8 * 1024 * 1024, f"Play image exceeds 8 MB: {path}"
        images.append({"path": path, **meta})
    return images


def gallery(images):
    meta = {item["path"]: item for item in images}
    sections = []
    for device, (label, w, h) in DEVICES.items():
        cards = []
        for slug in SLUGS:
            path = f"campaign/{device}/{slug}.png"
            raw = f"screenshots/{device}/{slug}.png"
            title = slug[3:].replace("-", " ").capitalize()
            cards.append(f'<article><a href="{path}" target="_blank"><img loading="lazy" src="{path}" '
                         f'alt="{html.escape(label)}: {title}" width="{w}" height="{h}"></a>'
                         f'<h3>{title}</h3><p>{w} × {h} · '
                         f'<a href="{path}" download>Campaign PNG</a> · '
                         f'<a href="{raw}" download>Raw screenshot</a></p></article>')
        sections.append(f'<section id="{device.replace("/", "-")}"><h2>{label}</h2>'
                        f'<div class="grid {"landscape" if w > h else ""}">{"".join(cards)}</div></section>')
    graphic_cards = []
    for path in EXACT:
        if not path.startswith("campaign/"):
            continue
        title = Path(path).stem.replace("-", " ").capitalize()
        item = meta[path]
        graphic_cards.append(f'<article><a href="{path}" target="_blank"><img loading="lazy" src="{path}" '
                             f'alt="{title}"></a><h3>{title}</h3><p>{item["width"]} × {item["height"]} · '
                             f'<a href="{path}" download>Download PNG</a></p></article>')
    nav = ''.join(f'<a href="#{key.replace("/", "-")}">{value[0]}</a>' for key, value in DEVICES.items())
    page = '''<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Soon and Since — Store artwork</title><style>
:root{color-scheme:light;--paper:#fbf9f3;--ink:#2e2a3a;--yellow:#ffe36e}*{box-sizing:border-box}
body{margin:0;background:var(--paper);color:var(--ink);font:16px/1.5 system-ui,sans-serif}
header,main{max-width:1560px;margin:auto;padding:32px}h1{font-size:clamp(34px,5vw,64px);line-height:1.05;margin:24px 0 16px}
header p{max-width:820px}nav{display:flex;flex-wrap:wrap;gap:8px}nav a,.pill{padding:9px 14px;border:1px solid #ddd5c7;border-radius:24px;text-decoration:none}
a{color:inherit;text-underline-offset:3px}.pill{display:inline-block;background:var(--yellow);font-weight:650}
section{margin:32px 0 64px;scroll-margin-top:24px}h2{font-size:30px}.grid{display:grid;grid-template-columns:repeat(4,minmax(0,1fr));gap:24px}
.landscape,.graphics{grid-template-columns:repeat(2,minmax(0,1fr))}article{min-width:0}article img{width:100%;height:auto;display:block;border:1px solid #e6e1d3;border-radius:12px}
article h3{margin:14px 0 4px;font-size:17px}article p{margin:0;color:#6b6677;font-size:13px}.wide{width:100%;height:auto;border-radius:12px}
.note{background:#f1ede2;padding:20px 24px;border-radius:16px;margin:24px 0}.note p{margin:8px 0}.small{font-size:14px;color:#6b6677}
@media(max-width:900px){.grid{grid-template-columns:repeat(2,minmax(0,1fr))}.landscape,.graphics{grid-template-columns:1fr}header,main{padding:20px}}
</style><header><img src="brand/mark.svg" alt="Soon and Since hourglass" width="64" height="64"><h1>Every day has a story.</h1>
<p>Soon and Since · Version 3.0 · English (US). Seven screenshots per device, matching store artwork, and the Android icon set.</p>
<p><a class="pill" href="soon-and-since-v3-store-assets.zip" download>Download the complete pack</a> <a href="README.md">Upload guide</a> · <a href="metadata/en-US.json">Listing copy</a> · <a href="manifest.json">Asset manifest</a></p>
<nav>''' + nav + '''<a href="#graphics">Headers &amp; icons</a></nav></header><main>
<div class="note"><p><strong>Choose one screenshot family per device.</strong> Campaign images add headlines and a frame; raw screenshots show the full app directly. Keep the numbered order.</p>
<p>Apple: upload either the universal artwork to both placements, or the separate header and search images. Safe-area overlays in review/ are for inspection only.</p>
<p class="small">Screens use the actual Flutter widgets with controlled sample data and platform themes. The scenic photo is an original AI-generated sample background. Artwork and listing copy are saved as version 3 drafts in App Store Connect and Google Play. See the <a href="UPLOADS.md">upload record</a>.</p></div>
''' + ''.join(sections) + '<section id="graphics"><h2>Headers &amp; store icons</h2><div class="grid graphics">' + ''.join(graphic_cards) + '''</div></section>
<section><h2>Android launcher masks</h2><img class="wide" src="review/android-launcher.png" alt="Play, legacy, adaptive circle, adaptive squircle and themed icon previews"></section>
<section><h2>Brand palette</h2><img class="wide" src="brand/brand-board.png" alt="Brand typography and color palette"></section>
</main></html>'''
    (OUT / "index.html").write_text(page, encoding="utf-8")


def main():
    images = validate()
    copy = json.loads((OUT / "metadata/en-US.json").read_text(encoding="utf-8"))
    limits = {
        "apple": {"name": 30, "subtitle": 30, "promotionalText": 170,
                  "description": 4000, "whatsNew": 4000, "keywords": 100},
        "googlePlay": {"name": 30, "shortDescription": 80,
                       "fullDescription": 4000, "releaseNotes": 500},
    }
    for store, fields in limits.items():
        for field, limit in fields.items():
            assert 0 < len(copy[store][field]) <= limit, f"Invalid {store}.{field} length"
    inputs = [ROOT / "tool/store_assets_test.dart", ROOT / "tool/store-assets/opaque.swift",
              ROOT / "tool/store-assets/photos/weekend-away.png", ROOT / "tool/splash/mark.swift"]
    manifest = {
        "name": "Soon and Since", "version": "3.0", "locale": "en-US",
        "sourceCommit": subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=ROOT, text=True).strip(),
        "sampleClock": "2026-11-22T09:41:00", "screensPerDevice": len(SLUGS),
        "capture": "Actual Flutter widgets, deterministic sample events, iOS/Android platform themes, representative safe insets; no native system chrome.",
        "inputs": [{"path": p.relative_to(ROOT).as_posix(), "sha256": hashlib.sha256(p.read_bytes()).hexdigest()} for p in inputs],
        "images": images,
        "metadata": copy,
    }
    (OUT / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    gallery(images)
    archive = OUT / "soon-and-since-v3-store-assets.zip"
    with zipfile.ZipFile(archive, "w", zipfile.ZIP_DEFLATED) as z:
        for file in sorted(OUT.rglob("*")):
            if file.is_file() and file.suffix != ".zip" and file.name != ".DS_Store":
                z.write(file, file.relative_to(OUT))
    with zipfile.ZipFile(archive) as z:
        assert z.testzip() is None, "Corrupt ZIP"
    print(f"Validated {len(images)} PNGs, including {len(DEVICES) * len(SLUGS)} raw and {len(DEVICES) * len(SLUGS)} campaign screenshots.")
    print(f"Packaged {archive.relative_to(ROOT)} ({archive.stat().st_size / 1024 / 1024:.1f} MB)")


if __name__ == "__main__":
    main()
