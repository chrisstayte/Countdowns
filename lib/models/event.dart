import 'package:flutter/material.dart';

class Event {
  String title;
  DateTime eventDate;
  IconData? icon;
  Color? color;

  Event({required this.title, required this.eventDate, this.icon, this.color});
}
