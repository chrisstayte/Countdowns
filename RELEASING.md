# Mobile releases

Countdowns uses the same release flow as Dominoes Calculator. Pushes and pull requests targeting `dev` run Flutter analysis and tests. Pull requests targeting `main` also build the unsigned iOS app and widget, build an Android release bundle, and run Android widget unit tests. Every push to `main` runs checks, reserves one shared build number, builds and validates both signed binaries, and then uploads to TestFlight and Google Play internal testing.

For a fresh build, use **Actions → Mobile release → Run workflow** on `main`. Choose `validate` for unsigned builds without secrets, tags, or uploads; `testflight`, `play-internal`, or `both` selects upload destinations. Both signed platforms must validate before either upload. A single-store recovery still validates both signed builds.

## App identity and existing listings

- App: `com.chrisstayte.countdowns` (Apple team `G3DYVCQJHD`).
- Widget: `com.chrisstayte.countdowns.CountdownsWidget`.
- Shared App Group: `group.com.chrisstayte.countdowns` on both targets.
- [App Store Connect](https://appstoreconnect.apple.com/apps/1603744166/distribution).
- [Google Play Console](https://play.google.com/console/u/0/developers/5696661877918052810/app/4973710932534622764/app-dashboard).

The store histories were inspected on November 21, 2026: TestFlight's latest upload was version 2.1.0 build 6; Play's latest uploaded bundle was version 2.0.0 code 6. App Store Connect already has a 3.0 draft. `pubspec.yaml` therefore starts at `3.0.0+6` and `MOBILE_BUILD_NUMBER_SEED` is 6, making the next automated release `3.0.0+7`.

The workflow chooses one more than the highest of that repository variable, the pubspec suffix, and all prior `mobile-vX.Y.Z+N` tags across versions. Upload runs reserve a tag on the exact source commit before any store upload. Leave tags in place after failures. Inspect processing before recovering from ambiguous uploads, then dispatch a fresh run for the missing destination. Update the seed after uploads outside this workflow. Validation runs never reserve a number.

## Environments and secrets

The `testflight`, `play-internal`, and `play-production` GitHub environments only allow deployments from the selected branch `main`. Store credentials belong in environment secrets, never Git history or repository variables. Pull request validation and development checks do not read them.

| Environment | Secrets |
| --- | --- |
| `testflight` | `ASC_API_KEY_P8`, `ASC_API_KEY_ID`, `ASC_API_ISSUER_ID`, `APPLE_DISTRIBUTION_P12_BASE64`, `APPLE_DISTRIBUTION_P12_PASSWORD`, `COUNTDOWNS_APPSTORE_PROFILE_BASE64`, `COUNTDOWNS_WIDGET_APPSTORE_PROFILE_BASE64` |
| `play-internal` | `ANDROID_KEYSTORE_BASE64`, `ANDROID_STORE_PASSWORD`, `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD`, `PLAY_SERVICE_ACCOUNT_JSON` |
| `play-production` | `PLAY_SERVICE_ACCOUNT_JSON` with production release permission |

Use original `.p8` private key text and complete service account JSON. Certificates, keystores, and provisioning profiles use single-line base64. Reuse the personal Apple distribution identity backed up in iCloud Drive → Development → Apple Signing and the registered Android upload key in Development → FlutterGoogleUpload. Each Apple target needs its own App Store Connect profile using the shared certificate and App Group. The app profile must also allow production push notifications. The signing script validates the profiles before importing assets, installs both profiles in an ephemeral runner keychain, imports Apple’s public WWDR G3 intermediate certificate, and removes the assets afterward while restoring the original keychain search list.

An App Store Connect Developer API key can upload builds. Apple team keys cover the personal team, so keep the key inside the main-only environment. Use separate Google testing and production identities, granting only the needed permissions for Countdowns. Verify the upload certificate fingerprint against Play Console before installing the Android key.

## Toolchain and validation

Flutter 3.50.1 is pinned to commit `ae9b586f34a8443573f82ef57c3bf914a908cbf7`. iOS uses the same `xcode-27` hosted runner and explicit Xcode 27.2 path as Dominoes; see the [runner inventory](https://github.com/actions/runner-images/blob/main/images/macos/xcode-27-arm64-Readme.md). The project uses Swift Package Manager. Both app and embedded widget must report the requested identifiers, version, build number, and iOS SDK 27 or newer. Signed IPAs are verified with codesign and Apple's upload validator before distribution.

Android uses Java 21 to run Gradle, Java 17 bytecode, compile SDK 37, Gradle 9.5, and the existing Compose/Glance widget configuration. CI signs using environment variables; local `android/key.properties` remains supported, and builds without signing material remain unsigned. Signed bundles must pass archive and signing checks. `:app:testDebugUnitTest` runs the native widget regression suite.

## Production

TestFlight uploads require Apple processing. Google uploads go to **internal testing**. Neither path submits a public production release automatically.

After internal testing, use **Actions → Promote tested Play release to production → Run workflow** on `main` and enter the tested version code. This explicitly requests a full production rollout of that uploaded internal release, subject to Google review and managed publishing. It builds nothing and consumes no build number. Check Publishing overview for any remaining review or publishing actions. Submit the processed iOS build for App Review separately in App Store Connect.
