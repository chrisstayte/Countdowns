import 'package:flutter/material.dart';

class CountdownEvent {
  String title;
  DateTime eventDate;
  IconData? icon;
  Color? color;

  CountdownEvent(
      {required this.title, required this.eventDate, this.icon, this.color});

  CountdownEvent.fromJson(Map<String, dynamic> json)
      : title = json['title'] as String,
        eventDate = json['eventDate'] as DateTime,
        icon = json['icon'] as IconData?,
        color = json['color'] as Color?;

  Map<String, dynamic> toJson() =>
      {'title': title, 'eventDate': eventDate, 'icon': icon, 'color': color};
}
