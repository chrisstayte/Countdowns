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

  Event({
    required this.title,
    required this.eventDate,
    this.icon,
    this.backgroundColor,
    this.fontFamily,
    this.contentColor,
  });
}
