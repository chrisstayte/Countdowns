import 'package:countdowns/enums/sorting_method.dart';
import 'package:flutter/material.dart';

class LocalSettings {
  ThemeMode themeMode = ThemeMode.light;
  SortingMethod sortingMethod = SortingMethod.alphaAscending;
  bool hapticFeedback = true;
  bool soundEffects = false;
  bool squareView = true;
  bool notify = false;
  String iconName;

  LocalSettings._({
    required this.themeMode,
    required this.sortingMethod,
    required this.hapticFeedback,
    required this.soundEffects,
    required this.squareView,
    required this.notify,
    required this.iconName,
  });

  factory LocalSettings.initialSettings() {
    return LocalSettings._(
      themeMode: ThemeMode.system,
      sortingMethod: SortingMethod.alphaAscending,
      hapticFeedback: true,
      soundEffects: false,
      squareView: true,
      notify: false,
      iconName: 'light',
    );
  }

  factory LocalSettings.fromJson(Map<String, dynamic> json) {
    int themeMode = json['themeMode'] as int;
    SortingMethod? sortingMethod;
    if (json['sortingMethod'] != null) {
      sortingMethod = _getStatusFromString(json['sortingMethod']);
    }

    bool hasHapticFeedback = json['hapticFeedback'] as bool;
    bool hasSoundFeedback = json['soundEffects'] as bool;
    bool squareView = json['squareView'] as bool;
    bool notify = json['notify'] as bool;

    return LocalSettings._(
      themeMode: ThemeMode.values[themeMode],
      sortingMethod: sortingMethod ?? SortingMethod.alphaAscending,
      hapticFeedback: hasHapticFeedback,
      soundEffects: hasSoundFeedback,
      squareView: squareView,
      notify: notify,
      iconName: json['iconName'] ?? 'light',
    );
  }

  Map<String, dynamic> toJson() => {
    'themeMode': themeMode.index,
    'sortingMethod': sortingMethod.toString(),
    'hapticFeedback': hapticFeedback,
    'soundEffects': soundEffects,
    'squareView': squareView,
    'notify': notify,
    'iconName': iconName,
  };

  static SortingMethod _getStatusFromString(String sortingMethodAsString) {
    for (SortingMethod element in SortingMethod.values) {
      if (element.toString() == sortingMethodAsString) {
        return element;
      }
    }
    return SortingMethod.alphaAscending;
  }
}
