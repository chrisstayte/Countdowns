import 'package:countdowns/enums/sorting_method.dart';

class Settings {
  // Theme Mode: 0 = System, 1 = Light, 2 = Dark
  int themeMode = 0;
  SortingMethod sortingMethod = SortingMethod.alphaAscending;
  bool hapticFeedback = true;
  bool soundEffects = true;
  bool squareView = true;
  bool notify = false;

  Settings({
    required this.themeMode,
    required this.sortingMethod,
    required this.hapticFeedback,
    required this.soundEffects,
    required this.squareView,
    required this.notify,
  });

  factory Settings.fromJson(Map<String, dynamic> json) {
    int themeMode = json['themeMode'] as int;

    SortingMethod? sortingMethod;
    if (json['sortingMethod'] != null) {
      sortingMethod = _getStatusFromString(json['sortingMethod']);
    }

    bool hasHapticFeedback = json['hapticFeedback'] as bool;
    bool hasSoundFeedback = json['soundEffects'] as bool;
    bool squareView = json['squareView'] as bool;
    bool notify = json['notify'] as bool;

    return Settings(
      themeMode: themeMode,
      sortingMethod: sortingMethod ?? SortingMethod.alphaAscending,
      hapticFeedback: hasHapticFeedback,
      soundEffects: hasSoundFeedback,
      squareView: squareView,
      notify: notify,
    );
  }

  Map<String, dynamic> toJson() => {
        'themeMode': themeMode,
        'sortingMethod': sortingMethod.toString(),
        'hapticFeedback': hapticFeedback,
        'soundEffects': soundEffects,
        'squareView': squareView,
        'notify': notify,
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
