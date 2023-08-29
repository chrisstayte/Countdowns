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
  bool allDayEvent;

  Event({
    required this.title,
    required this.eventDate,
    required this.allDayEvent,
    this.icon,
    this.backgroundColor,
    this.contentColor,
    this.fontFamily,
  });

  Duration getTimeDifference() {
    DateTime now = DateTime.now();
    DateTime eventDate = allDayEvent
        ? DateTime(
            this.eventDate.year, this.eventDate.month, this.eventDate.day)
        : this.eventDate;
    Duration difference = eventDate.difference(now);
    return difference;
  }
}
