import 'dart:convert';

import 'package:countdowns/models/palette.dart';
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

enum CountUnit {
  days('Days'),
  weeks('Weeks'),
  sleeps('Sleeps'),
  hours('Hours');

  const CountUnit(this.label);
  final String label;

  static CountUnit parse(String? name) =>
      values.where((u) => u.name == name).firstOrNull ?? CountUnit.days;
}

enum RepeatRule {
  none('Never'),
  yearly('Every year');

  const RepeatRule(this.label);
  final String label;
}

/// The places a photo is shown, each with its own crop point.
enum CropShape {
  full('Full screen', 390 / 844),
  card('Card', 1),
  wide('Wide widget', 360 / 168),
  tablet('iPad landscape', 1194 / 834);

  const CropShape(this.label, this.aspect);
  final String label;

  /// Width divided by height.
  final double aspect;
}

/// Where each shape's crop sits within the photo, as an [Alignment]
/// (-1 to 1 on each axis) used with [BoxFit.cover].
class PhotoCrops {
  const PhotoCrops({this.sameForAll = true, this.points = const {}});

  final bool sameForAll;
  final Map<CropShape, Alignment> points;

  Alignment alignmentFor(CropShape shape) {
    if (sameForAll) return points[CropShape.full] ?? Alignment.center;
    return points[shape] ?? points[CropShape.full] ?? Alignment.center;
  }

  PhotoCrops copyWith({bool? sameForAll, Map<CropShape, Alignment>? points}) =>
      PhotoCrops(
        sameForAll: sameForAll ?? this.sameForAll,
        points: points ?? this.points,
      );

  String toJson() => jsonEncode({
    'same': sameForAll,
    for (final e in points.entries) e.key.name: [e.value.x, e.value.y],
  });

  static PhotoCrops? fromJson(String? json) {
    if (json == null) return null;
    try {
      final map = jsonDecode(json) as Map<String, dynamic>;
      return PhotoCrops(
        sameForAll: map['same'] as bool? ?? true,
        points: {
          for (final shape in CropShape.values)
            if (map[shape.name] case [num x, num y])
              shape: Alignment(x.toDouble(), y.toDouble()),
        },
      );
    } on FormatException {
      return null;
    } on TypeError {
      return null;
    }
  }

  @override
  bool operator ==(Object other) =>
      other is PhotoCrops &&
      other.sameForAll == sameForAll &&
      other.points.length == points.length &&
      points.entries.every((e) => other.points[e.key] == e.value);

  @override
  int get hashCode => Object.hash(sameForAll, Object.hashAllUnordered(points.entries.map((e) => Object.hash(e.key, e.value))));
}

/// Darken strengths offered for photos.
const photoDarkenLevels = {'Light': 0.15, 'Medium': 0.35, 'Strong': 0.55};

/// A countdown as the app uses it. Stored in the Drift `events` table.
@immutable
class Countdown {
  const Countdown({
    this.id,
    required this.title,
    required this.dateTime,
    this.allDay = true,
    this.iconSlug,
    this.colorArgb = 0xFF7877E6,
    this.gradientId,
    this.gradientDirection,
    this.photoPath,
    this.photoCrops,
    this.photoDarken = 0.35,
    this.fontFamily = 'Default',
    this.unit = CountUnit.days,
    this.repeat = RepeatRule.none,
    this.reminders = const [],
    this.createdAt,
    this.updatedAt,
    this.legacyHiveKey,
  });

  final int? id;
  final String title;
  final DateTime dateTime;
  final bool allDay;
  final String? iconSlug;
  final int colorArgb;
  final String? gradientId;
  final GradientDirection? gradientDirection;

  /// Relative to the app documents folder.
  final String? photoPath;
  final PhotoCrops? photoCrops;
  final double photoDarken;
  final String fontFamily;
  final CountUnit unit;
  final RepeatRule repeat;

  /// Minutes before the event; 0 means at the time.
  final List<int> reminders;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int? legacyHiveKey;

  Color get color => Color(colorArgb);
  bool get hasPhoto => photoPath != null;

  List<Color>? get gradient => gradientColors(gradientId, color);

  GradientDirection get direction =>
      gradientDirection ?? GradientDirection.diagonalDown;

  /// Background for colour fills, null for photos.
  Gradient? get backgroundGradient {
    final colors = gradient;
    return colors == null ? null : buildGradient(colors, direction);
  }

