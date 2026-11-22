import 'package:countdowns/models/countdown.dart';
import 'package:countdowns/providers/notification_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

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

  test('one-off events get one-shot notifications, never daily', () {
    final plan = planNotifications(
      [trip],
      [
        (id: 10, eventId: 1, offsetMinutes: 0),
        (id: 11, eventId: 1, offsetMinutes: 10080),
      ],
      now,
    );
    expect(plan, hasLength(2));
    expect(plan.every((r) => r.match == null), isTrue);
    expect(plan.first.id, 11);
    expect(plan.first.when, DateTime(2027, 3, 7, 9, 30));
    expect(plan.first.body, 'One week to go');
    expect(plan.last.id, 10);
    expect(plan.last.when, DateTime(2027, 3, 14, 9, 30));
  });

  test('yearly events repeat on date and time; all-day fires at 9 AM', () {
    final plan = planNotifications(
      [birthday],
      [(id: 20, eventId: 2, offsetMinutes: 1440)],
      now,
    );
    expect(plan.single.match, DateTimeComponents.dateAndTime);
    expect(plan.single.when, DateTime(2027, 2, 2, allDayReminderHour));
    expect(plan.single.body, 'Tomorrow!');
  });

  test('past events and passed reminders are skipped', () {
    final plan = planNotifications(
      [past, trip],
      [
        (id: 30, eventId: 3, offsetMinutes: 0),
        // 200 days before the trip is already behind us.
        (id: 31, eventId: 1, offsetMinutes: 200 * 1440),
      ],
      now,
    );
    expect(plan, isEmpty);
  });

  test('keeps the soonest within the iOS pending limit', () {
    final events = [
      for (var i = 0; i < 80; i++)
        Countdown(id: i + 1, title: '$i', dateTime: DateTime(2027, 1, 1 + i)),
    ];
    final plan = planNotifications(events, [
      for (final e in events) (id: e.id!, eventId: e.id!, offsetMinutes: 0),
    ], now);
    expect(plan, hasLength(maxPendingNotifications));
    expect(plan.last.when, DateTime(2027, 1, maxPendingNotifications, 9));
  });

  test('schedule hands the plugin one-shot and yearly arguments', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    tzdata.initializeTimeZones();
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    FlutterLocalNotificationsPlatform.instance =
        IOSFlutterLocalNotificationsPlugin();
    final calls = <Map>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('dexterous.com/flutter/local_notifications'),
          (call) async {
            if (call.method == 'zonedSchedule')
              calls.add(call.arguments as Map);
            return null;
          },
        );
    final notifications = EventNotifications();
    final requests = planNotifications(
      [trip, birthday],
      [
        (id: 10, eventId: 1, offsetMinutes: 0),
        (id: 20, eventId: 2, offsetMinutes: 0),
      ],
      now,
    );
    for (final r in requests) {
      await notifications.schedule(r, tz.UTC);
    }
    expect(calls, hasLength(2));
    final yearly = calls.firstWhere((c) => c['id'] == 20);
    final oneOff = calls.firstWhere((c) => c['id'] == 10);
    expect(
      yearly['matchDateTimeComponents'],
      DateTimeComponents.dateAndTime.index,
    );
    expect(
      oneOff.containsKey('matchDateTimeComponents') &&
          oneOff['matchDateTimeComponents'] != null,
      isFalse,
    );
    expect(oneOff['title'], 'Japan trip');
  });
}
