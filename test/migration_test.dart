import 'dart:convert';
import 'dart:io';

import 'package:countdowns/data/database.dart';
import 'package:countdowns/models/countdown.dart';
import 'package:countdowns/models/event.dart';
import 'package:countdowns/models/local_settings.dart';
import 'package:countdowns/models/palette.dart';
import 'package:countdowns/storage/hive_migration.dart';
import 'package:countdowns/storage/legacy_import.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

final now = DateTime(2026, 11, 21, 12);

/// Fixtures written with the real adapter, as the shipped app did.
Map<int, Event> fixtures() => {
  3: Event(
    title: 'Mia’s birthday',
    eventDateTime: DateTime(2027, 2, 3),
    icon: Icons.cake,
    backgroundColor: const Color(0xFFFE607C),
    fontFamily: 'ComicNeue',
  ),
  7: Event(
    title: 'Japan trip',
    eventDateTime: DateTime(2027, 3, 14, 9, 30),
    allDayEvent: false,
    // A rare icon and a custom colour outside the palette.
    icon: Icons.flutter_dash,
    backgroundColor: const Color(0xFF123456),
    contentColor: const Color(0xFFFFFFFF),
    backgroundGradient: true,
  ),
  9: Event(
    title: 'Moved in',
    eventDateTime: DateTime(2026, 8, 2),
    icon: Icons.apartment,
  ),
  11: Event(title: 'No icon', eventDateTime: DateTime(2027, 1, 1)),
  12: Event(
    title: 'Unknown icon',
    eventDateTime: DateTime(2027, 5, 5),
    icon: Icons.ac_unit,
  ),
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory dir;
  late Box<Event> box;
  late AppDatabase db;
  late SharedPreferences prefs;

  setUpAll(() => Hive.registerAdapter(EventAdapter()));

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('countdowns-migration');
    Hive.init(dir.path);
    box = await Hive.openBox<Event>('events');
    await box.putAll(fixtures());
    await box.close();
    box = await Hive.openBox<Event>(
      'events',
      compactionStrategy: (_, _) => false,
    );
    db = AppDatabase(NativeDatabase.memory());
    SharedPreferences.setMockInitialValues({
      'localSettings': jsonEncode({'notify': true, 'themeMode': 2}),
    });
    prefs = await SharedPreferences.getInstance();
  });

  tearDown(() async {
    await db.close();
    await Hive.close();
    await dir.delete(recursive: true);
  });

  Future<MigrationOutcome> migrate({void Function(int)? beforeInsert}) =>
      migrateHiveToDrift(
        db: db,
        prefs: prefs,
        box: box,
        notify: true,
        now: now,
        beforeInsert: beforeInsert,
      );

  Countdown byTitle(List<Countdown> all, String title) =>
      all.singleWhere((c) => c.title == title);

  test('copies every field from Hive', () async {
    expect(await migrate(), MigrationOutcome.copied);
    expect(prefs.getBool(driftMigratedKey), isTrue);
    final all = await db.allCountdowns();
    expect(all, hasLength(5));

    final mia = byTitle(all, 'Mia’s birthday');
    expect(mia.dateTime, DateTime(2027, 2, 3));
    expect(mia.allDay, isTrue);
    expect(mia.iconSlug, 'cake');
    expect(mia.colorArgb, 0xFFFE607C);
    expect(mia.gradientId, isNull);
    expect(mia.gradientDirection, isNull);
    expect(mia.fontFamily, 'ComicNeue');
    expect(mia.unit, CountUnit.days);
    expect(mia.repeat, RepeatRule.none);
    expect(mia.reminders, [0]);
    expect(mia.legacyHiveKey, 3);
    expect(mia.photoPath, isNull);

    final japan = byTitle(all, 'Japan trip');
    expect(japan.dateTime, DateTime(2027, 3, 14, 9, 30));
    expect(japan.allDay, isFalse);
    expect(japan.iconSlug, 'bird');
    // Custom colour kept exactly, not snapped to the palette.
    expect(japan.colorArgb, 0xFF123456);
    expect(isPaletteColor(japan.colorArgb), isFalse);
    expect(japan.gradientId, legacyGradientId);
    expect(japan.gradientDirection, GradientDirection.diagonalDown);
    expect(japan.gradient, legacyGradientColors(const Color(0xFF123456)));
    expect(japan.fontFamily, 'Default');

    // A past event copies over but gets no reminder.
    final moved = byTitle(all, 'Moved in');
    expect(moved.iconSlug, 'apartment');
    expect(moved.reminders, isEmpty);
    expect(moved.isDone(now), isTrue);

    expect(byTitle(all, 'No icon').iconSlug, isNull);
    expect(byTitle(all, 'Unknown icon').iconSlug, 'calendar');
  });

  test('without notify, no reminders are added', () async {
    await migrateHiveToDrift(
      db: db,
      prefs: prefs,
      box: box,
      notify: false,
      now: now,
    );
    final all = await db.allCountdowns();
    expect(all.every((c) => c.reminders.isEmpty), isTrue);
  });

  test('running the copy twice does not duplicate anything', () async {
    await migrate();
    expect(await migrate(), MigrationOutcome.alreadyDone);
    // Even if the flag is lost, legacyHiveKey stops duplicates.
    await prefs.remove(driftMigratedKey);
    expect(await migrate(), MigrationOutcome.copied);
    final all = await db.allCountdowns();
    expect(all, hasLength(5));
    expect((await db.allReminders()), hasLength(4));
  });

  test('a copy interrupted part-way leaves Hive intact and retries', () async {
    final file = File('${dir.path}/events.hive');
    final before = await file.readAsBytes();
    final outcome = await migrate(
      beforeInsert: (index) {
        if (index == 2) throw const FileSystemException('disk full');
      },
    );
    expect(outcome, MigrationOutcome.failed);
    expect(prefs.getBool(driftMigratedKey), isNull);
    // The transaction rolled back: nothing half-copied.
    expect(await db.allCountdowns(), isEmpty);
    // Hive is untouched.
    await box.close();
    expect(await file.readAsBytes(), before);
    box = await Hive.openBox<Event>(
      'events',
      compactionStrategy: (_, _) => false,
    );
    expect(box.length, 5);
    expect(box.get(7)!.backgroundColor, const Color(0xFF123456));

    expect(await migrate(), MigrationOutcome.copied);
    expect(await db.allCountdowns(), hasLength(5));
    await box.close();
    expect(await file.readAsBytes(), before);
  });

  test('v1 JSON goes straight into Drift, once', () async {
    await File('${dir.path}/settings.json').writeAsString(
      jsonEncode({'themeMode': 2, 'squareView': false, 'notify': true}),
    );
    await File('${dir.path}/countdownevents.json').writeAsString(
      jsonEncode([
        {
          'title': 'Anniversary',
          'eventDate': '2031-01-01',
          'backgroundColor': 0xff123456,
          'icon': Icons.favorite.codePoint,
          'fontFamily': 'ComicNeue',
        },
        {'title': 'Old one', 'eventDate': '2020-01-01'},
      ]),
    );
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    await importLegacyData(dir, db, prefs, now: now);
    final settings = LocalSettings.fromJson(
      jsonDecode(prefs.getString('localSettings')!),
    );
    expect(settings.themeMode, ThemeMode.dark);
    expect(settings.squareView, isFalse);

    // An interruption after the rows commit but before the prefs flag.
    await prefs.remove('legacyEventsImported');
    await importLegacyData(dir, db, prefs, now: now);

    final all = await db.allCountdowns();
    expect(all, hasLength(2));
    final anniversary = byTitle(all, 'Anniversary');
    expect(anniversary.iconSlug, 'heart');
    expect(anniversary.colorArgb, 0xff123456);
    expect(anniversary.fontFamily, 'ComicNeue');
    expect(anniversary.reminders, [0]);
    expect(byTitle(all, 'Old one').reminders, isEmpty);
    expect(byTitle(all, 'Old one').iconSlug, isNull);
  });

  test('settings keep every existing key and unknown ones', () {
    final json = {
      'themeMode': 2,
      'sortingMethod': 'SortingMethod.dateDescending',
      'hapticFeedback': false,
      'soundEffects': true,
      'squareView': false,
      'notify': true,
      'iconName': 'crayon',
      'somethingNewer': 'keep me',
    };
    final settings = LocalSettings.fromJson(json);
    final out = settings.copyWith(keepDone: false).toJson();
    for (final key in json.keys) {
      expect(out[key], json[key], reason: key);
    }
    expect(out['keepDone'], false);
    expect(out['defaultUnit'], 'days');
  });

  test('saving replaces reminders but keeps ids of the ones that stay',
      () async {
    final id = await db.saveCountdown(
      Countdown(
        title: 'Trip',
        dateTime: DateTime(2027, 1, 1),
        reminders: const [0, 1440],
      ),
    );
    final first = await db.allReminders();
    final keptId = first.singleWhere((r) => r.offsetMinutes == 0).id;
    final all = await db.allCountdowns();
    await db.saveCountdown(all.single.copyWith(reminders: [0, 10080]));
    final second = await db.allReminders();
    expect(second.map((r) => r.offsetMinutes).toSet(), {0, 10080});
    expect(second.singleWhere((r) => r.offsetMinutes == 0).id, keptId);
    await db.deleteCountdown(id);
    expect(await db.allReminders(), isEmpty);
  });
}
