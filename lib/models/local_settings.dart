import 'package:countdowns/enums/sorting_method.dart';
import 'package:material_ui/material_ui.dart';

class LocalSettings {
  const LocalSettings({
    this.themeMode = ThemeMode.system,
    this.sortingMethod = SortingMethod.alphaAscending,
    this.hapticFeedback = true,
    this.soundEffects = false,
    this.squareView = true,
    this.notify = false,
    this.iconName = 'highlighter',
  });

  final ThemeMode themeMode;
  final SortingMethod sortingMethod;
  final bool hapticFeedback, soundEffects, squareView, notify;
  final String iconName;

  LocalSettings copyWith({
    ThemeMode? themeMode,
    SortingMethod? sortingMethod,
    bool? hapticFeedback,
    bool? soundEffects,
    bool? squareView,
    bool? notify,
    String? iconName,
  }) => LocalSettings(
    themeMode: themeMode ?? this.themeMode,
    sortingMethod: sortingMethod ?? this.sortingMethod,
    hapticFeedback: hapticFeedback ?? this.hapticFeedback,
    soundEffects: soundEffects ?? this.soundEffects,
    squareView: squareView ?? this.squareView,
    notify: notify ?? this.notify,
    iconName: iconName ?? this.iconName,
  );

  factory LocalSettings.fromJson(Map<String, dynamic> json) => LocalSettings(
    themeMode:
        ThemeMode.values
            .where((v) => v.index == json['themeMode'])
            .firstOrNull ??
        ThemeMode.system,
    sortingMethod:
        SortingMethod.values
            .where((v) => v.toString() == json['sortingMethod'])
            .firstOrNull ??
        SortingMethod.alphaAscending,
    hapticFeedback: json['hapticFeedback'] ?? true,
    soundEffects: json['soundEffects'] ?? false,
    squareView: json['squareView'] ?? true,
    notify: json['notify'] ?? false,
    iconName: json['iconName'] ?? 'highlighter',
  );

  Map<String, dynamic> toJson() => {
    'themeMode': themeMode.index,
    'sortingMethod': sortingMethod.toString(),
    'hapticFeedback': hapticFeedback,
    'soundEffects': soundEffects,
    'squareView': squareView,
    'notify': notify,
    'iconName': iconName,
  };
}
