import 'package:countdowns/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:hive/hive.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

part 'event.g.dart';

@HiveType(typeId: 0)
class Event extends HiveObject {
  @HiveField(0)
  String title;

  @HiveField(1)
  DateTime eventDateTime;

  @HiveField(2)
  IconData? icon;

  @HiveField(3)
  Color backgroundColor;

  @HiveField(4)
  Color? contentColor;

  @HiveField(5)
  String fontFamily;

  @HiveField(6)
  bool allDayEvent;

  @HiveField(7)
  bool backgroundGradient;

  Event({
    required this.title,
    required this.eventDateTime,
    this.fontFamily = 'Default',
    this.allDayEvent = true,
    this.backgroundGradient = false,
    this.icon,
    this.backgroundColor = const Color(0Xff7877E6),
    this.contentColor,
  });

  Event copy() {
    return Event(
      title: title,
      eventDateTime: DateTime.fromMillisecondsSinceEpoch(
          eventDateTime.millisecondsSinceEpoch),
      allDayEvent: allDayEvent,
      icon: icon,
      backgroundColor: backgroundColor,
      contentColor: contentColor,
      fontFamily: fontFamily,
      backgroundGradient: backgroundGradient,
    );
  }

  void update(Event event) {
    title = event.title;
    eventDateTime = event.eventDateTime;
    allDayEvent = event.allDayEvent;
    icon = event.icon;
    backgroundColor = event.backgroundColor;
    contentColor = event.contentColor;
    fontFamily = event.fontFamily;
    backgroundGradient = event.backgroundGradient;
  }

  Duration getTimeDifference() {
    DateTime now = DateTime.now();
    DateTime eventDate = allDayEvent
        ? DateTime(eventDateTime.year, eventDateTime.month, eventDateTime.day)
        : eventDateTime;

    // print(eventDate);
    Duration difference = eventDate.difference(now);
    // print(difference);
    return difference;
  }

  bool isPast() {
    Duration difference = getTimeDifference();
    return difference.isNegative;
  }

  void cancelNotification() async {
    if (key != null) {
      await flutterLocalNotificationsPlugin.cancel(key);
    }
  }

  void scheduleNotification() async {
    if (isPast()) return;

    tz.initializeTimeZones();

    final String currentTimeZone = await FlutterTimezone.getLocalTimezone();

    tz.Location location = tz.getLocation(currentTimeZone);

    tz.TZDateTime eventDateTime = tz.TZDateTime.from(
      this.eventDateTime,
      location,
    );

    flutterLocalNotificationsPlugin.zonedSchedule(
      key,
      title,
      'Event is happening now!',
      eventDateTime,
      const NotificationDetails(
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
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      androidScheduleMode: AndroidScheduleMode.exact,
    );
  }

  void rescheduleNotification() async {
    cancelNotification();
    scheduleNotification();
  }
}
