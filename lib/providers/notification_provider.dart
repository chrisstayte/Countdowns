import 'package:countdowns/models/countdown.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

final notificationsProvider = Provider((ref) => EventNotifications());

/// iOS keeps only the 64 soonest pending notifications.
const maxPendingNotifications = 60;

/// All-day events have no time, so their reminders go off at 9 AM.
const allDayReminderHour = 9;

/// Reminder offsets the editor offers, in minutes before the event.
const reminderChoices = <int, String>{
  0: 'On the day',
  60: '1 hour before',
  1440: '1 day before',
  2880: '2 days before',
  10080: '1 week before',
  20160: '2 weeks before',
  43200: '30 days before',
};

String reminderLabel(int offset) =>
    reminderChoices[offset] ?? '${offset ~/ 60} hours before';

/// One notification to hand to the platform.
@immutable
class NotificationRequest {
  const NotificationRequest({
    required this.id,
    required this.title,
    required this.body,
    required this.when,
    this.match,
  });

  /// The reminder's id.
  final int id;
  final String title;
  final String body;
  final DateTime when;

  /// Null for one-shot notifications. Yearly events use
  /// [DateTimeComponents.dateAndTime]. Never [DateTimeComponents.time], which
  /// repeats every day.
  final DateTimeComponents? match;

  @override
  String toString() => 'NotificationRequest($id, $title, $when, $match)';
}

/// A reminder row: its id and the minutes before the event.
typedef ReminderSlot = ({int id, int eventId, int offsetMinutes});

/// Works out which notifications to schedule. Pure, so it can be tested.
List<NotificationRequest> planNotifications(
  List<Countdown> events,
  List<ReminderSlot> reminders,
  DateTime now,
) {
  final byId = {
    for (final e in events)
      if (e.id != null) e.id!: e,
  };
  final requests = <NotificationRequest>[];
  for (final slot in reminders) {
    final event = byId[slot.eventId];
    if (event == null) continue;
    final yearly = event.repeat == RepeatRule.yearly;
    var occurrence = event.nextOccurrence(now);
    DateTime fireTime(DateTime occ) {
      final base = event.allDay
          ? DateTime(occ.year, occ.month, occ.day, allDayReminderHour)
          : occ;
      // Whole days move by calendar day so the wall-clock time survives a
      // daylight-saving change in between.
      final days = slot.offsetMinutes ~/ 1440;
      final minutes = slot.offsetMinutes % 1440;
      return DateTime(
        base.year,
        base.month,
        base.day - days,
        base.hour,
        base.minute - minutes,
      );
    }

    var when = fireTime(occurrence);
    if (yearly && !when.isAfter(now)) {
      // This year's reminder has passed; the platform repeats it next year
      // anyway, but give it the next year's date as its first fire time.
      occurrence = DateTime(
        occurrence.year + 1,
        occurrence.month,
        occurrence.day,
        occurrence.hour,
        occurrence.minute,
      );
      when = fireTime(occurrence);
    }
    if (!when.isAfter(now)) continue;
    requests.add(
      NotificationRequest(
        id: slot.id,
        title: event.title,
        body: _body(event, slot.offsetMinutes),
        when: when,
        match: yearly ? DateTimeComponents.dateAndTime : null,
      ),
    );
  }
  requests.sort((a, b) => a.when.compareTo(b.when));
  return requests.take(maxPendingNotifications).toList();
}

String _body(Countdown event, int offset) {
  if (offset == 0) return event.allDay ? 'It’s today!' : 'It’s happening now!';
  if (offset == 1440) return 'Tomorrow!';
  if (offset % 10080 == 0) {
    final weeks = offset ~/ 10080;
    return weeks == 1 ? 'One week to go' : '$weeks weeks to go';
  }
  if (offset % 1440 == 0) return '${offset ~/ 1440} days to go';
  final hours = offset ~/ 60;
  return hours == 1 ? 'In one hour' : 'In $hours hours';
}

class EventNotifications {
  final plugin = FlutterLocalNotificationsPlugin();
  bool get supported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.android);

  Future<void> initialize() async {
    if (!supported) return;
    await plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/countdowns'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
    tz.initializeTimeZones();
  }

  Future<bool> requestPermission() async {
    if (!supported) return false;
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return await plugin
              .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin
              >()
              ?.requestPermissions(alert: true, badge: true, sound: true) ??
          false;
    }
    final android = plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    return await android?.requestNotificationsPermission() == true &&
        await android?.requestExactAlarmsPermission() == true;
  }

  Future<void> cancelAll() async {
    if (supported) await plugin.cancelAll();
  }

  /// Replaces every pending notification with [requests].
  Future<void> replaceAll(List<NotificationRequest> requests) async {
    if (!supported) return;
    await plugin.cancelAll();
    if (requests.isEmpty) return;
    final zone = tz.getLocation(
      (await FlutterTimezone.getLocalTimezone()).identifier,
    );
    for (final request in requests) {
      await schedule(request, zone);
    }
  }

  Future<void> schedule(NotificationRequest request, tz.Location zone) =>
      plugin.zonedSchedule(
        id: request.id,
        title: request.title,
        body: request.body,
        scheduledDate: tz.TZDateTime.from(request.when, zone),
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'event_notification',
            'Event Notification',
            importance: Importance.max,
            priority: Priority.max,
            showWhen: true,
            enableVibration: true,
            styleInformation: BigTextStyleInformation(''),
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exact,
        matchDateTimeComponents: request.match,
      );
}
