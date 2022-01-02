import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class CountdownEvent {
  String title;
  DateTime eventDate;
  IconData? icon;
  Color? color;

  CountdownEvent(
      {required this.title, required this.eventDate, this.icon, this.color});

  factory CountdownEvent.fromJson(Map<String, dynamic> json) {
    String title = json['title'] as String;
    DateTime eventDate = DateTime.parse(json['eventDate']);
    IconData? icon;
    if (json['icon'] != null) {
      icon = IconData(json['icon'], fontFamily: 'MaterialIcons');
    }

    Color? color;
    if (json['color'] != null) {
      color = Color(json['color']).withOpacity(1);
    }

    return CountdownEvent(
      title: title,
      eventDate: eventDate,
      icon: icon,
      color: color,
    );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'eventDate': eventDate.toString(),
        'icon': icon?.codePoint,
        'color': color?.value,
      };
}
