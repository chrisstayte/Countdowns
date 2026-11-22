import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:ui';

import 'package:countdowns/models/countdown_event.dart';
import 'package:countdowns/models/event.dart';
import 'package:countdowns/models/local_settings.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Imports files written by the original mobile releases before the UI starts.
Future<void> importLegacyData(
  Directory directory,
  Box<Event> box,
  SharedPreferences prefs,
) async {
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

  if (prefs.getBool('legacyEventsImported') == true) return;
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

  // Reuse the same integer keys if startup is interrupted after the Hive write.
  final first =
      prefs.getInt('legacyEventsFirstKey') ??
      box.keys.whereType<int>().fold(-1, max) + 1;
  if (!await prefs.setInt('legacyEventsFirstKey', first)) {
    throw StateError('Could not record the countdown import position');
  }
  await box.putAll({
    for (final (index, old) in events.indexed)
      if (!box.containsKey(first + index))
        first + index: Event(
          title: old.title,
          eventDateTime: old.eventDate,
          icon: old.icon,
          backgroundColor: old.backgroundColor ?? const Color(0xff7877e6),
          contentColor: old.contentColor,
          fontFamily: old.fontFamily ?? 'Default',
        ),
  });
  if (!await prefs.setBool('legacyEventsImported', true)) {
    throw StateError('Could not finish the countdown import');
  }
}
