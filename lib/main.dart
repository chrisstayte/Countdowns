import 'dart:async';

import 'package:countdowns/data/database.dart';
import 'package:countdowns/theme/app_theme.dart';
import 'package:countdowns/widgets_bridge/widget_snapshot.dart';
import 'package:countdowns/providers/event_provider.dart';
import 'package:countdowns/providers/local_settings_provider.dart';
import 'package:countdowns/providers/notification_provider.dart';
import 'package:countdowns/router.dart';
import 'package:countdowns/screens/event_screen/event_screen.dart';
import 'package:countdowns/screens/share/share_sheet.dart';
import 'package:countdowns/storage/photos.dart';
import 'package:countdowns/stock/stock_provider.dart';
import 'package:countdowns/storage/startup.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  openShareSheet = showShareSheet;
  final prefs = await SharedPreferences.getInstance();
  final notifications = EventNotifications();
  await notifications.initialize();
  final db = AppDatabase.open();
  final mobile =
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.android);
  final documents = mobile ? await getApplicationDocumentsDirectory() : null;
  PhotoStore.setUp(documents ?? await getApplicationSupportDirectory());
  // Stock photo pages and downloads are disposable: keep them in caches.
  try {
    stockCacheRoot = await getApplicationCacheDirectory();
  } catch (_) {}

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
    // Keep the home and lock screen widgets' snapshot current.
    final widgets = WidgetSnapshotWriter();
    container.listen(eventsStreamProvider, (_, next) {
      final events = next.value;
      if (events != null) unawaited(widgets.write(events));
    }, fireImmediately: true);
    // Rebuild every pending notification from the new database.
    unawaited(
      container.read(eventsControllerProvider).rescheduleNotifications(),
    );
    // Flutter draws nothing before runApp, so the native splash (Paper and
    // the icon mark) stays up through storage setup and this first read.
    // Waiting for it means the first frame is Home with its countdowns, not
    // a flash of the empty state. Capped so a slow read can't hold launch.
    try {
      await container
          .read(eventsStreamProvider.future)
          .timeout(const Duration(seconds: 3));
    } catch (_) {
      // Draw anyway; Home fills in when the read lands.
    }
    runApp(
      UncontrolledProviderScope(container: container, child: const MyApp()),
    );
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
    theme: buildAppTheme(),
    home: Scaffold(
      backgroundColor: AppColors.ground,
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
      theme: buildAppTheme(),
      // Dark mode is hidden for now. The stored themeMode setting is still
      // read and written unchanged so it can come back later.
      themeMode: ThemeMode.light,
      // Dark status bar text on Paper by default. Screens on dark grounds
      // (wall mode, crop, photo details) put their own light region on top,
      // and leaving them falls back to this one instead of keeping theirs.
      builder: (context, child) => AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark,
        child: child!,
      ),
    );
  }
}
