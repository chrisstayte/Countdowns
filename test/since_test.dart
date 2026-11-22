import 'dart:io';

import 'package:countdowns/data/database.dart';
import 'package:countdowns/models/countdown.dart';
import 'package:countdowns/providers/home_provider.dart';
import 'package:countdowns/providers/notification_provider.dart';
import 'package:countdowns/screens/share/ics.dart';
import 'package:countdowns/utilities/count_format.dart';
import 'package:countdowns/utilities/milestones.dart';
import 'package:countdowns/widgets_bridge/widget_snapshot.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 11, 21, 12);
  // 100 days ago, all day.
  final quit = Countdown(
    id: 1,
    title: 'Quit smoking',
    dateTime: DateTime(2026, 8, 13),
    kind: EventKind.since,
  );
  final job = Countdown(
    id: 2,
    title: 'New job',
    dateTime: DateTime(2023, 6, 1, 9),
    allDay: false,
    kind: EventKind.since,
  );
  final trip = Countdown(
    id: 3,
    title: 'Japan trip',
    dateTime: DateTime(2027, 3, 14),
  );

  group('counting up', () {
    test('counts from the start in every unit', () {
      expect(countIn(quit, CountUnit.days, now), (big: '100', unit: 'days'));
      expect(countIn(quit, CountUnit.sleeps, now), (
        big: '100',
        unit: 'sleeps',
      ));
      // Real elapsed hours (one more where clocks went back in November).
      final hours = now.difference(DateTime(2026, 8, 13)).inHours;
      expect(
        countIn(quit, CountUnit.hours, now).big,
        '${hours ~/ 1000},${hours % 1000}',
      );
      expect(cardCount(quit, now), (big: '100', unit: 'days'));
      expect(countLabel(quit, cardCount(quit, now), now), 'days since');
      expect(quit.isDone(now), isFalse);
      expect(cardDate(quit, now), 'Since Aug 13');
      expect(cardDate(job, now), 'Since Jun 1, 2023');
      expect(longDate(quit, now), 'Since Thursday, August 13');
    });

    test('a year or more gets the years line, never "in N years"', () {
      expect(yearsLine(job, CountUnit.days, now), '3 years, 173 days');
      expect(cardYears(job, now), isNull);
      expect(longDate(job, now), 'Since Thursday, June 1, 2023 · 9:00 AM');
    });

    test('the first day says Started today, the first hours count hours', () {
      final today = quit.copyWith(dateTime: DateTime(2026, 11, 21));
      expect(cardCount(today, now), (big: 'Today', unit: ''));
      expect(countLabel(today, cardCount(today, now), now), 'Started today');
      final timed = job.copyWith(dateTime: DateTime(2026, 11, 21, 7, 30));
      expect(cardCount(timed, now), (big: '4', unit: 'hours'));
    });

    test('a start in the future counts zero instead of going negative', () {
      final ahead = job.copyWith(dateTime: DateTime(2026, 11, 22));
      expect(countIn(ahead, CountUnit.days, now).big, '0');
      expect(detailTiles(ahead, CountUnit.days, now).first.value, '00');
    });
  });

  group('milestones', () {
    test('day counts, six months and anniversaries, in order', () {
      final labels = sinceMilestones(quit).take(10).map((m) => m.label);
      expect(labels, [
        '1 day',
        '1 week',
        '30 days',
        '100 days',
        '6 months',
        '200 days',
        '300 days',
        '1 year',
        '500 days',
        '2 years',
      ]);
      expect(nextMilestone(quit, now), (
        at: DateTime(2027, 2, 13),
        label: '6 months',
      ));
      // 12 hours into the 84 days from 100 days to six months.
      expect(waitProgress(quit, now), 1);
      expect(upcomingMilestones(job, now).first, (
        at: DateTime(2027, 6, 1, 9),
        label: '4 years',
      ));
    });

    test('an anniversary wins a shared day, and Feb 29 lands on Feb 28', () {
      final leap = quit.copyWith(dateTime: DateTime(2024, 2, 29));
      final years = sinceMilestones(leap).where((m) => m.label.contains('yea'));
      expect(years.first.at, DateTime(2025, 2, 28));
      expect(years.elementAt(3).at, DateTime(2028, 2, 29));
      final newYear = quit.copyWith(dateTime: DateTime(2025, 1, 1));
      final onTheDay = sinceMilestones(newYear)
          .where((m) => m.at == DateTime(2026, 1, 1));
      expect(onTheDay.single.label, '1 year');
    });
  });

  group('reminders', () {
    List<NotificationRequest> plan(List<int> offsets, DateTime at) =>
        planNotifications(
          [quit],
          [
            for (final (i, o) in offsets.indexed)
              (id: 10 + i, eventId: 1, offsetMinutes: o),
          ],
          at,
        );

    test('remind before the next milestone, at 9 AM for all-day', () {
      final p = plan([0, 1440], now);
      expect(p.map((r) => (r.id, r.when, r.body)), [
        (11, DateTime(2027, 2, 12, 9), '6 months tomorrow'),
        (10, DateTime(2027, 2, 13, 9), '6 months today'),
      ]);
      expect(p.every((r) => r.match == null), isTrue);
    });

    test('a milestone at midnight still gets its 9 AM reminder', () {
      final p = plan([0], DateTime(2026, 11, 21, 8));
      expect(p.single.when, DateTime(2026, 11, 21, 9));
      expect(p.single.body, '100 days today');
    });
  });

  test('home lists Since apart, newest start first', () {
    final lists = splitEvents([job, trip, quit], now);
    expect(lists.upcoming, [trip]);
    expect(lists.since, [quit, job]);
    expect(lists.done, isEmpty);
  });

  test('widgets get Since after countdowns, with milestones', () {
    final events =
        buildWidgetSnapshot([quit, trip], now)['events']! as List<Object?>;
    expect(events.map((e) => (e! as Map)['id']), [3, 1]);
    final since = events.last! as Map;
    expect(since['since'], true);
    expect(
      since['target'],
      DateTime(2026, 8, 13).millisecondsSinceEpoch ~/ 1000,
    );
    final marks = since['milestones']! as List;
    // The last milestone passed, then the ones ahead.
    expect(marks.take(2), [
      DateTime(2026, 11, 21).millisecondsSinceEpoch ~/ 1000,
      DateTime(2027, 2, 13).millisecondsSinceEpoch ~/ 1000,
    ]);
    expect((events.first! as Map)['milestones'], isNull);
  });

  test('the calendar file repeats the start every year', () {
    final ics = buildIcs(quit, now: now);
    expect(ics, contains('DTSTART;VALUE=DATE:20260813'));
    expect(ics, contains('RRULE:FREQ=YEARLY'));
  });

  test('a schema 2 database upgrades with every countdown as Soon', () async {
    final dir = await Directory.systemTemp.createTemp('since-migration');
    addTearDown(() => dir.delete(recursive: true));
    final file = File('${dir.path}/countdowns.sqlite');

    // Make a schema 3 file, then turn it back into schema 2.
    final v3 = AppDatabase(NativeDatabase(file));
    await v3.saveCountdown(
      Countdown(
        title: 'Old',
        dateTime: DateTime(2027, 5, 1),
        artId: 'linen-oat',
        reminders: const [0, 1440],
      ),
    );
    await v3.customStatement('ALTER TABLE events DROP COLUMN kind');
    await v3.customStatement('PRAGMA user_version = 2');
    await v3.close();

    final db = AppDatabase(NativeDatabase(file));
    addTearDown(db.close);
    final old = (await db.allCountdowns()).single;
    expect(old.kind, EventKind.soon);
    expect(old.title, 'Old');
    expect(old.artId, 'linen-oat');
    expect(old.reminders, [0, 1440]);
    // And the new column round-trips.
    await db.saveCountdown(old.copyWith(kind: EventKind.since));
    expect((await db.allCountdowns()).single.kind, EventKind.since);
  });
}
