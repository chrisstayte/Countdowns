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

  /// The first time it goes off, in local time.
  final DateTime when;

  /// Null for one-shot notifications. Yearly reminders use
  /// [DateTimeComponents.dateAndTime]. Never [DateTimeComponents.time], which
  /// repeats every day.
  final DateTimeComponents? match;

  @override
  String toString() => 'NotificationRequest($id, $title, $when, $match)';
}

/// A reminder row: its id and the minutes before the event.
typedef ReminderSlot = ({int id, int eventId, int offsetMinutes});

/// Works out which notifications to schedule, soonest first, capped at
/// [maxPendingNotifications]. Pure, so it can be tested.
List<NotificationRequest> planNotifications(
  List<Countdown> events,
  List<ReminderSlot> reminders,
  DateTime now,
) {
  final byId = {
    for (final e in events)
      if (e.id != null) e.id!: e,
  };
  final requests = [
    for (final slot in reminders)
      if (byId[slot.eventId] case final event?) ?_plan(event, slot, now),
  ]..sort((a, b) => a.when.compareTo(b.when));
  return requests.take(maxPendingNotifications).toList();
}

NotificationRequest? _plan(Countdown event, ReminderSlot slot, DateTime now) {
  final offset = slot.offsetMinutes;
  var occurrence = event.nextOccurrence(now);
  var when = _reminderTime(event, occurrence, offset);
  DateTimeComponents? match;
  if (event.repeat == RepeatRule.yearly) {
    // This year's reminder has passed: aim at next year's.
    if (!when.isAfter(now)) {
      occurrence = _followingYear(event, occurrence);
      when = _reminderTime(event, occurrence, offset);
    }
    // iOS repeats on month, day and time alone and fires at the next match,
    // so only repeat when this reminder is the next match (less than a year
    // away) and next year's lands on the same date and time. Feb 29, and
    // reminders that count back across it, don't; they go one at a time and
    // are planned again each time the app opens.
    final next = _reminderTime(
      event,
      _followingYear(event, occurrence),
      offset,
    );
    final lastYear = DateTime(
      when.year - 1,
      when.month,
      when.day,
      when.hour,
      when.minute,
    );
    if (!lastYear.isAfter(now) && _sameDayAndTime(when, next)) {
      match = DateTimeComponents.dateAndTime;
    }
  }
  if (!when.isAfter(now)) return null;
  return NotificationRequest(
    id: slot.id,
    title: event.title,
    body: _body(event, offset),
    when: when,
    match: match,
  );
}

/// When a reminder [offset] minutes before [occurrence] goes off. Whole days
/// move by calendar day, so the time of day survives a daylight-saving change
/// in between; the rest is real elapsed time.
DateTime _reminderTime(Countdown event, DateTime occurrence, int offset) =>
    DateTime(
      occurrence.year,
      occurrence.month,
      occurrence.day - offset ~/ 1440,
      event.allDay ? allDayReminderHour : occurrence.hour,
      event.allDay ? 0 : occurrence.minute,
    ).subtract(Duration(minutes: offset % 1440));

/// The yearly occurrence after [occurrence], with Feb 29 handled.
DateTime _followingYear(Countdown event, DateTime occurrence) =>
    event.nextOccurrence(occurrence.add(const Duration(days: 1)));

bool _sameDayAndTime(DateTime a, DateTime b) =>
    a.month == b.month &&
    a.day == b.day &&
    a.hour == b.hour &&
    a.minute == b.minute;

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

  AndroidFlutterLocalNotificationsPlugin? get _android => plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  Future<void> initialize() async {
    if (!supported) return;
    tz.initializeTimeZones();
    await plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('ic_stat_countdowns'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
  }

  /// Asks to show notifications. True when they're allowed.
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
    final android = _android;
    if (await android?.requestNotificationsPermission() != true) return false;
    // Exact alarms keep reminders on the minute. Without them Android may
    // deliver up to an hour late, but they still arrive, so a refusal here
    // doesn't turn notifications off.
    await android?.requestExactAlarmsPermission();
    return true;
  }

  /// Removes pending and delivered notifications.
  Future<void> cancelAll() async {
    if (supported) await plugin.cancelAll();
  }

  /// Replaces every pending notification with [requests]. Delivered ones stay
  /// in the notification centre.
  Future<void> replaceAll(List<NotificationRequest> requests) async {
    if (!supported) return;
    await plugin.cancelAllPendingNotifications();
    if (requests.isEmpty) return;
    final zone = await _localZone();
    final mode = await _scheduleMode();
    for (final request in requests) {
      // One failure (say, a reminder that passed while planning) mustn't
      // drop the rest.
      try {
        await schedule(request, zone, mode);
      } catch (error, stack) {
        FlutterError.reportError(
          FlutterErrorDetails(
            exception: error,
            stack: stack,
            library: 'countdown notifications',
            context: ErrorDescription('scheduling $request'),
          ),
        );
      }
    }
  }

  Future<void> schedule(
    NotificationRequest request,
    tz.Location zone, [
    AndroidScheduleMode mode = AndroidScheduleMode.exactAllowWhileIdle,
  ]) => plugin.zonedSchedule(
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
    androidScheduleMode: mode,
    matchDateTimeComponents: request.match,
  );

  /// Exact alarms when Android allows them (they need a permission from
  /// Android 12, off by default from 14), inexact ones otherwise (Android
  /// gives those up to an hour's leeway). Both still fire in Doze.
  Future<AndroidScheduleMode> _scheduleMode() async =>
      await _android?.canScheduleExactNotifications() == false
      ? AndroidScheduleMode.inexactAllowWhileIdle
      : AndroidScheduleMode.exactAllowWhileIdle;

  /// The device's zone, so yearly repeats keep their local time.
  Future<tz.Location> _localZone() async {
    try {
      return tz.getLocation(
        (await FlutterTimezone.getLocalTimezone()).identifier,
      );
    } catch (_) {
      // An unknown zone name: the times still land on the right instant.
      return tz.UTC;
    }
  }
}
