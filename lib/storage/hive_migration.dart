import 'package:countdowns/data/database.dart';
import 'package:countdowns/models/countdown.dart';
import 'package:countdowns/models/event.dart';
import 'package:countdowns/models/event_icons.dart';
import 'package:countdowns/models/palette.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Set in SharedPreferences once every Hive event is safely in Drift.
const driftMigratedKey = 'driftMigrated';

enum MigrationOutcome {
  /// Already done on an earlier launch.
  alreadyDone,

  /// Copied this launch.
  copied,

  /// Nothing to copy (no Hive data).
  nothingToCopy,

  /// The copy threw. Hive is untouched; it will be retried next launch.
  failed,
}

/// Maps one Hive event to a countdown. Pure, so tests can check every field.
Countdown countdownFromHive(
  int key,
  Event event, {
  required bool notify,
  required DateTime now,
  CountUnit unit = CountUnit.days,
}) {
  final legacyFuture = event.getTimeDifference(now) > Duration.zero;
  return Countdown(
    title: event.title,
    dateTime: event.eventDateTime,
    allDay: event.allDayEvent,
    iconSlug: slugForCodePoint(event.icon?.codePoint),
    // Custom colours are kept exactly; never snapped to the palette.
    colorArgb: event.backgroundColor.toARGB32(),
    gradientId: event.backgroundGradient ? legacyGradientId : null,
    gradientDirection: event.backgroundGradient
        ? GradientDirection.diagonalDown
        : null,
    fontFamily: event.fontFamily,
    unit: unit,
    // contentColor is dropped: text colour is now always automatic.
    reminders: notify && legacyFuture ? const [0] : const [],
    createdAt: now,
    legacyHiveKey: key,
  );
}

/// Copies every Hive event into Drift once.
///
/// The Hive file is only read, never written or deleted, so it stays as a
/// backup. Rows carry `legacyHiveKey`, so a rerun skips what is already there.
/// [beforeInsert] lets tests interrupt the copy part-way.
Future<MigrationOutcome> migrateHiveToDrift({
  required AppDatabase db,
  required SharedPreferences prefs,
  required Box<Event>? box,
  required bool notify,
  CountUnit unit = CountUnit.days,
  DateTime? now,
  @visibleForTesting void Function(int index)? beforeInsert,
}) async {
  if (prefs.getBool(driftMigratedKey) == true) {
    return MigrationOutcome.alreadyDone;
  }
  try {
    final entries = <(int, Event)>[];
    if (box != null) {
      for (final key in box.keys) {
        final event = box.get(key);
        if (key is int && event != null) entries.add((key, event));
      }
    }
    final stamp = now ?? DateTime.now();
    await db.transaction(() async {
      final done = await db.legacyKeys();
      for (final (index, (key, event)) in entries.indexed) {
        if (done.contains(key)) continue;
        beforeInsert?.call(index);
        await db.saveCountdown(
          countdownFromHive(key, event, notify: notify, now: stamp, unit: unit),
          now: stamp,
        );
      }
    });
    // Only after the transaction has committed.
    await prefs.setBool(driftMigratedKey, true);
    return entries.isEmpty
        ? MigrationOutcome.nothingToCopy
        : MigrationOutcome.copied;
  } catch (error, stack) {
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stack,
        library: 'hive to drift migration',
        context: ErrorDescription('copying countdowns; will retry next launch'),
      ),
    );
    return MigrationOutcome.failed;
  }
}
