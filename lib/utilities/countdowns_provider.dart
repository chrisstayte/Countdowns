import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:countdowns/models/countdown_event.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class CountdownsProvider extends ChangeNotifier {
  final String _fileName = 'countdownevents.json';

  CountdownsProvider() {
    loadEvents();
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
    _saveEvents();
    notifyListeners();
  }

  void deleteEvent(CountdownEvent event) {
    _events.remove(event);
    _saveEvents();
    notifyListeners();
  }

  void deleteAll() {
    _events.clear();
    notifyListeners();
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