  /// Text colour: ink or white by contrast, white on photos.
  Color get textColor {
    if (hasPhoto) return Colors.white;
    final colors = gradient;
    return colors == null ? autoTextColor(color) : autoTextColorFor(colors);
  }

  /// The moment being counted to (start of the day for all-day events).
  DateTime get target => allDay
      ? DateTime(dateTime.year, dateTime.month, dateTime.day)
      : dateTime;

  /// For yearly events, the next time it happens on or after [now].
  DateTime nextOccurrence(DateTime now) {
    final base = target;
    if (repeat == RepeatRule.none) return base;
    if (!base.isBefore(now)) return base;
    var year = now.year;
    while (true) {
      final candidate = _withYear(base, year);
      final passed = allDay
          ? DateTime(now.year, now.month, now.day).isAfter(candidate)
          : candidate.isBefore(now);
      if (!passed) return candidate;
      year++;
    }
  }

  /// Done means it happened and won't come round again.
  bool isDone(DateTime now) {
    if (repeat == RepeatRule.yearly) return false;
    if (allDay) {
      return DateTime(now.year, now.month, now.day).isAfter(target);
    }
    return !target.isAfter(now);
  }

  /// Time left until the next occurrence (negative once done).
  Duration timeLeft(DateTime now) => nextOccurrence(now).difference(now);

  /// True on the day of an all-day event.
  bool isToday(DateTime now) =>
      allDay &&
      nextOccurrence(now).year == now.year &&
      nextOccurrence(now).month == now.month &&
      nextOccurrence(now).day == now.day;

  Countdown copyWith({
    int? id,
    String? title,
    DateTime? dateTime,
    bool? allDay,
    Object? iconSlug = _keep,
    int? colorArgb,
    Object? gradientId = _keep,
    Object? gradientDirection = _keep,
    Object? photoPath = _keep,
    Object? photoCrops = _keep,
    double? photoDarken,
    String? fontFamily,
    CountUnit? unit,
    RepeatRule? repeat,
    List<int>? reminders,
    DateTime? createdAt,
    DateTime? updatedAt,
    Object? legacyHiveKey = _keep,
  }) => Countdown(
    id: id ?? this.id,
    title: title ?? this.title,
    dateTime: dateTime ?? this.dateTime,
    allDay: allDay ?? this.allDay,
    iconSlug: iconSlug == _keep ? this.iconSlug : iconSlug as String?,
    colorArgb: colorArgb ?? this.colorArgb,
    gradientId: gradientId == _keep ? this.gradientId : gradientId as String?,
    gradientDirection: gradientDirection == _keep
        ? this.gradientDirection
        : gradientDirection as GradientDirection?,
    photoPath: photoPath == _keep ? this.photoPath : photoPath as String?,
    photoCrops: photoCrops == _keep
        ? this.photoCrops
        : photoCrops as PhotoCrops?,
    photoDarken: photoDarken ?? this.photoDarken,
    fontFamily: fontFamily ?? this.fontFamily,
    unit: unit ?? this.unit,
    repeat: repeat ?? this.repeat,
    reminders: reminders ?? this.reminders,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    legacyHiveKey: legacyHiveKey == _keep
        ? this.legacyHiveKey
        : legacyHiveKey as int?,
  );

  @override
  bool operator ==(Object other) =>
      other is Countdown &&
      other.id == id &&
      other.title == title &&
      other.dateTime == dateTime &&
      other.allDay == allDay &&
      other.iconSlug == iconSlug &&
      other.colorArgb == colorArgb &&
      other.gradientId == gradientId &&
      other.gradientDirection == gradientDirection &&
      other.photoPath == photoPath &&
      other.photoCrops == photoCrops &&
      other.photoDarken == photoDarken &&
      other.fontFamily == fontFamily &&
      other.unit == unit &&
      other.repeat == repeat &&
      listEquals(other.reminders, reminders);

  @override
  int get hashCode => Object.hash(
    id,
    title,
    dateTime,
    allDay,
    iconSlug,
    colorArgb,
    gradientId,
    gradientDirection,
    photoPath,
    photoCrops,
    photoDarken,
    fontFamily,
    unit,
    repeat,
    Object.hashAll(reminders),
  );
}

const _keep = Object();

DateTime _withYear(DateTime d, int year) {
  // Feb 29 falls back to Feb 28 in other years.
  final day = d.month == 2 && d.day == 29 && !_isLeap(year) ? 28 : d.day;
  return DateTime(year, d.month, day, d.hour, d.minute);
}

bool _isLeap(int y) => (y % 4 == 0 && y % 100 != 0) || y % 400 == 0;
