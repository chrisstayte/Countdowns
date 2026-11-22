# Countdowns redesign: build spec

Chris approved this work (2026-11-21): move storage to Drift, fix the notification bug, hide dark mode, and migrate the app to the new UI on the redesign canvas, with all event icons redrawn and a gradient library with directions.

The canvas is the source of truth for layout and look. The `boards/` folder holds every artboard as an HTML file. Open them in a browser to see each screen; the `renderVals()` block at the bottom of each file lists the exact colours, gradients, fonts and copy. `boards/canvas.json` has the notes that explain each row.

## 0. Ground rules

- **Do not touch Chris's `dev` working tree.** It has a lot of uncommitted work, including the new app icons. It must look exactly the same when you finish.
- Work in a git worktree on a new branch `redesign`, inside the project folder at `.worktrees/redesign`. Add `.worktrees/` to `.git/info/exclude`, not to `.gitignore`.
- Start the branch from `dev`. Its first commit must be a baseline of the current uncommitted changes, untracked files included, so nothing is lost. For example, copy tracked changes from `git stash create` and copy untracked files across. Never run `git stash` or `git checkout` in the main tree.
- Commit in small, logical steps. Do not push, publish or release anything.
- There is no backend. Everything stays on the device.
- Copy this handoff folder into the branch as `design/redesign/` and commit it.

## 1. Storage: Hive to Drift (SQLite)

- Add `drift`, `drift_flutter`, `sqlite3_flutter_libs` (or the current recommended set) and `build_runner` with `drift_dev`. Keep `hive` and `hive_flutter` only for the one-time copy.
- **Events table:**
  - id
  - title
  - eventDateTime
  - allDay
  - iconSlug (nullable)
  - colorArgb
  - gradientId (nullable)
  - gradientDirection (nullable)
  - photoPath (nullable)
  - photoCrops as JSON (nullable): a crop per shape plus a "same for all" flag
  - photoDarken
  - fontFamily
  - unit: days, weeks, sleeps or hours
  - repeat: none or yearly. Add more only if the canvas shows them.
  - createdAt
  - updatedAt
  - legacyHiveKey (nullable)
- **Reminders table:**
  - id
  - eventId
  - offsetMinutes, where 0 means at the time
  - Notification ids come from the reminder ids.
- **Settings:** keep them in SharedPreferences as they are today, under the `localSettings` JSON key. Add the new defaults (unit, reminders, Done section). Every existing key stays, is still read and is written back unchanged.
- **One-time copy at startup, before the UI.** Follow the pattern in `lib/storage/legacy_import.dart`:
  1. Open the Hive `events` box with the existing `EventAdapter`.
  2. Insert every event into Drift in one transaction, storing `legacyHiveKey` so the copy can safely run again.
  3. Set a `driftMigrated` flag only after the transaction commits.
  4. Never delete or rewrite the Hive file. Keep it as a backup for at least two releases.
  5. If the copy throws, log it, keep the Hive data and retry next launch. Never start the user on an empty database when Hive has data.
- The v1 JSON import (`countdownevents.json`, `settings.json`) must still work, and go straight into Drift.
- **Field mapping:**
  - The icon codepoint maps to a slug using `icons/icons.json` (the `material` name gives `Icons.<name>.codePoint`). An unknown codepoint becomes `calendar`.
  - `backgroundColor` maps to `colorArgb` as is. Do not snap custom colours to the palette.
  - `backgroundGradient == true` maps to gradientId `legacy`, direction `diagonalDown`. This is today's colour-to-complementary gradient.
  - `allDayEvent` maps to `allDay`.
  - `contentColor` is ignored, because text colour is always automatic.
  - If the global `notify` setting was on, every future event gets one reminder at offset 0.
- **Tests:**
  - Hive fixtures, written with the real adapter, copy correctly: every field, a missing icon, a custom colour, gradient on and off, a past event.
  - Running the copy twice does not duplicate anything.
  - A copy interrupted part-way leaves Hive intact.
  - v1 JSON goes into Drift.

## 2. Notifications bug

`EventNotifications.schedule` passes `matchDateTimeComponents: DateTimeComponents.time`, so the notification repeats every day at the event's time. Remove it:
- One-off events get one-shot notifications.
- Yearly repeats use `DateTimeComponents.dateAndTime`.
- Add per-event reminders (offsets from the editor: on the day, 1 day, 1 week before and so on, as drawn).
- Reschedule everything after the migration and whenever an event changes.
- Cancel the old daily repeating notifications once, on upgrade.
- Add a test for the schedule arguments.

## 3. Dark mode (hidden for now)

- Remove the theme toggle from Settings.
- Force `ThemeMode.light` in `MaterialApp`.
- Keep `themeMode` in `LocalSettings` and keep reading and writing it unchanged, so it can come back later. Don't delete it.
- Do the same for `sortingMethod` and `squareView`. Home now uses the new date sections and the list layout, but the stored values stay.

## 4. New UI (match the canvas)

Build in this order and commit after each:

1. **Theme.**
   - Colours: ground `#F5F4FF`, ink `#1C1633`, primary `#4A0D67`, save green `#1B998B`, secondary text `#5E5878`, borders `#D6D3F0`.
   - Fonts: Bricolage Grotesque for numerals and Inter for the UI, bundled as assets, not fetched.
   - Text on an event colour is chosen automatically, ink or white, by contrast. Photos always get white text with a shadow and a dark scrim.
