import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:countdowns/data/database.dart';
import 'package:countdowns/models/countdown.dart';
import 'package:countdowns/models/countdown_event.dart';
import 'package:countdowns/models/event_icons.dart';
import 'package:countdowns/models/local_settings.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Marks, inside the same Drift transaction as the rows, that the v1 JSON
/// countdowns were imported, so an interruption can never import them twice.
const _v1ImportedMeta = 'v1JsonImported';

/// Imports files written by the original mobile releases (v1) before the UI
/// starts. Countdowns go straight into Drift.
Future<void> importLegacyData(
  Directory directory,
  AppDatabase db,
  SharedPreferences prefs, {
  DateTime? now,
}) async {
  final settingsFile = File('${directory.path}/settings.json');
  if (!prefs.containsKey('localSettings') && await settingsFile.exists()) {
    final json = await settingsFile.readAsString();
    try {
      final settings = LocalSettings.fromJson(jsonDecode(json));
      await prefs.setString('localSettings', jsonEncode(settings.toJson()));
    } on FormatException catch (error) {
      debugPrint('Could not read legacy settings: $error');
    } on TypeError catch (error) {
      debugPrint('Could not read legacy settings: $error');
    }
  }

  // Earlier builds imported v1 JSON into Hive; those rows arrive through the
  // Hive copy instead.
  if (prefs.getBool('legacyEventsImported') == true) return;
  if (await db.readMeta(_v1ImportedMeta) != null) return;
  final file = File('${directory.path}/countdownevents.json');
  if (!await file.exists()) return;
  final raw = await file.readAsString();
  final List<CountdownEvent> events;
  try {
    events = (jsonDecode(raw) as List)
        .map((entry) => CountdownEvent.fromJson(entry))
        .toList();
  } on FormatException catch (error) {
    debugPrint('Could not read legacy countdowns: $error');
    return;
  } on TypeError catch (error) {
    debugPrint('Could not read legacy countdowns: $error');
    return;
  }

  final settingsJson = prefs.getString('localSettings');
  final settings = settingsJson == null
      ? const LocalSettings()
      : LocalSettings.fromJson(jsonDecode(settingsJson));
  final stamp = now ?? DateTime.now();
  await db.transaction(() async {
    for (final old in events) {
      await db.saveCountdown(
        Countdown(
          title: old.title,
          dateTime: old.eventDate,
          iconSlug: slugForCodePoint(old.icon?.codePoint),
          colorArgb: (old.backgroundColor ?? const Color(0xff7877e6))
              .toARGB32(),
          fontFamily: old.fontFamily ?? 'Default',
          unit: settings.defaultUnit,
          reminders: settings.notify && old.eventDate.isAfter(stamp)
              ? const [0]
              : const [],
          createdAt: stamp,
        ),
        now: stamp,
      );
    }
    await db.writeMeta(_v1ImportedMeta, stamp.toIso8601String());
  });
  await prefs.setBool('legacyEventsImported', true);
}
