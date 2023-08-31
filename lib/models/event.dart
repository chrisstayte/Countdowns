import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

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
}
