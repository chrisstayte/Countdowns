# Soon and Since — store artwork, version 3

The store listing name is **Soon and Since**. The installed app and promotional artwork use **Soon & Since**. Public review submissions are paused after the November 22 rename.

Open `index.html` to review and download the artwork. The ZIP contains all final assets, raw screenshots, previews, listing copy, and the dimension/hash manifest. The artwork and English (US) metadata were uploaded and saved for version 3 on November 22, 2026. See [the upload record](UPLOADS.md) for the exact destinations and draft status.

Use the numbered **campaign** screenshots for the designed listing. The **screenshots** folder contains the same screens without marketing text or frames. Choose one family for each device; do not mix both families in the same screenshot row.

| Store slot | Folder / file | Pixels |
| --- | --- | --- |
| iPhone, Dynamic Island medium display | `campaign/apple/iphone/` | 1206 × 2622 |
| iPhone, large display | `campaign/apple/iphone-large/` | 1320 × 2868 |
| iPhone, Face ID large display | `campaign/apple/iphone-face-id-large/` | 1242 × 2688 |
| iPhone, Home Button large display | `campaign/apple/iphone-home-button-large/` | 1242 × 2208 |
| iPad 13-inch, landscape | `campaign/apple/ipad-13/` | 2752 × 2064 |
| Android phone | `campaign/google-play/phone/` | 1080 × 1920 |
| Android 7-inch tablet | `campaign/google-play/tablet-7/` | 1920 × 1080 |
| Android 10-inch tablet | `campaign/google-play/tablet-10/` | 2560 × 1440 |
| Apple product page header | `campaign/apple/header-and-search-results/header.png` | 3840 × 1646 |
| Apple search results | `campaign/apple/header-and-search-results/search-results.png` | 3840 × 2560 |
| Apple universal header/search asset | `campaign/apple/header-and-search-results/universal.png` | 5244 × 2950 |
| Google Play feature graphic | `campaign/google-play/feature-graphic.png` | 1024 × 500 |
| Google Play store icon | `campaign/google-play/app-icon.png` | 512 × 512 |

Seven screenshots per device: Soon, Since, a live countdown, customization, reminders, sharing (phones) / wall mode (tablets), and the background library. Events demonstrate an original scenic photo, an illustrated birthday, a gradient, a watercolor texture, a dark confetti pattern, mountain artwork, gingham, and a solid color.

`metadata/en-US.json` contains the final store name, subtitle, descriptions, promotional text, keywords, copyright, and platform-specific release notes. All fields fit their respective store limits.

For Apple, either upload the **universal** asset to both placements or use the dedicated header and search exports. They are composed separately around Apple's published safe rectangles; they are not stretched crops of one another. `review/apple-safe-areas/` shows the green inspection guides. Do not upload those annotated images.

All final artwork and screenshots are opaque 8-bit sRGB RGB PNGs. The Play icon is the required 32-bit RGBA PNG with an opaque square canvas, with no baked corner mask or external shadow. Play applies the store mask. The Android launcher uses a separate vector foreground in the adaptive icon safe area, plus a monochrome vector for themed icons and opaque legacy launcher PNGs at all five densities.

The identity follows the app's existing Highlighter icon and theme: Paper `#FBF9F3`, Ink `#2E2A3A`, Highlighter `#FFE36E`, Bricolage Grotesque headings and Inter body copy. `brand/` contains the SVG mark, square icon master, and palette board. Existing bundled font licenses remain in `fonts/`.

## Sources and capture

Screens are rendered offscreen from the actual Flutter screens using the shipping widgets, platform themes, bundled fonts, local sample events, a fixed clock, and representative safe insets. They are not AI-generated interfaces or captures of native OS chrome. Photo backgrounds use the real photo rendering/crop/scrim pipeline. No production event data, credentials, or live background catalog is accessed by the exporter.

`tool/store-assets/photos/weekend-away.png` is an original scenic background generated with OpenAI's built-in Image Generation tool on November 22, 2026 for these sample events. It is a fictional travel scene, not an identified destination or an item added to the production stock-photo catalog. All other event backgrounds are the app's own built-in artwork. The icon's exact vector coordinates come from `tool/splash/mark.swift`, matching the existing iOS Highlighter mark.

Specifications checked November 22, 2026: [Apple creative assets](https://developer.apple.com/help/app-store-connect/reference/app-information/creative-assets-specifications), [Apple screenshot sizes](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications), [Google Play preview assets](https://support.google.com/googleplay/android-developer/answer/9866151?hl=en), and [Android adaptive icons](https://developer.android.com/develop/ui/views/launch/icon_design_adaptive).

## Rebuild

From the repository root on macOS with the project's Flutter SDK and Xcode tools:

```sh
flutter test tool/store_assets_test.dart --reporter expanded
swift -module-cache-path /private/tmp/countdowns-store-module-cache tool/store-assets/opaque.swift store-assets/v3
python3 tool/store-assets/package.py
```

The first command renders the actual screens and designed campaign. The second removes PNG alpha channels and updates the five Android legacy launcher images. The third verifies exact dimensions, color types and size limits; writes SHA-256 provenance and the local review gallery; and makes `soon-and-since-v3-store-assets.zip`. Normal Flutter tests do not regenerate the pack.
