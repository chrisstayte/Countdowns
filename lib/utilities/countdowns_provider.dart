import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:countdowns/enums/sorting_method.dart';
import 'package:countdowns/models/countdown_event.dart';
import 'package:countdowns/utilities/settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class CountdownsProvider extends ChangeNotifier {
  SettingsProvider? _settingsProvider;
  final String _fileName = 'countdownevents.json';

  CountdownsProvider(this._settingsProvider) {}

  CountdownsProvider.empty() {}

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
    _events.add(
      CountdownEvent(
        title: 'Random',
        eventDate: DateTime(2023, 3, 4),
        color: Colors.primaries[Random().nextInt(Colors.primaries.length)],
      ),
    );
    notifyListeners();
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

  void sortEvents() async {
    switch (_settingsProvider?.settings.sortingMethod) {
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

  Future<void> loadEvents() async {
    try {
      File file = await _localFile;
      if (!await file.exists()) {
        return;
      }
      String stringFromFile = await file.readAsString();
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
