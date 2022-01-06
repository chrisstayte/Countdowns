import 'package:countdowns/enums/sorting_method.dart';

class Settings {
  bool darkMode;
  SortingMethod sortingMethod = SortingMethod.alphaAscending;

  Settings({required this.darkMode, required this.sortingMethod});

  factory Settings.fromJson(Map<String, dynamic> json) {
    bool darkMode = json['darkMode'] as bool;

    SortingMethod? sortingMethod;
    if (json['sortingMethod'] != null) {
      sortingMethod = _getStatusFromString(json['sortingMethod']);
    }

    return Settings(
        darkMode: darkMode,
        sortingMethod: sortingMethod ?? SortingMethod.alphaAscending);
  }

  Map<String, dynamic> toJson() => {
        'darkMode': darkMode,
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
