import 'dart:convert';

import 'package:countdowns/enums/sorting_method.dart';
import 'package:countdowns/models/countdown.dart';
import 'package:countdowns/models/local_settings.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

final preferencesProvider = Provider<SharedPreferences>(
  (ref) => throw StateError('Preferences must be opened before startup'),
);

final localSettingsProvider =
    NotifierProvider<SettingsController, LocalSettings>(SettingsController.new);

class SettingsController extends Notifier<LocalSettings> {
  @override
  LocalSettings build() {
    final json = ref.watch(preferencesProvider).getString('localSettings');
    return json == null
        ? const LocalSettings()
        : LocalSettings.fromJson(jsonDecode(json));
  }

  Future<void> _save(LocalSettings next) async {
    state = next;
    await ref
        .read(preferencesProvider)
        .setString('localSettings', jsonEncode(next.toJson()));
  }

  Future<void> setThemeMode(int index) =>
      _save(state.copyWith(themeMode: ThemeMode.values[index]));
  Future<void> setSortingMethod(SortingMethod value) =>
      _save(state.copyWith(sortingMethod: value));
  Future<void> setHapticFeedbackMode(bool value) =>
      _save(state.copyWith(hapticFeedback: value));
  Future<void> setSoundEffectsMode(bool value) =>
      _save(state.copyWith(soundEffects: value));
  Future<void> setSquareView(bool value) =>
      _save(state.copyWith(squareView: value));
  Future<void> setNotify(bool value) => _save(state.copyWith(notify: value));
  Future<void> setIconName(String value) =>
      _save(state.copyWith(iconName: value));
  Future<void> setDefaultUnit(CountUnit value) =>
      _save(state.copyWith(defaultUnit: value));
  Future<void> setDefaultReminders(List<int> value) =>
      _save(state.copyWith(defaultReminders: [...value]..sort()));
  Future<void> setKeepDone(bool value) =>
      _save(state.copyWith(keepDone: value));
}
