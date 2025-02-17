import 'dart:async';
import 'dart:convert';

import 'package:countdowns/enums/sorting_method.dart';
import 'package:countdowns/models/local_settings.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalSettingsProvider extends ChangeNotifier {
  late LocalSettings localSettings;
  final Completer _completer = Completer<void>();

  Future<void> get isReady => _completer.future;

  LocalSettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? localSettingsJson = prefs.getString('localSettings');

    if (localSettingsJson != null) {
      Map<String, dynamic> json = jsonDecode(localSettingsJson);
      localSettings = LocalSettings.fromJson(json);
      debugPrint('Loaded local settings: ${localSettings.toJson()}');
    } else {
      localSettings = LocalSettings.initialSettings();
      debugPrint('Loaded default local settings: $localSettings');
    }

    _completer.complete();
  }

  Future<void> saveSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String localSettingsJson = jsonEncode(localSettings.toJson());
    await prefs.setString('localSettings', localSettingsJson);
  }

  void setSoundEffectsMode(bool soundEffects) {
    localSettings.soundEffects = soundEffects;
    saveSettings();
    notifyListeners();
  }

  void setThemeMode(int themeMode) {
    final ThemeMode convertedThemeMode = ThemeMode.values[themeMode];
    localSettings.themeMode = convertedThemeMode;

    localSettings.themeMode = convertedThemeMode;
    saveSettings();
    notifyListeners();
  }

  void setSortingMethod(SortingMethod sortingMethod) {
    localSettings.sortingMethod = sortingMethod;
    saveSettings();
    notifyListeners();
  }

  void setHapticFeedbackMode(bool hapticFeedback) {
    localSettings.hapticFeedback = hapticFeedback;
    saveSettings();
    notifyListeners();
  }

  void setSoundEffects(bool soundEffects) {
    localSettings.soundEffects = soundEffects;
    saveSettings();
    notifyListeners();
  }

  void setSquareView(bool squareView) {
    localSettings.squareView = squareView;
    saveSettings();
    notifyListeners();
  }

  void setNotify(bool notify) {
    localSettings.notify = notify;
    saveSettings();
    notifyListeners();
  }

  void setIconName(String iconName) {
    localSettings.iconName = iconName;
    saveSettings();
    notifyListeners();
  }

  void resetSettings() {
    localSettings = LocalSettings.initialSettings();
    saveSettings();
    notifyListeners();
  }
}
