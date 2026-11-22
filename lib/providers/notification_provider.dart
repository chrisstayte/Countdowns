import 'package:countdowns/models/event.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

final notificationsProvider = Provider((ref) => EventNotifications());

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

  Future<void> cancel(int id) async {
    if (supported) await plugin.cancel(id: id);
  }

  Future<void> cancelAll() async {
    if (supported) await plugin.cancelAll();
  }

  Future<void> schedule(int id, Event event) async {
    if (!supported || event.getTimeDifference().isNegative) return;
    final zone = await FlutterTimezone.getLocalTimezone();
    await plugin.zonedSchedule(
      id: id,
      title: event.title,
      body: 'Event is happening now!',
      scheduledDate: tz.TZDateTime.from(
        event.eventDateTime,
        tz.getLocation(zone.identifier),
      ),
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
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }
}
