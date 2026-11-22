import 'dart:io';

import 'package:countdowns/data/database.dart';
import 'package:countdowns/models/countdown.dart';
import 'package:countdowns/models/event.dart';
import 'package:countdowns/models/local_settings.dart';
import 'package:countdowns/providers/notification_provider.dart';
import 'package:countdowns/storage/hive_migration.dart';
import 'package:countdowns/storage/legacy_import.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'dart:convert';

const hiveEventsBox = 'events';

/// Set once the old daily-repeating notifications have been cleared.
const legacyNotificationsCancelledKey = 'legacyNotificationsCancelled';

enum StartupResult { ready, migrationFailed }

/// Gets storage ready before the UI starts:
/// 1. copies Hive into Drift once (Hive is kept as a backup),
/// 2. imports v1 JSON files straight into Drift,
/// 3. clears the old daily-repeating notifications once.
Future<StartupResult> prepareStorage({
  required AppDatabase db,
  required SharedPreferences prefs,
  required EventNotifications notifications,
  Directory? documents,
}) async {
  final settings = _settings(prefs);
  if (prefs.getBool(driftMigratedKey) != true) {
    Box<Event>? box;
    var hiveHasData = false;
    try {
      if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(EventAdapter());
      await Hive.initFlutter();
      // Never compact: the file is the backup and must not be rewritten.
      box = await Hive.openBox<Event>(
        hiveEventsBox,
        compactionStrategy: (_, _) => false,
      );
      hiveHasData = box.isNotEmpty;
    } catch (error, stack) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stack,
          library: 'hive to drift migration',
          context: ErrorDescription('opening the Hive backup'),
        ),
      );
      // If Hive can't even be opened we can't tell whether it has data, so
      // only carry on when Drift already has countdowns or no file exists.
      if (documents != null &&
          await File('${documents.path}/$hiveEventsBox.hive').exists()) {
        return StartupResult.migrationFailed;
      }
    }
    final outcome = await migrateHiveToDrift(
      db: db,
      prefs: prefs,
      box: box,
      notify: settings.notify,
      unit: settings.defaultUnit,
    );
    await box?.close();
    if (outcome == MigrationOutcome.failed && hiveHasData) {
      return StartupResult.migrationFailed;
    }
  }

  if (documents != null) {
    try {
      await importLegacyData(documents, db, prefs);
    } catch (error, stack) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stack,
          library: 'v1 import',
        ),
      );
    }
  }

  if (prefs.getBool(legacyNotificationsCancelledKey) != true) {
    try {
      // Old builds scheduled notifications that repeated every day.
      await notifications.cancelAll();
      await prefs.setBool(legacyNotificationsCancelledKey, true);
    } catch (error) {
      debugPrint('Could not clear old notifications: $error');
    }
  }
  return StartupResult.ready;
}

LocalSettings _settings(SharedPreferences prefs) {
  final json = prefs.getString('localSettings');
  if (json == null) return const LocalSettings();
  try {
    return LocalSettings.fromJson(jsonDecode(json));
  } catch (_) {
    return const LocalSettings(defaultUnit: CountUnit.days);
  }
}
