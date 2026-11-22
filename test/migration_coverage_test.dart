// Exhaustive tests for the one-time Hive to Drift copy. Hive files are
// written exactly as shipped builds wrote them: with the real EventAdapter,
// or with a raw writer for formats the adapter can't produce (the first
// six-field version, unknown icon codepoints).
import 'dart:convert';
import 'dart:io';

import 'package:countdowns/data/database.dart';
import 'package:countdowns/models/countdown.dart';
import 'package:countdowns/models/event.dart';
import 'package:countdowns/models/event_icons.dart';
import 'package:countdowns/models/icon_catalog.dart';
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

/// Writes events field by field, for formats the current adapter can't
/// produce. Keyed by title.
final Map<String, List<Object?>> rawFields = {};

class _RawWriter extends TypeAdapter<Event> {
  @override
  final int typeId = 0;

  @override
  Event read(BinaryReader reader) => EventAdapter().read(reader);

  @override
  void write(BinaryWriter writer, Event value) {
    final fields = rawFields[value.title]!;
    writer.writeByte(fields.length);
    for (final (i, f) in fields.indexed) {
      writer.writeByte(i);
      writer.write(f);
    }
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory dir;
  late AppDatabase db;
  late SharedPreferences prefs;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('countdowns-coverage');
    Hive.init(dir.path);
    Hive.registerAdapter(EventAdapter(), override: true);
    db = AppDatabase(NativeDatabase.memory());
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  tearDown(() async {
    await db.close();
    await Hive.close();
    await dir.delete(recursive: true);
  });

  /// Writes [events] with the real adapter (or [raw] events with the raw
  /// writer), then reopens the box with the real adapter, as the app does.
  Future<Box<Event>> hive(
    Map<int, Event> events, {
    Map<int, List<Object?>> raw = const {},
  }) async {
    var box = await Hive.openBox<Event>('events');
    await box.putAll(events);
    await box.close();
    if (raw.isNotEmpty) {
      Hive.registerAdapter(_RawWriter(), override: true);
      box = await Hive.openBox<Event>('events');
      for (final e in raw.entries) {
        final title = e.value.first! as String;
        rawFields[title] = e.value;
        await box.put(e.key, Event(title: title, eventDateTime: now));
      }
      await box.close();
      Hive.registerAdapter(EventAdapter(), override: true);
    }
    return Hive.openBox<Event>('events', compactionStrategy: (_, _) => false);
  }

  Future<MigrationOutcome> migrate(
    Box<Event>? box, {
    bool notify = false,
    CountUnit unit = CountUnit.days,
    void Function(int)? beforeInsert,
  }) => migrateHiveToDrift(
    db: db,
    prefs: prefs,
    box: box,
    notify: notify,
    unit: unit,
    now: now,
    beforeInsert: beforeInsert,
  );

  Future<Countdown> only(String title) async =>
      (await db.allCountdowns()).singleWhere((c) => c.title == title);

  group('fields', () {
    test('every field maps through the real EventAdapter', () async {
      final box = await hive({
        4: Event(
          title: 'Japan trip',
          eventDateTime: DateTime(2027, 3, 14, 9, 30),
          allDayEvent: false,
          icon: Icons.airplanemode_active,
          backgroundColor: const Color(0xFF66B6FE),
          contentColor: const Color(0xFFFFFFFF),
          fontFamily: 'LibreBaskerville',
          backgroundGradient: true,
        ),
      });
      // The adapter reads back what it wrote.
      expect(box.get(4)!.title, 'Japan trip');
      expect(box.get(4)!.allDayEvent, isFalse);

      await migrate(box, unit: CountUnit.sleeps);
      final c = await only('Japan trip');
      expect(c.id, isNotNull);
      expect(c.title, 'Japan trip');
      expect(c.dateTime, DateTime(2027, 3, 14, 9, 30));
      expect(c.allDay, isFalse);
      expect(c.iconSlug, 'plane');
      expect(c.colorArgb, 0xFF66B6FE);
      expect(c.gradientId, legacyGradientId);
      expect(c.gradientDirection, GradientDirection.diagonalDown);
      expect(c.photoPath, isNull);
      expect(c.photoCrops, isNull);
      expect(c.photoDarken, 0.35);
      expect(c.fontFamily, 'LibreBaskerville');
      expect(c.unit, CountUnit.sleeps);
      expect(c.repeat, RepeatRule.none);
      expect(c.reminders, isEmpty);
      expect(c.createdAt, now);
      expect(c.updatedAt, now);
      expect(c.legacyHiveKey, 4);
      // contentColor is not stored: text colour is automatic.
      expect(c.textColor, ink);
    });

    test('the first six-field Hive format still copies', () async {
      final box = await hive(
        {},
        raw: {
          17: [
            'Birthday',
            DateTime(2032, 2, 1),
            Icons.cake.codePoint,
            null,
            null,
            null,
          ],
        },
      );
      await migrate(box);
      final c = await only('Birthday');
      expect(c.dateTime, DateTime(2032, 2, 1));
      expect(c.allDay, isTrue);
      expect(c.iconSlug, 'cake');
      expect(c.colorArgb, 0xFF7877E6);
      expect(c.fontFamily, 'Default');
      expect(c.gradientId, isNull);
      expect(c.legacyHiveKey, 17);
    });
  });

  group('icons', () {
    test('the catalog covers all 68 old icons in the old order', () {
      expect(eventIcons, hasLength(68));
      expect(eventIconCatalog, hasLength(68));
      expect(eventIconCatalog.map((i) => i.slug).toSet(), hasLength(68));
      for (final (i, icon) in eventIcons.indexed) {
        expect(
          eventIconCatalog[i].legacyCodePoint,
          icon.codePoint,
          reason: 'icon $i',
        );
      }
      // card_giftcard and wallet_giftcard are the same Material codepoint,
      // so 67 distinct values were ever stored.
      expect(eventIcons.map((i) => i.codePoint).toSet(), hasLength(67));
      expect(Icons.card_giftcard.codePoint, Icons.wallet_giftcard.codePoint);
    });

    test('every old icon codepoint copies to the right slug', () async {
      final box = await hive({
        for (final (i, icon) in eventIcons.indexed)
          i: Event(title: 'icon $i', eventDateTime: DateTime(2027), icon: icon),
      });
      await migrate(box);
      final all = await db.allCountdowns();
      expect(all, hasLength(68));
      for (final (i, info) in eventIconCatalog.indexed) {
        final c = all.singleWhere((c) => c.legacyHiveKey == i);
        // The shared gift codepoint always meant the first, Gift.
        final expected = info.slug == 'giftcard' ? 'gift' : info.slug;
        expect(
          c.iconSlug,
          expected,
          reason: 'codepoint ${info.legacyCodePoint}',
        );
        // And the redrawn icon file exists.
        expect(File(info.asset).existsSync(), isTrue, reason: info.asset);
      }
    });

    test('an unknown codepoint becomes calendar; no icon stays none', () async {
      final box = await hive(
        {1: Event(title: 'No icon', eventDateTime: DateTime(2027))},
        raw: {
          2: [
            'Unknown',
            DateTime(2027),
            0xE999,
            0xFF7877E6,
            null,
            'Default',
            true,
            false,
          ],
          3: [
            'Ac unit',
            DateTime(2027),
            Icons.ac_unit.codePoint,
            0xFF7877E6,
            null,
            'Default',
            true,
            false,
          ],
        },
      );
      await migrate(box);
      expect((await only('No icon')).iconSlug, isNull);
      expect((await only('Unknown')).iconSlug, 'calendar');
      expect((await only('Ac unit')).iconSlug, 'calendar');
    });
  });

  group('colours and gradients', () {
    test('custom colours are kept exactly, never snapped', () async {
      const colours = [
        0xFF123456,
        0xFF000000,
        0xFFFFFFFF,
        0xFF7877E7, // one off Lavender
        0x80FE607C, // with transparency
      ];
      final box = await hive({
        for (final (i, argb) in colours.indexed)
          i: Event(
            title: 'c$i',
            eventDateTime: DateTime(2027),
            backgroundColor: Color(argb),
          ),
      });
      await migrate(box);
      for (final (i, argb) in colours.indexed) {
        expect((await only('c$i')).colorArgb, argb);
      }
      expect(isPaletteColor(0xFF7877E7), isFalse);
    });

    test('gradient on maps to legacy/diagonalDown, off to none', () async {
      final box = await hive({
        1: Event(
          title: 'On',
          eventDateTime: DateTime(2027),
          backgroundColor: const Color(0xFFFE7228),
          backgroundGradient: true,
        ),
        2: Event(title: 'Off', eventDateTime: DateTime(2027)),
      });
      await migrate(box);
      final on = await only('On');
      expect(on.gradientId, legacyGradientId);
      expect(on.gradientDirection, GradientDirection.diagonalDown);
      expect(on.gradient, legacyGradientColors(const Color(0xFFFE7228)));
      final off = await only('Off');
      expect(off.gradientId, isNull);
      expect(off.gradientDirection, isNull);
      expect(off.gradient, isNull);
    });
  });

  group('dates', () {
    test('all-day and timed events keep their date, time and flag', () async {
      final box = await hive({
        1: Event(title: 'All day', eventDateTime: DateTime(2027, 2, 3, 15, 45)),
        2: Event(
          title: 'Timed',
          eventDateTime: DateTime(2027, 2, 3, 15, 45),
          allDayEvent: false,
        ),
      });
      await migrate(box);
      final allDay = await only('All day');
      expect(allDay.allDay, isTrue);
      expect(allDay.dateTime, DateTime(2027, 2, 3, 15, 45));
      expect(allDay.target, DateTime(2027, 2, 3));
      final timed = await only('Timed');
      expect(timed.allDay, isFalse);
      expect(timed.target, DateTime(2027, 2, 3, 15, 45));
    });

    test('past events copy and land in Done', () async {
      final box = await hive({
        1: Event(title: 'Past', eventDateTime: DateTime(2026, 8, 2)),
        2: Event(
          title: 'Earlier today',
          eventDateTime: DateTime(2026, 11, 21, 9),
          allDayEvent: false,
        ),
      });
      await migrate(box);
      expect((await only('Past')).isDone(now), isTrue);
      expect((await only('Earlier today')).isDone(now), isTrue);
    });
  });

  group('reminders', () {
    test(
      'notify on gives each future event one reminder at the time',
      () async {
        final box = await hive({
          1: Event(title: 'Future', eventDateTime: DateTime(2027)),
          2: Event(title: 'Past', eventDateTime: DateTime(2026, 8, 2)),
          3: Event(
            title: 'Later today',
            eventDateTime: DateTime(2026, 11, 21, 18),
            allDayEvent: false,
          ),
        });
        await migrate(box, notify: true);
        expect((await only('Future')).reminders, [0]);
        expect((await only('Later today')).reminders, [0]);
        expect((await only('Past')).reminders, isEmpty);
        expect(await db.allReminders(), hasLength(2));
      },
    );

    test('notify off gives no reminders', () async {
      final box = await hive({
        1: Event(title: 'Future', eventDateTime: DateTime(2027)),
      });
      await migrate(box);
      expect((await only('Future')).reminders, isEmpty);
      expect(await db.allReminders(), isEmpty);
    });
  });

  group('empty, missing and repeated', () {
    test('an empty box copies nothing and is marked done', () async {
      final box = await hive({});
      expect(await migrate(box), MigrationOutcome.nothingToCopy);
      expect(prefs.getBool(driftMigratedKey), isTrue);
      expect(await db.allCountdowns(), isEmpty);
    });

    test('a missing box copies nothing and is marked done', () async {
      expect(await migrate(null), MigrationOutcome.nothingToCopy);
      expect(prefs.getBool(driftMigratedKey), isTrue);
      expect(await db.allCountdowns(), isEmpty);
    });

    test('running the copy twice never duplicates', () async {
      final box = await hive({
        for (var i = 0; i < 5; i++)
          i: Event(title: 'e$i', eventDateTime: DateTime(2027, 1, i + 1)),
      });
      expect(await migrate(box, notify: true), MigrationOutcome.copied);
      expect(await migrate(box, notify: true), MigrationOutcome.alreadyDone);
      // Even with the flag lost, legacyHiveKey stops duplicates.
      await prefs.remove(driftMigratedKey);
      expect(await migrate(box, notify: true), MigrationOutcome.copied);
      expect(await db.allCountdowns(), hasLength(5));
      expect(await db.allReminders(), hasLength(5));
    });

    test('a new Hive event after a lost flag is the only one added', () async {
      var box = await hive({
        1: Event(title: 'First', eventDateTime: DateTime(2027)),
      });
      await migrate(box);
      await prefs.remove(driftMigratedKey);
      await box.put(2, Event(title: 'Second', eventDateTime: DateTime(2027)));
      await migrate(box);
      final titles = (await db.allCountdowns()).map((c) => c.title).toList()
        ..sort();
      expect(titles, ['First', 'Second']);
    });
  });

  group('failure part-way', () {
    test(
      'rolls back and leaves the Hive file byte-for-byte unchanged',
      () async {
        var box = await hive({
          for (var i = 0; i < 6; i++)
            i: Event(
              title: 'e$i',
              eventDateTime: DateTime(2027, 1, i + 1),
              backgroundColor: Color(0xFF000000 + i),
            ),
        });
        await box.close();
        final file = File('${dir.path}/events.hive');
        final before = await file.readAsBytes();
        box = await Hive.openBox<Event>(
          'events',
          compactionStrategy: (_, _) => false,
        );

        for (final failAt in [0, 3, 5]) {
          final outcome = await migrate(
            box,
            notify: true,
            beforeInsert: (i) {
              if (i == failAt) throw const FileSystemException('disk full');
            },
          );
          expect(outcome, MigrationOutcome.failed, reason: 'fail at $failAt');
          expect(prefs.getBool(driftMigratedKey), isNull);
          expect(await db.allCountdowns(), isEmpty, reason: 'fail at $failAt');
          expect(await db.allReminders(), isEmpty);
        }

        await box.close();
        expect(await file.readAsBytes(), before);

        // The next launch succeeds, and still leaves Hive as it was.
        box = await Hive.openBox<Event>(
          'events',
          compactionStrategy: (_, _) => false,
        );
        expect(box.length, 6);
        expect(await migrate(box), MigrationOutcome.copied);
        expect(await db.allCountdowns(), hasLength(6));
        await box.close();
        expect(await file.readAsBytes(), before);
      },
    );
  });

  group('v1 JSON import', () {
    Future<void> writeV1(Object events, {Object? settings}) async {
      await File('${dir.path}/countdownevents.json')
          .writeAsString(jsonEncode(events));
      if (settings != null) {
        await File('${dir.path}/settings.json')
            .writeAsString(jsonEncode(settings));
      }
    }

    test('goes straight into Drift with every field', () async {
      await writeV1(
        [
          {
            'title': 'Anniversary',
            'eventDate': '2031-01-01T00:00:00.000',
            'backgroundColor': 0xff123456,
            'icon': Icons.favorite.codePoint,
            'fontFamily': 'ComicNeue',
            'contentColor': 0xffffffff,
          },
          {'title': 'Bare', 'eventDate': '2030-06-01'},
          {'title': 'Old', 'eventDate': '2020-01-01'},
        ],
        settings: {'notify': true, 'themeMode': 2},
      );
      await importLegacyData(dir, db, prefs, now: now);
      final a = await only('Anniversary');
      expect(a.dateTime, DateTime(2031));
      expect(a.iconSlug, 'heart');
      expect(a.colorArgb, 0xff123456);
      expect(a.fontFamily, 'ComicNeue');
      expect(a.allDay, isTrue);
      expect(a.reminders, [0]);
      final bare = await only('Bare');
      expect(bare.iconSlug, isNull);
      expect(bare.colorArgb, 0xFF7877E6);
      expect(bare.fontFamily, 'Default');
      expect((await only('Old')).reminders, isEmpty);
      expect(prefs.getBool('legacyEventsImported'), isTrue);
    });

    test('runs once, even if interrupted before its flag is saved', () async {
      await writeV1([
        {'title': 'Once', 'eventDate': '2030-01-01'},
      ]);
      await importLegacyData(dir, db, prefs, now: now);
      await prefs.remove('legacyEventsImported');
      await importLegacyData(dir, db, prefs, now: now);
      expect(await db.allCountdowns(), hasLength(1));
    });

    test(
      'is skipped if an earlier build already imported it to Hive',
      () async {
        await writeV1([
          {'title': 'Already in Hive', 'eventDate': '2030-01-01'},
        ]);
        await prefs.setBool('legacyEventsImported', true);
        await importLegacyData(dir, db, prefs, now: now);
        expect(await db.allCountdowns(), isEmpty);
      },
    );

    test('missing or broken files are ignored', () async {
      await importLegacyData(dir, db, prefs, now: now);
      expect(await db.allCountdowns(), isEmpty);
      await File('${dir.path}/countdownevents.json').writeAsString('{oops');
      await importLegacyData(dir, db, prefs, now: now);
      expect(await db.allCountdowns(), isEmpty);
      expect(prefs.getBool('legacyEventsImported'), isNull);
    });
  });

  group('settings', () {
    const stored = {
      'themeMode': 2,
      'sortingMethod': 'SortingMethod.dateDescending',
      'hapticFeedback': false,
      'soundEffects': true,
      'squareView': false,
      'notify': true,
      'iconName': 'crayon',
      'aKeyFromTheFuture': {'nested': 1},
    };

    test('every existing key is read and written back unchanged', () {
      final out = LocalSettings.fromJson(jsonDecode(jsonEncode(stored)))
          .copyWith(defaultUnit: CountUnit.sleeps, keepDone: false)
          .toJson();
      for (final e in stored.entries) {
        expect(out[e.key], e.value, reason: e.key);
      }
      expect(out['defaultUnit'], 'sleeps');
      expect(out['keepDone'], false);
      expect(out['defaultReminders'], [0]);
    });

    test('the copy never rewrites the stored settings', () async {
      final json = jsonEncode(stored);
      await prefs.setString('localSettings', json);
      final box = await hive({
        1: Event(title: 'x', eventDateTime: DateTime(2027)),
      });
      await migrate(box, notify: true);
      expect(prefs.getString('localSettings'), json);
    });

    test('v1 settings.json fills in settings only when none exist', () async {
      await File('${dir.path}/settings.json')
          .writeAsString(jsonEncode({'themeMode': 1, 'squareView': false}));
      await prefs.setString('localSettings', jsonEncode(stored));
      await importLegacyData(dir, db, prefs, now: now);
      expect(jsonDecode(prefs.getString('localSettings')!), stored);
    });
  });
}
