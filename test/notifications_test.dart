import 'package:countdowns/models/countdown.dart';
import 'package:countdowns/providers/notification_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

// Wall-clock expectations hold in any time zone. Run with
// TZ=America/New_York to exercise the daylight-saving cases for real.
void main() {
  final now = DateTime(2026, 11, 21, 12);
  final trip = Countdown(
    id: 1,
    title: 'Japan trip',
    dateTime: DateTime(2027, 3, 14, 9, 30),
    allDay: false,
  );
  final birthday = Countdown(
    id: 2,
    title: 'Mia’s birthday',
    dateTime: DateTime(2020, 2, 3),
    repeat: RepeatRule.yearly,
  );
  final past = Countdown(
    id: 3,
    title: 'Moved in',
    dateTime: DateTime(2026, 8, 2),
  );

  /// Plans [offsets] for [event] at [at], one reminder id per offset.
  List<NotificationRequest> plan(
    Countdown event,
    List<int> offsets, {
    DateTime? at,
  }) => planNotifications(
    [event],
    [
      for (final (i, o) in offsets.indexed)
        (id: 100 + i, eventId: event.id!, offsetMinutes: o),
    ],
    at ?? now,
  );

  group('one-off events', () {
    test('get one-shot notifications, never daily', () {
      final p = plan(trip, [0, 10080]);
      expect(p, hasLength(2));
      expect(p.every((r) => r.match == null), isTrue);
      expect(p.first.id, 101);
      expect(p.first.when, DateTime(2027, 3, 7, 9, 30));
      expect(p.first.body, 'One week to go');
      expect(p.last.id, 100);
      expect(p.last.when, DateTime(2027, 3, 14, 9, 30));
      expect(p.last.body, 'It’s happening now!');
    });

    test('whole days keep the time of day across a DST change', () {
      // US clocks go forward on 14 March 2027, Europe's on 28 March.
      final p = plan(trip, [1440, 20160]);
      expect(p.map((r) => (r.when.hour, r.when.minute)), [(9, 30), (9, 30)]);
      expect(p.first.when.day, 28);
      expect(p.last.when.day, 13);
    });

    test('hours before are elapsed time', () {
      final p = plan(trip, [60]);
      expect(p.single.when, DateTime(2027, 3, 14, 9, 30).subtract(_hour));
      expect(p.single.body, 'In one hour');
    });

    test('all-day reminders go off at 9 AM', () {
      final party = Countdown(
        id: 4,
        title: 'Party',
        dateTime: DateTime(2026, 12, 31),
      );
      final p = plan(party, [0, 1440, 2880]);
      expect(p.map((r) => r.when), [
        DateTime(2026, 12, 29, allDayReminderHour),
        DateTime(2026, 12, 30, allDayReminderHour),
        DateTime(2026, 12, 31, allDayReminderHour),
      ]);
      expect(p.map((r) => r.body), [
        '2 days to go',
        'Tomorrow!',
        'It’s today!',
      ]);
    });

    test('an all-day event today after 9 AM gets nothing', () {
      final today = Countdown(
        id: 5,
        title: 'Today',
        dateTime: DateTime(2026, 11, 21),
      );
      expect(plan(today, [0]), isEmpty);
      expect(plan(today, [0], at: DateTime(2026, 11, 21, 8)), hasLength(1));
    });

    test('past events and passed reminders are skipped', () {
      final p = planNotifications(
        [past, trip],
        [
          (id: 30, eventId: 3, offsetMinutes: 0),
          // 200 days before the trip is already behind us.
          (id: 31, eventId: 1, offsetMinutes: 200 * 1440),
          // A reminder whose countdown is gone.
          (id: 32, eventId: 99, offsetMinutes: 0),
        ],
        now,
      );
      expect(p, isEmpty);
    });
  });

  group('yearly events', () {
    test('repeat on date and time', () {
      final p = plan(birthday, [1440]);
      expect(p.single.match, DateTimeComponents.dateAndTime);
      expect(p.single.when, DateTime(2027, 2, 2, allDayReminderHour));
      expect(p.single.body, 'Tomorrow!');
    });

    test('a reminder that passed this year starts next year', () {
      // The birthday is in 5 days; 30 days before was last month.
      final p = plan(birthday, [43200, 0], at: DateTime(2027, 1, 29, 12));
      expect(p.map((r) => r.when), [
        DateTime(2027, 2, 3, allDayReminderHour),
        DateTime(2028, 1, 4, allDayReminderHour),
      ]);
      expect(p.every((r) => r.match == DateTimeComponents.dateAndTime), isTrue);
    });

    test('a first date more than a year away goes one at a time', () {
      // iOS would fire a repeating reminder at the next 1 June, a year early.
      final wedding = Countdown(
        id: 6,
        title: 'Wedding',
        dateTime: DateTime(2028, 6, 1, 15),
        allDay: false,
        repeat: RepeatRule.yearly,
      );
      expect(plan(wedding, [0]).single.match, isNull);
      expect(
        plan(wedding, [0], at: DateTime(2027, 6, 2)).single.match,
        DateTimeComponents.dateAndTime,
      );
    });

    test('Feb 29 goes one at a time, on Feb 28 in other years', () {
      final leapling = Countdown(
        id: 7,
        title: 'Leap day',
        dateTime: DateTime(2024, 2, 29),
        repeat: RepeatRule.yearly,
      );
      final p = plan(leapling, [0]);
      expect(p.single.when, DateTime(2027, 2, 28, allDayReminderHour));
      expect(p.single.match, isNull);
      final leap = plan(leapling, [0], at: DateTime(2027, 3, 1));
      expect(leap.single.when, DateTime(2028, 2, 29, allDayReminderHour));
      expect(leap.single.match, isNull);
    });

    test('a reminder counting back across Feb 29 goes one at a time', () {
      final march = Countdown(
        id: 8,
        title: 'Spring',
        dateTime: DateTime(2020, 3, 1),
        repeat: RepeatRule.yearly,
      );
      final p = plan(march, [1440, 0]);
      // 1 day before is Feb 28 in 2027 but Feb 29 in 2028.
      expect(p.first.when, DateTime(2027, 2, 28, allDayReminderHour));
      expect(p.first.match, isNull);
      expect(p.last.match, DateTimeComponents.dateAndTime);
    });
  });

  test('keeps the soonest within the iOS pending limit', () {
    final events = [
      for (var i = 0; i < 80; i++)
        Countdown(id: i + 1, title: '$i', dateTime: DateTime(2027, 1, 1 + i)),
    ];
    final p = planNotifications(events, [
      for (final e in events.reversed)
        (id: e.id!, eventId: e.id!, offsetMinutes: 0),
    ], now);
    expect(p, hasLength(maxPendingNotifications));
    expect(p.first.when, DateTime(2027, 1, 1, allDayReminderHour));
    expect(p.last.when, DateTime(2027, 1, maxPendingNotifications, 9));
  });

  group('platform calls', () {
    late List<MethodCall> calls;
    var exactAllowed = true;

    setUp(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      tzdata.initializeTimeZones();
      calls = [];
      exactAllowed = true;
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(
        const MethodChannel('dexterous.com/flutter/local_notifications'),
        (call) async {
          calls.add(call);
          return call.method == 'canScheduleExactNotifications'
              ? exactAllowed
              : null;
        },
      );
      messenger.setMockMethodCallHandler(
        const MethodChannel('flutter_timezone'),
        (call) async => 'Europe/London',
      );
    });

    tearDown(() => debugDefaultTargetPlatformOverride = null);

    List<Map> scheduled() => [
      for (final c in calls)
        if (c.method == 'zonedSchedule') c.arguments as Map,
    ];

    test('iOS gets one-shot and yearly arguments', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      FlutterLocalNotificationsPlatform.instance =
          IOSFlutterLocalNotificationsPlugin();
      final requests = planNotifications(
        [trip, birthday],
        [
          (id: 10, eventId: 1, offsetMinutes: 0),
          (id: 20, eventId: 2, offsetMinutes: 0),
        ],
        DateTime.now(),
      );
      for (final r in requests) {
        await EventNotifications().schedule(r, tz.UTC);
      }
      final yearly = scheduled().firstWhere((c) => c['id'] == 20);
      final oneOff = scheduled().firstWhere((c) => c['id'] == 10);
      expect(
        yearly['matchDateTimeComponents'],
        DateTimeComponents.dateAndTime.index,
      );
      expect(oneOff['matchDateTimeComponents'], isNull);
      expect(oneOff['title'], 'Japan trip');
    }, skip: trip.target.isBefore(DateTime.now()));

    test('replaceAll keeps delivered notifications and survives a bad '
        'request', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      FlutterLocalNotificationsPlatform.instance =
          AndroidFlutterLocalNotificationsPlugin();
      final errors = <FlutterErrorDetails>[];
      final onError = FlutterError.onError;
      FlutterError.onError = errors.add;
      addTearDown(() => FlutterError.onError = onError);
      final soon = DateTime.now().add(const Duration(days: 1));
      await EventNotifications().replaceAll([
        NotificationRequest(id: 1, title: 'A', body: '', when: soon),
        // Passed while the plan was being made: the plugin rejects it.
        NotificationRequest(
          id: 2,
          title: 'B',
          body: '',
          when: DateTime.now().subtract(_hour),
        ),
        NotificationRequest(id: 3, title: 'C', body: '', when: soon),
      ]);
      expect(calls.first.method, 'cancelAllPendingNotifications');
      expect(calls.map((c) => c.method), isNot(contains('cancelAll')));
      expect(scheduled().map((c) => c['id']), [1, 3]);
      expect(errors.single.exception, isArgumentError);
      expect(scheduled().map((c) => c['timeZoneName']).toSet(), {
        'Europe/London',
      });
      expect(
        (scheduled().first['platformSpecifics'] as Map)['scheduleMode'],
        AndroidScheduleMode.exactAllowWhileIdle.name,
      );
    });

    test(
      'Android falls back to inexact alarms without the permission',
      () async {
        debugDefaultTargetPlatformOverride = TargetPlatform.android;
        FlutterLocalNotificationsPlatform.instance =
            AndroidFlutterLocalNotificationsPlugin();
        exactAllowed = false;
        await EventNotifications().replaceAll([
          NotificationRequest(
            id: 1,
            title: 'A',
            body: '',
            when: DateTime.now().add(const Duration(days: 1)),
          ),
        ]);
        expect(
          (scheduled().single['platformSpecifics'] as Map)['scheduleMode'],
          AndroidScheduleMode.inexactAllowWhileIdle.name,
        );
      },
    );
  });
}

const _hour = Duration(hours: 1);