2. **Home** (`Main.dc.html`, `PhoneSearch.dc.html`): the Up next hero, upcoming cards, a Done section for past events, search with recents and filters, and the dark (`#1C1633`) New countdown button. Search's holiday suggestions are optional.
3. **Detail** (`PhoneDetail.dc.html`, `DetailUnits.dc.html`): one giant number with the Days, Weeks, Sleeps and Hours switcher, and the supporting tiles for each unit.
   - **Years:** don't add a fifth tab. When the event is 365 or more days away, show one quiet line under the big number, such as "1 year, 42 days". The section on Years below has the full rule.
4. **Editor** (`PhoneEditor.dc.html`, with `PhoneFonts.dc.html` for the font sheet):
   - A live preview on top, then Details and Look tabs.
   - **Details:** name, date, time (with all day), repeats, Remind me (after When), count in.
   - **Look:**
     - Background grid: an add-photo tile, recent photos, gradients, the 12 colours.
     - Icons: the 15 most recently used plus an "All icons" sheet with search by label.
     - Fonts: 4 recent plus the "All fonts" sheet.
5. **Photos** (`PhotoStyle`, `PhotoCrop`, `PhotoHome`, `PhotoDetail`):
   - Copy each picked photo into the app documents folder and store only the relative path.
   - The crop screen outlines every shape (full screen, card, small widget, wide widget), with a crop point for each shape and a "Same spot for all" toggle.
   - Photo cards and the full-bleed detail screen.
6. **Settings** (`PhoneSettings.dc.html`): everything that is there today except the theme toggle, plus the defaults for new countdowns. The app icon picker stays as Chris's current working tree has it.
7. **Share** (`PhoneShare.dc.html`): a Story image, a Square image and a Calendar `.ics` file, all made on the device and sent through the system share sheet. There is no live link.
8. **iPad** (`TabletSplit`, `TabletLook`, `TabletCrop`, `TabletSettings`, `TabletWall`): the 3-pane split view, the editor with preview, Details and Look side by side, the crop screen with live thumbnails, sidebar settings, and wall mode.
9. **Widgets** (`WidgetsHome`, `WidgetsLock`, `WidgetGallery`, `PhotoWidgets`): do these last, and only once 1 to 8 pass.
   - iOS uses WidgetKit through an App Group.
   - The Flutter app writes a JSON snapshot of the events, plus resized photo copies, into the group container on every change. Widgets read only that snapshot.
   - The Live Activity is optional. If there isn't time, write down what's left instead of half-building it.

### Colours (the editor offers these only)

Lavender `#7877E6`, Charcoal `#8A8796`, Sun `#F7BC33`, Tomato `#FF564A`, Peach `#FEA08B`, Tangerine `#FE7228`, Lime `#83C236`, Cobalt `#597FFE`, Sky `#66B6FE`, Bubblegum `#FE607C`, Mint `#5FD3B5`, Lilac `#C9A7F5`.

There is no custom colour picker any more. An existing event with a colour outside this list keeps it. The editor shows that colour as an extra "Current" swatch first in the grid, until the user picks another.

### Gradient library

Each gradient has 2 or 3 stops taken from the palette above, plus `legacy`, which is the old automatic complementary gradient and is never offered for new events. Start with these 12:

- Sunset: Tangerine, Bubblegum
- Lagoon: Sky, Mint
- Grape: Lavender, Lilac
- Peachy: Peach, Sun
- Berry: Bubblegum, Lavender
- Ocean: Cobalt, Sky
- Citrus: Sun, Lime
- Ember: Tomato, Tangerine
- Mojito: Lime, Mint
- Dusk: Cobalt, Lilac, Peach
- Candy: Lilac, Bubblegum
- Aurora: Mint, Cobalt, Lavender

When a gradient is picked, show a direction row under the grid:

- Linear: down ↓, up ↑, right →, left ←, diagonal down ↘, diagonal up ↗
- Radial: from the centre outward
- Sweep: round in a circle

Each option is a small chip that previews the gradient in that direction. The direction applies everywhere the colour shows: cards, detail, widgets and share images.

### Icons

`icons/*.svg` holds 68 redrawn icons on a 24 grid. They use `currentColor` strokes at 1.75 with round caps, plus soft fills at 22% opacity of `currentColor`. `icons/icons.json` maps each slug to the old Material icon name and gives a short label. Render them with `flutter_svg`, tinted to the automatic text colour. The editor's main icon row is the 15 most recently used, falling back to: calendar, cake, party, plane, gift, heart, graduation, dining, note, tree, work, friends, baby, holiday, alarm. The rest are in "All icons".

### Years on the detail screen

The switcher stays Days, Weeks, Sleeps, Hours. When the event is 365 or more days away, show a small line under the giant number in the secondary text style. Day units show "2 years, 41 days", Weeks shows "2 years, 6 weeks" and Hours shows "2 years". Hide the line under a year. Cards on Home can say "in 2 years" when the event is 2 or more years away.

## 5. Checks before reporting

- `flutter analyze` is clean, and `flutter test` passes, including the new migration and notification tests.
- Build and run on an iPhone simulator and an iPad simulator.
- Start from a copy of real Hive data first: install the current `dev` build, add a few countdowns (custom colour, gradient, rare icon, past event, notify on), then install the redesign build over it. Confirm everything carried over.
- Save screenshots of each main screen to `build/redesign-shots/` in the main project folder (it's gitignored).
- Report what's done, what's left, and anything that differs from the canvas, with the reason.
