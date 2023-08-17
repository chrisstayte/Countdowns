import 'dart:convert';
import 'dart:io';

import 'package:countdowns/enums/sorting_method.dart';
import 'package:countdowns/models/settings.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class SettingsProvider extends ChangeNotifier {
  SettingsProvider() {
    _loadSettings();
  }

  late Settings settings =
      Settings(darkMode: false, sortingMethod: SortingMethod.alphaAscending);

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
    _saveSettings();
    notifyListeners();
  }

  void setSortingMethod(SortingMethod sortingMethod) {
    settings.sortingMethod = sortingMethod;

    _saveSettings();
    notifyListeners();
  }

  Future<void> _loadSettings() async {
    try {
      File file = await _localFile;
      if (!await file.exists()) {
        return;
      }
      String stringFromFile = await file.readAsString();

      // printing out file for user to see
      if (kDebugMode) {
        print("\n\nSettings\n$stringFromFile");
      }

      settings = Settings.fromJson(jsonDecode(stringFromFile));
    } catch (e) {
      print(e.toString());
    }
    notifyListeners();
  }

  Future<void> _saveSettings() async {
    String settingsString = jsonEncode(settings);
    File file = await _localFile;
    file.writeAsString(settingsString);
  }
}
