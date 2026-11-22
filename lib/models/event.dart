import 'package:countdowns/models/event_icons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:hive/hive.dart';

part 'event_adapter.dart';

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
      eventDateTime: eventDateTime,
      allDayEvent: allDayEvent,
      icon: icon,
      backgroundColor: backgroundColor,
      contentColor: contentColor,
      fontFamily: fontFamily,
      backgroundGradient: backgroundGradient,
    );
  }

  Duration getTimeDifference([DateTime? now]) {
    DateTime eventDate = allDayEvent
        ? DateTime(eventDateTime.year, eventDateTime.month, eventDateTime.day)
        : eventDateTime;

    return eventDate.difference(now ?? DateTime.now());
  }
}
