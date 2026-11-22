import 'package:countdowns/models/event_icons.dart';
import 'package:material_ui/material_ui.dart';

class CountdownEvent {
  String title;
  DateTime eventDate;
  IconData? icon;
  Color? backgroundColor;
  Color? contentColor;
  String? fontFamily;

  CountdownEvent({
    required this.title,
    required this.eventDate,
    this.icon,
    this.backgroundColor,
    this.fontFamily,
    this.contentColor,
  });

  factory CountdownEvent.fromJson(Map<String, dynamic> json) {
    String title = json['title'] as String;
    DateTime eventDate = DateTime.parse(json['eventDate']);
    IconData? icon;
    if (json['icon'] != null) {
      icon = eventIcon(json['icon']);
    }

    Color? color;
    if (json['backgroundColor'] != null) {
      color = Color(json['backgroundColor']).withValues(alpha: 1);
    }

    String? fontFamily = json['fontFamily'];

    Color? contentColor;
    if (json['contentColor'] != null) {
      contentColor = Color(json['contentColor']).withValues(alpha: 1);
    }
    return CountdownEvent(
      title: title,
      eventDate: eventDate,
      icon: icon,
      backgroundColor: color,
      fontFamily: fontFamily,
      contentColor: contentColor,
    );
  }
}
