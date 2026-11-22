# Version 3 upload record

Uploaded through Chrome on November 22, 2026. Language: English (US).

## App Store Connect

[Since & Soon — iOS version 3.0](https://appstoreconnect.apple.com/apps/1603744166/distribution/ios/version/inflight)

- Dedicated product page header and search results artwork: 1 asset in each slot.
- Seven screenshots in each of five slots: iPhone Dynamic Island medium, iPhone Dynamic Island large, iPhone Face ID large, iPhone Home Button large, and iPad 13-inch.
- Screenshot order checked from 01 Soon through 07 Background Library.
- Description, What's New, promotional text, keywords, and copyright saved on version 3.0.
- App name is Since & Soon; subtitle updated to Countdowns & days since in App Information.
- Revisited the version page and verified the stored text matches `metadata/en-US.json`.
- Version remains **Prepare for Submission**. It was not added for review or released.

## Google Play Console

[Default store listing draft](https://play.google.com/console/u/0/developers/5696661877918052810/app/4973710932534622764/store-listings/default/edit)

- Store icon and feature graphic uploaded and assigned.
- Seven screenshots each for phone, 7-inch tablet, and 10-inch tablet. All three sets were verified in 01–07 order after reopening the saved listing.
- Name updated to Since & Soon to match iOS; short and full descriptions saved.
- Saved as a draft. No store-listing submission or production rollout was performed.

[Internal testing release draft 3.0.0 (7)](https://play.google.com/console/u/0/developers/5696661877918052810/app/4973710932534622764/tracks/4699726487448805508/releases/2/prepare)

- Included the existing version 7 (3.0.0) app bundle already available in Play Console.
- Added the English release notes from `metadata/en-US.json` and saved the draft.
- Verified the “Changes saved” receipt. No build was uploaded by this artwork task, no testers were added, and the release was not rolled out.
- The launcher resource changes in this repository will be present in the next binary built from them; saving listing assets does not modify an existing uploaded binary.

Google Play uploads used device-prefixed filenames (`phone-`, `tablet-7-`, `tablet-10-`) so the matching slot can be identified in its Asset Library. These copies have identical image bytes to their numbered campaign sources.

Local browser receipts are in `review/upload-proof-*.jpg`. They are included in the local downloadable pack and excluded from Git.
