import 'dart:math';

import 'package:countdown/models/countdown_event.dart';
import 'package:flutter/material.dart';

class MyCountdowns extends ChangeNotifier {
  final List<CountdownEvent> _events = [
    CountdownEvent(
      title: 'Jeff\'s Birthday',
      color: const Color(0XFFBB84E7),
      eventDate: DateTime(2022, 1, 5),
      icon: Icons.celebration,
    ),
  ];
  List<CountdownEvent> get events => _events;

  void addRandomEvent() {
    _events.add(
      CountdownEvent(
        title: 'Random',
        eventDate: DateTime(2023, 3, 4),
        color: Colors.primaries[Random().nextInt(Colors.primaries.length)],
      ),
    );
    notifyListeners();
  }

  void addEvent(CountdownEvent event) {
    _events.add(event);
    notifyListeners();
  }
}
