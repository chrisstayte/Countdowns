# Since & Soon

Since & Soon (formerly Countdowns) counts down to the days ahead and up from the days behind.

Created: December 22, 2021 9:38 PM
Tier: Beginner

Android - https://play.google.com/store/apps/details?id=com.chrisstayte.countdowns&hl=en&gl=US

iOS - https://apps.apple.com/us/app/countdowns-chris-stayte/id1603744166


## Application stack

Since & Soon runs on Flutter 3.50.1 and Dart 3.14.0. The previous app declared Dart 3.7, Provider 6 and GoRouter 14.

| Area | Implementation |
| --- | --- |
| State | Riverpod 3 manages saved events, per-editor drafts, preferences, sorted views and a shared one-second clock. Closing an editor discards its unsaved draft. |
| Navigation | GoRouter 18 owns the Events screen, event details, new and edit forms, date picker, settings and iOS app icons. Date confirmation returns the selection to the open form. |
| Storage | Hive 2 stores events locally in the `events` box. Integer event IDs, adapter type 0 and the original field numbers are preserved. SharedPreferences stores the `localSettings` JSON object. Startup imports older mobile JSON files when present. |
| Interface | Material and Cupertino widgets, bundled fonts, Font Awesome, AutoSizeText, FlexColorPicker and Flutter Animate render the existing screens. |
| Device features | AudioPlayers and Flutter haptics provide feedback. Local Notifications, Flutter Timezone and timezone schedule mobile reminders. Alternate icons use flutter_dynamic_icon_plus on iOS. |
| Native builds | iOS and macOS use Swift Package Manager. Android uses Gradle 9.5, Android Gradle Plugin 9.3.1, Java 17 and compile SDK 37. The Android icon and review plugins still use the Kotlin Gradle Plugin. |

Use `flutter pub get` to install the locked dependencies, `flutter test` for the regression suite and `flutter run` to open the app on a selected device.

## Stock photos

The All backgrounds sheet offers free background photos from our own catalogue on Cloudflare R2, served from `https://media.countdowns.stayte.app` as a public JSON manifest plus pre-optimised images. There is no API key. The app caches the manifest on the device and hides the stock sections entirely when it can't be reached. See `lib/stock/` (the app side only knows the `StockPhotoSource` interface).

Debug and release builds both read the live catalogue. When the catalogue is empty, switched off or unreachable, the Photos tab shows only your own photos and the stock photos you already downloaded.

Privacy: the app only downloads public files from that host. No user data or analytics are sent.

## Releases

Development checks run on `dev`. Promote to `main` to build and validate both signed mobile apps and upload to TestFlight and Google Play internal testing. Production promotion is a separate manual action. See [RELEASING.md](RELEASING.md) for build numbers, app and widget signing, environment secrets, validation, and recovery.

## Original project brief

The objective of Countdown Timer is to provide a continuously decrementing display of the he months, days, hours, minutes, and seconds to a user entered event.

### Constraints

- Use only builtin language functions for your calculations rather than relying on a library or package.
- Can’t use any code generators such as the counting down to site.

### **User Stories**

- [X]  User can see an event input box containing an event name field, an date field, an optional time, and a ‘Start’ button.
- [ ]  User can define the event by entering its name, the date it is scheduled to take place, and an optional time of the event. If the time is omitted it is assumed to be at Midnight on the event date in the local time zone.
- [X]  User can see a warning message if the event name is blank.
- [X]  User can see a warning message if the event date or time are incorrectly entered.
- [X]  User can see a warning message if the time until the event data and time that has been entered would overflow the precision of the countdown timer.
- [ ]  User can click on the ‘Start’ button to see the countdown timer start displaying the days, hours, minutes, and seconds until the event takes place.
- [X]  User can see the elements in the countdown timer automatically decrement. For example, when the remaining seconds count reaches 0 the remaining minutes count will decrement by 1 and the seconds will start to countdown from 59. This progression must take place from seconds all the way up to the remaining days position in countdown display.

### **Bonus features**

- [X]  User can save the event so that it persists across sessions
- [ ]  User can see an alert when the event is reached
- [X]  User can specify more than one event.
- [X]  User can see a countdown timers for each event that has been defined.


