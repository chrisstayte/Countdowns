import 'package:countdowns/enums/sorting_method.dart';
import 'package:countdowns/models/countdown.dart';
import 'package:material_ui/material_ui.dart';

/// Settings stored as JSON in SharedPreferences under `localSettings`.
///
/// [themeMode], [sortingMethod] and [squareView] are hidden in the redesign
/// but still read and written back unchanged so they can return later.
/// Keys this version doesn't know about are kept in [extra] and written back.
class LocalSettings {
  const LocalSettings({
    this.themeMode = ThemeMode.system,
    this.sortingMethod = SortingMethod.alphaAscending,
    this.hapticFeedback = true,
    this.soundEffects = false,
    this.squareView = true,
    this.notify = false,
    this.iconName = 'highlighter',
    this.defaultUnit = CountUnit.days,
    this.defaultReminders = const [0],
    this.keepDone = true,
    this.extra = const {},
  });

  final ThemeMode themeMode;
  final SortingMethod sortingMethod;
  final bool hapticFeedback, soundEffects, squareView, notify;
  final String iconName;

  /// New in the redesign: defaults for new countdowns and the Done section.
  final CountUnit defaultUnit;
  final List<int> defaultReminders;
  final bool keepDone;
  final Map<String, dynamic> extra;

  LocalSettings copyWith({
    ThemeMode? themeMode,
    SortingMethod? sortingMethod,
    bool? hapticFeedback,
    bool? soundEffects,
    bool? squareView,
    bool? notify,
    String? iconName,
    CountUnit? defaultUnit,
    List<int>? defaultReminders,
    bool? keepDone,
  }) => LocalSettings(
    themeMode: themeMode ?? this.themeMode,
    sortingMethod: sortingMethod ?? this.sortingMethod,
    hapticFeedback: hapticFeedback ?? this.hapticFeedback,
    soundEffects: soundEffects ?? this.soundEffects,
    squareView: squareView ?? this.squareView,
    notify: notify ?? this.notify,
    iconName: iconName ?? this.iconName,
    defaultUnit: defaultUnit ?? this.defaultUnit,
    defaultReminders: defaultReminders ?? this.defaultReminders,
    keepDone: keepDone ?? this.keepDone,
    extra: extra,
  );

  static const _known = {
    'themeMode',
    'sortingMethod',
    'hapticFeedback',
    'soundEffects',
    'squareView',
    'notify',
    'iconName',
    'defaultUnit',
    'defaultReminders',
    'keepDone',
  };

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
    defaultUnit: CountUnit.parse(json['defaultUnit'] as String?),
    defaultReminders: json['defaultReminders'] is List
        ? [
            for (final v in json['defaultReminders'] as List)
              if (v is int) v,
          ]
        : const [0],
    keepDone: json['keepDone'] ?? true,
    extra: {
      for (final e in json.entries)
        if (!_known.contains(e.key)) e.key: e.value,
    },
  );

  Map<String, dynamic> toJson() => {
    ...extra,
    'themeMode': themeMode.index,
    'sortingMethod': sortingMethod.toString(),
    'hapticFeedback': hapticFeedback,
    'soundEffects': soundEffects,
    'squareView': squareView,
    'notify': notify,
    'iconName': iconName,
    'defaultUnit': defaultUnit.name,
    'defaultReminders': defaultReminders,
    'keepDone': keepDone,
  };
}
