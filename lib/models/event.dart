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
    Duration difference = eventDate.difference(now);
    return difference;
  }

  int getTimeDifferenceInYears() {
    Duration difference = getTimeDifference();
    int years = (difference.inDays / 365).floor();
    return years;
  }

  int getTimeDifferenceInDays({bool includeAllTime = false}) {
    Duration difference = getTimeDifference();
    int days = difference.inDays;
    return includeAllTime ? days : days % 365;
  }

  int getTimeDifferenceInHours({bool includeAllTime = false}) {
    Duration difference = getTimeDifference();
    int hours = difference.inHours;
    return includeAllTime ? hours : hours % 24;
  }

  int getTimeDifferenceInMinutes({bool includeAllTime = false}) {
    Duration difference = getTimeDifference();
    int minutes = difference.inMinutes;
    return includeAllTime ? minutes : minutes % 60;
  }

  int getTimeDifferenceInSeconds({bool includeAllTime = false}) {
    Duration difference = getTimeDifference();
    int seconds = difference.inSeconds;
    return includeAllTime ? seconds : seconds % 60;
  }

  bool isPast() {
    Duration difference = getTimeDifference();
    return difference.isNegative;
  }
}
