import 'package:countdowns/global/global.dart';
import 'package:countdowns/models/event.dart';
import 'package:countdowns/providers/event_provider.dart';
import 'package:countdowns/providers/local_settings_provider.dart';
import 'package:countdowns/providers/notification_provider.dart';
import 'package:countdowns/router.dart';
import 'package:countdowns/storage/legacy_import.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Hive.registerAdapter(EventAdapter());
  await Hive.initFlutter();
  final box = await Hive.openBox<Event>(eventsBoxName);
  final prefs = await SharedPreferences.getInstance();
  if (!kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.android)) {
    await importLegacyData(
      await getApplicationDocumentsDirectory(),
      box,
      prefs,
    );
  }
  final notifications = EventNotifications();
  await notifications.initialize();
  runApp(
    ProviderScope(
      overrides: [
        preferencesProvider.overrideWithValue(prefs),
        notificationsProvider.overrideWithValue(notifications),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(
      localSettingsProvider.select((s) => s.themeMode),
    );
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
      themeMode: themeMode,
    );
  }
}
