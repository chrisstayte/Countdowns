# Countdowns

- Integrate changes into dev. Pushes and pull requests targeting dev run Flutter analysis and tests.
- Promote dev to main when asked to prepare a release. Every push to main uploads to TestFlight and Google Play internal testing after checks and both signed builds pass validation.
- Use a manual Mobile release from main for requested fresh uploads to either or both stores. Build numbers are shared and reserved with mobile-vX.Y.Z+N tags before upload; leave reserved tags in place after failures.
- Keep store credentials in the main-only testflight, play-internal, and play-production environments. See [release setup](RELEASING.md).
- iOS signing covers Runner and CountdownsWidget, with separate App Store profiles and the shared group.com.chrisstayte.countdowns App Group.
- Reuse the Apple distribution identity backed up in iCloud Drive → Development → Apple Signing. The registered Android upload key is in Development → FlutterGoogleUpload. Do not create another distribution certificate to add an app.
