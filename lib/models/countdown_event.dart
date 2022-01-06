import 'package:flutter/material.dart';

class CountdownEvent {
  String title;
  DateTime eventDate;
  IconData? icon;
  Color? color;
  Color? contentColor;
  String? fontFamily;

  CountdownEvent(
      {required this.title,
      required this.eventDate,
      this.icon,
      this.color,
      this.fontFamily,
      this.contentColor});

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

    String? fontFamily = json['fontFamily'];

    Color? contentColor;
    if (json['contentColor'] != null) {
      contentColor = Color(json['contentColor']).withOpacity(1);
    }
    ;
    return CountdownEvent(
      title: title,
      eventDate: eventDate,
      icon: icon,
      color: color,
      fontFamily: fontFamily,
      contentColor: contentColor,
    );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'eventDate': eventDate.toString(),
        'icon': icon?.codePoint,
        'color': color?.value,
        'fontFamily': fontFamily,
        'contentColor': contentColor?.value,
      };
}
