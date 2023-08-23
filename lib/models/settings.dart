import 'package:countdowns/enums/sorting_method.dart';

class Settings {
  // Theme Mode: 0 = System, 1 = Light, 2 = Dark
  int themeMode = 0;
  SortingMethod sortingMethod = SortingMethod.alphaAscending;

  Settings({required this.themeMode, required this.sortingMethod});

  factory Settings.fromJson(Map<String, dynamic> json) {
    int themeMode = json['themeMode'] as int;

    SortingMethod? sortingMethod;
    if (json['sortingMethod'] != null) {
      sortingMethod = _getStatusFromString(json['sortingMethod']);
    }

    return Settings(
        themeMode: themeMode,
        sortingMethod: sortingMethod ?? SortingMethod.alphaAscending);
  }

  Map<String, dynamic> toJson() => {
        'themeMode': themeMode,
        'sortingMethod': sortingMethod.toString(),
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
