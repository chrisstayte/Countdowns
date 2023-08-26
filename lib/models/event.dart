import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

part 'event.g.dart';

@HiveType(typeId: 0)
class Event extends HiveObject {
  @HiveField(0)
  String title;

  @HiveField(1)
  DateTime eventDate;

  @HiveField(2)
  IconData? icon;

  @HiveField(3)
  Color? backgroundColor;

  @HiveField(4)
  Color? contentColor;

  @HiveField(5)
  String? fontFamily;

  @HiveField(6)
  bool? allDayEvent;

  Event({
    required this.title,
    required this.eventDate,
    this.icon,
    this.backgroundColor,
    this.fontFamily,
    this.contentColor,
    this.allDayEvent,
  });

  Duration getTimeDifference() {
    DateTime now = DateTime.now();
    DateTime eventDate = this.eventDate;
    DateTime eventDateWithoutTime = DateTime(
      eventDate.year,
      eventDate.month,
      eventDate.day,
    );
    DateTime nowWithoutTime = DateTime(
        now.year, now.month, now.day, now.hour, now.minute, now.second);
    Duration difference = eventDateWithoutTime.difference(nowWithoutTime);
    return difference;
  }
}
