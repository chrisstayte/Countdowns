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

  late Settings settings = Settings(
    themeMode: 0,
    sortingMethod: SortingMethod.alphaAscending,
    hapticFeedback: true,
    soundEffects: true,
    squareView: true,
    notify: true,
  );

  final String _fileName = 'settings.json';

  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<File> get _localFile async {
    final path = await _localPath;
    return File('$path/$_fileName');
  }

  void setThemeMode(int themeMode) {
    settings.themeMode = themeMode;
    _saveSettings();
    notifyListeners();
  }

  void setHapticFeedbackMode(bool hapticFeedback) {
    settings.hapticFeedback = hapticFeedback;
    _saveSettings();
    notifyListeners();
  }

  void setSquareView(bool squareView) {
    settings.squareView = squareView;
    _saveSettings();
    notifyListeners();
  }

  void setNotify(bool notify) {
    settings.notify = notify;
    _saveSettings();
    notifyListeners();
  }

  void setSoundEffectsMode(bool soundEffects) {
    settings.soundEffects = soundEffects;
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
        print("Settings: $stringFromFile");
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
