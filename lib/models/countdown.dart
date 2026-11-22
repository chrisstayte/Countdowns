import 'dart:convert';

import 'package:countdowns/models/art_catalog.dart';
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

/// Soon counts down to a date; Since counts up from one (sober since,
/// started a job, together since).
enum EventKind {
  soon('Soon'),
  since('Since');

  const EventKind(this.label);
  final String label;
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

/// Zoom limits for photo crops. 1 means the photo just covers the shape.
const minPhotoZoom = 1.0;
const maxPhotoZoom = 4.0;

/// One shape's crop: where it sits in the photo, as an [Alignment]
/// (-1 to 1 on each axis, as used with [BoxFit.cover]), and how far it is
/// zoomed in.
@immutable
class CropPoint {
  const CropPoint(this.x, this.y, [this.zoom = minPhotoZoom]);

  static const center = CropPoint(0, 0);

  final double x, y, zoom;

  Alignment get alignment => Alignment(x, y);

  CropPoint moved(double dx, double dy) =>
      CropPoint((x + dx).clamp(-1.0, 1.0), (y + dy).clamp(-1.0, 1.0), zoom);

  CropPoint zoomed(double value) =>
      CropPoint(x, y, value.clamp(minPhotoZoom, maxPhotoZoom));

  @override
  bool operator ==(Object other) =>
      other is CropPoint && other.x == x && other.y == y && other.zoom == zoom;

  @override
  int get hashCode => Object.hash(x, y, zoom);

  @override
  String toString() => 'CropPoint($x, $y, zoom: $zoom)';
}

/// The crop for every shape a photo shows in. Each shape always keeps its
/// own point and zoom. A shape with nothing stored yet uses the full-screen
/// crop. (Older saves may hold a "same" flag; it's ignored.)
class PhotoCrops {
  const PhotoCrops({this.points = const {}});

  final Map<CropShape, CropPoint> points;

  CropPoint pointFor(CropShape shape) =>
      points[shape] ?? points[CropShape.full] ?? CropPoint.center;

  PhotoCrops copyWith({Map<CropShape, CropPoint>? points}) =>
      PhotoCrops(points: points ?? this.points);

  String toJson() => jsonEncode({
    for (final e in points.entries)
      e.key.name: [e.value.x, e.value.y, e.value.zoom],
  });

  static PhotoCrops? fromJson(String? json) {
    if (json == null) return null;
    try {
      final map = jsonDecode(json) as Map<String, dynamic>;
      return PhotoCrops(
        points: {
          for (final shape in CropShape.values)
            if (map[shape.name] case [num x, num y, ...final rest])
              shape: CropPoint(
                x.toDouble(),
                y.toDouble(),
                rest.isNotEmpty && rest.first is num
                    ? (rest.first as num).toDouble()
                    : minPhotoZoom,
              ),
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
      other.points.length == points.length &&
      points.entries.every((e) => other.points[e.key] == e.value);

  @override
  int get hashCode => Object.hashAllUnordered(
    points.entries.map((e) => Object.hash(e.key, e.value)),
  );
}

/// The part of an image of [imageSize] that a crop of [aspect] shows:
/// BoxFit.cover at the point's alignment, shrunk by its zoom.
Rect cropRectIn(Size imageSize, double aspect, CropPoint point) {
  final imageAspect = imageSize.width / imageSize.height;
  final coverW = aspect > imageAspect
      ? imageSize.width
      : imageSize.height * aspect;
  final coverH = aspect > imageAspect
      ? imageSize.width / aspect
      : imageSize.height;
  final w = coverW / point.zoom, h = coverH / point.zoom;
  return Rect.fromLTWH(
    (imageSize.width - w) * (point.x + 1) / 2,
    (imageSize.height - h) * (point.y + 1) / 2,
    w,
    h,
  );
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
    this.kind = EventKind.soon,
    this.allDay = true,
    this.iconSlug,
    this.colorArgb = 0xFF7877E6,
    this.gradientId,
    this.gradientDirection,
    this.artId,
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

  /// The date counted to (Soon), or the start counted from (Since).
  final DateTime dateTime;
  final EventKind kind;
  final bool allDay;
  final String? iconSlug;
  final int colorArgb;
  final String? gradientId;
  final GradientDirection? gradientDirection;

  /// A pattern, texture or illustration (see art_catalog.dart). Shown
  /// instead of the colour or gradient; a photo still shows over it.
  final String? artId;

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

  bool get isSince => kind == EventKind.since;

  Color get color => Color(colorArgb);
  bool get hasPhoto => photoPath != null;

  /// The drawn background, if it has one (and no photo over it).
  Art? get art => hasPhoto ? null : artById(artId);

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
    if (art case final a?) return a.textColor;
    final colors = gradient;
    return colors == null ? autoTextColor(color) : autoTextColorFor(colors);
  }

  /// The moment being counted to (start of the day for all-day events).
  DateTime get target =>
      allDay ? DateTime(dateTime.year, dateTime.month, dateTime.day) : dateTime;

  /// For yearly events, the next time it happens on or after [now]. Since
  /// events always give their start.
  DateTime nextOccurrence(DateTime now) {
    final base = target;
    if (repeat == RepeatRule.none || isSince) return base;
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

  /// Done means it happened and won't come round again. Since events keep
  /// counting, so they're never done.
  bool isDone(DateTime now) {
    if (isSince || repeat == RepeatRule.yearly) return false;
    if (allDay) {
      return DateTime(now.year, now.month, now.day).isAfter(target);
    }
    return !target.isAfter(now);
  }

  /// Time left until the next occurrence (negative once done).
  Duration timeLeft(DateTime now) => nextOccurrence(now).difference(now);

  /// True on the day of an all-day event (the first day, for Since).
  bool isToday(DateTime now) =>
      allDay &&
      nextOccurrence(now).year == now.year &&
      nextOccurrence(now).month == now.month &&
      nextOccurrence(now).day == now.day;

  Countdown copyWith({
    int? id,
    String? title,
    DateTime? dateTime,
    EventKind? kind,
    bool? allDay,
    Object? iconSlug = _keep,
    int? colorArgb,
    Object? gradientId = _keep,
    Object? gradientDirection = _keep,
    Object? artId = _keep,
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
    kind: kind ?? this.kind,
    allDay: allDay ?? this.allDay,
    iconSlug: iconSlug == _keep ? this.iconSlug : iconSlug as String?,
    colorArgb: colorArgb ?? this.colorArgb,
    gradientId: gradientId == _keep ? this.gradientId : gradientId as String?,
    gradientDirection: gradientDirection == _keep
        ? this.gradientDirection
        : gradientDirection as GradientDirection?,
    artId: artId == _keep ? this.artId : artId as String?,
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
      other.kind == kind &&
      other.allDay == allDay &&
      other.iconSlug == iconSlug &&
      other.colorArgb == colorArgb &&
      other.gradientId == gradientId &&
      other.gradientDirection == gradientDirection &&
      other.artId == artId &&
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
    kind,
    allDay,
    iconSlug,
    colorArgb,
    gradientId,
    gradientDirection,
    artId,
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
