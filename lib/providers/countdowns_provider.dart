import 'dart:convert';
import 'dart:io';
import 'dart:math';

// THIS IS LEGACY CODE, TO BE REMOVED AFTER OFFICIAL RELEASE AND WORKING CANDIDATE

import 'package:countdowns/enums/sorting_method.dart';
import 'package:countdowns/models/countdown_event.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class CountdownsProvider extends ChangeNotifier {
  final String _fileName = 'countdownevents.json';

  CountdownsProvider() {
    _loadEvents();
  }

  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();

    return directory.path;
  }

  Future<File> get _localFile async {
    final path = await _localPath;
    return File('$path/$_fileName');
  }

  List<CountdownEvent> _events = [
    // CountdownEvent(
    //   title: 'Jeff\'s Birthday',
    //   color: const Color(0XFFBB84E7),
    //   eventDate: DateTime(2022, 1, 5),
    //   icon: Icons.celebration,
    // ),
  ];

  List<CountdownEvent> get events => _events;

  void addRandomEvent() {
    int randomNumber = Random().nextInt(5);
    addEvent(
      CountdownEvent(
        title: 'Random',
        eventDate: DateTime(2025 + randomNumber, randomNumber, 4),
        backgroundColor:
            Colors.primaries[Random().nextInt(Colors.primaries.length)],
      ),
    );
  }

  void _sortEventsAlphaAscending() {
    events.sort((a, b) {
      return a.title.toLowerCase().compareTo(b.title.toLowerCase());
    });
  }

  void _sortEventAlphaDescending() {
    _events.sort((a, b) {
      return b.title.toLowerCase().compareTo(a.title.toLowerCase());
    });
  }

  void _sortEventsDateAscending() {
    _events.sort((a, b) {
      return a.eventDate.compareTo(b.eventDate);
    });
  }

  void _sortEventsDateDescending() {
    _events.sort((a, b) {
      return b.eventDate.compareTo(a.eventDate);
    });
  }

  void sortEvents(SortingMethod sortingMethod) async {
    switch (sortingMethod) {
      case SortingMethod.alphaAscending:
        _sortEventsAlphaAscending();
        break;
      case SortingMethod.alphaDescending:
        _sortEventAlphaDescending();
        break;
      case SortingMethod.dateAscending:
        _sortEventsDateAscending();
        break;
      case SortingMethod.dateDescending:
        _sortEventsDateDescending();
        break;
    }

    notifyListeners();
    await _saveEvents();
  }

  void editEvent(CountdownEvent event) async {
    if (_events.contains(event)) {
      notifyListeners();
      _saveEvents();
    }
  }

  void addEvent(CountdownEvent event) async {
    _events.add(event);
    notifyListeners();
    await _saveEvents();
  }

  void deleteEvent(CountdownEvent event) async {
    _events.remove(event);
    notifyListeners();
    await _saveEvents();
  }

  void deleteAll() async {
    _events.clear();
    notifyListeners();
    await _saveEvents();
  }

  Future<void> _loadEvents() async {
    try {
      File file = await _localFile;
      if (!await file.exists()) {
        return;
      }
      String stringFromFile = await file.readAsString();

      // printing out file for user to see
      if (kDebugMode) {
        print("\n\nCountdowns\n$stringFromFile");
      }

      List<dynamic> parsedListJson = jsonDecode(stringFromFile);

      _events = List<CountdownEvent>.from(
          parsedListJson.map((e) => CountdownEvent.fromJson(e)));
    } catch (e) {
      print(e.toString());
    }

    notifyListeners();
  }

  Future<void> _saveEvents() async {
    String countdownEvents = jsonEncode(_events);
    File file = await _localFile;
    file.writeAsString(countdownEvents);
  }
}
