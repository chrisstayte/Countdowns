import 'dart:async';

import 'package:countdowns/data/database.dart';
import 'package:countdowns/global/global.dart';
import 'package:countdowns/providers/event_provider.dart';
import 'package:countdowns/providers/local_settings_provider.dart';
import 'package:countdowns/providers/notification_provider.dart';
import 'package:countdowns/router.dart';
import 'package:countdowns/storage/startup.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final notifications = EventNotifications();
  await notifications.initialize();
  final db = AppDatabase.open();
  final mobile =
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.android);
  final documents = mobile ? await getApplicationDocumentsDirectory() : null;

  Future<void> start() async {
    final result = await prepareStorage(
      db: db,
      prefs: prefs,
      notifications: notifications,
      documents: documents,
    );
    if (result == StartupResult.migrationFailed) {
      // Never show an empty list when Hive still holds countdowns.
      runApp(StorageErrorApp(onRetry: start));
      return;
    }
    final container = ProviderContainer(
      overrides: [
        preferencesProvider.overrideWithValue(prefs),
        notificationsProvider.overrideWithValue(notifications),
        databaseProvider.overrideWithValue(db),
      ],
    );
    // Rebuild every pending notification from the new database.
    unawaited(container.read(eventsControllerProvider).rescheduleNotifications());
    runApp(UncontrolledProviderScope(container: container, child: const MyApp()));
  }

  await start();
}

/// Shown if the one-time copy from Hive fails. The Hive data is untouched.
class StorageErrorApp extends StatelessWidget {
  const StorageErrorApp({super.key, required this.onRetry});
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Your countdowns are safe, but they couldn’t be updated '
                'for this version.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 20),
              FilledButton(onPressed: onRetry, child: const Text('Try again')),
            ],
          ),
        ),
      ),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      routerConfig: ref.watch(routerProvider),
      debugShowCheckedModeBanner: false,
      debugShowMaterialGrid: false,
      showPerformanceOverlay: false,
      showSemanticsDebugger: false,
      title: 'Countdowns',
      theme: ThemeData(
        primaryColor: Global.colors.primaryColor,
        colorScheme: ColorScheme.fromSeed(
          brightness: Brightness.light,
          seedColor: Global.colors.primaryColor,
        ),
        appBarTheme: AppBarThemeData(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 4,
          toolbarHeight: 77,
          centerTitle: false,
          iconTheme: IconThemeData(color: Global.colors.secondaryColor),
          titleTextStyle: TextStyle(
            color: Global.colors.secondaryColor,
            fontWeight: FontWeight.w600,
            fontSize: 24,
          ),
        ),
        scaffoldBackgroundColor: Global.colors.lightBackgroundColor,
        listTileTheme: Theme.of(context).listTileTheme
            .copyWith(iconColor: Global.colors.secondaryColor),
      ),
      darkTheme: ThemeData(
        primaryColor: Global.colors.primaryColor,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Global.colors.primaryColor,
          brightness: Brightness.dark,
        ),
        appBarTheme: AppBarThemeData(
          elevation: 0,
          scrolledUnderElevation: 4,
          centerTitle: false,
          toolbarHeight: 77,
          iconTheme: const IconThemeData(color: Colors.white),
          backgroundColor: Global.colors.darkBackgroundColor,
          surfaceTintColor: Colors.transparent,
          titleTextStyle: TextStyle(
            color: Global.colors.accentColor,
            fontWeight: FontWeight.w600,
            fontSize: 24,
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: ButtonStyle(
            textStyle: WidgetStateProperty.all(
              TextStyle(
                color: Global.colors.accentColor,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            foregroundColor: WidgetStateProperty.all(Global.colors.accentColor),
          ),
        ),
        scaffoldBackgroundColor: Global.colors.darkBackgroundColorLighter,
        cupertinoOverrideTheme: const NoDefaultCupertinoThemeData(
          textTheme: CupertinoTextThemeData(
            primaryColor: CupertinoColors.white,
          ),
        ),
        // shadowColor: Colors.grey,
      ),
      // Dark mode is hidden for now. The stored themeMode setting is still
      // read and written unchanged so it can come back later.
      themeMode: ThemeMode.light,
    );
  }
}
