import 'dart:convert';
import 'dart:io';

import 'package:countdowns/models/settings.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class SettingsProvider extends ChangeNotifier {
  SettingsProvider() {
    _loadEvents();
  }

  late Settings settings = Settings(darkMode: false);

  final String _fileName = 'settings.json';

  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<File> get _localFile async {
    final path = await _localPath;
    return File('$path/$_fileName');
  }

  void setDarkMode(bool isDark) {
    settings.darkMode = isDark;
    _saveEvents();
    notifyListeners();
  }

  Future<void> _loadEvents() async {
    try {
      File file = await _localFile;
      if (!await file.exists()) {
        return;
      }
      String stringFromFile = await file.readAsString();

      settings = Settings.fromJson(jsonDecode(stringFromFile));
    } catch (e) {
      print(e.toString());
    }
    notifyListeners();
  }

  Future<void> _saveEvents() async {
    String settingsString = jsonEncode(settings);
    File file = await _localFile;
    file.writeAsString(settingsString);
  }
}
