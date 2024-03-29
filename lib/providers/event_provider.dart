import 'package:countdowns/enums/sorting_method.dart';
import 'package:countdowns/models/event.dart';
import 'package:flutter/cupertino.dart';
import 'package:hive/hive.dart';

class EventProvider extends ChangeNotifier {
  static const String BoxName = 'events';
  final Box<Event> box = Hive.box<Event>(BoxName);

  List<Event> get events => box.values.toList();

  Map<SortingMethod, int Function(Event a, Event b)> sortingMethods = {
    SortingMethod.alphaAscending: (a, b) {
      return a.title.toLowerCase().compareTo(b.title.toLowerCase());
    },
    SortingMethod.alphaDescending: (a, b) {
      return b.title.toLowerCase().compareTo(a.title.toLowerCase());
    },
    SortingMethod.dateAscending: (a, b) {
      return a.eventDateTime.compareTo(b.eventDateTime);
    },
    SortingMethod.dateDescending: (a, b) {
      return b.eventDateTime.compareTo(a.eventDateTime);
    },
  };

  Event? getEvent(String? key) {
    if (key == null) return null;
    return box.get(int.tryParse(key));
  }

  void saveEvent(Event event) {
    event.save();
    notifyListeners();
  }

  void addEvent(Event event) {
    box.add(event);
    notifyListeners();
  }

  void deleteEvent(Event event) {
    event.cancelNotification();
    box.delete(event.key);
    notifyListeners();
  }

  void deleteAllEvents() {
    box.clear();
    notifyListeners();
  }
}
