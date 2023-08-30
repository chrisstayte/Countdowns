import 'package:countdowns/global/global.dart';
import 'package:countdowns/models/event.dart';

import 'package:countdowns/providers/event_provider.dart';
import 'package:countdowns/router.dart';
import 'package:countdowns/providers/countdowns_provider.dart';
import 'package:countdowns/providers/settings_provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

void main() async {
  Hive.registerAdapter(EventAdapter());
  await Hive.initFlutter();
  await Hive.openBox<Event>(EventProvider.BoxName);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<EventProvider>(
          create: (_) => EventProvider(),
          lazy: false,
        ),
        ChangeNotifierProvider<SettingsProvider>(
          create: (_) => SettingsProvider(),
        ),
        ChangeNotifierProvider<CountdownsProvider>(
          create: (_) => CountdownsProvider(),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    int themeModeSetting = context.watch<SettingsProvider>().settings.themeMode;
    ThemeMode themeMode;
    switch (themeModeSetting) {
      case 0:
        themeMode = ThemeMode.system;
        break;
      case 1:
        themeMode = ThemeMode.light;
        break;
      case 2:
        themeMode = ThemeMode.dark;
        break;
      default:
        themeMode = ThemeMode.system;
    }

    return MaterialApp.router(
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      debugShowMaterialGrid: false,
      showPerformanceOverlay: false,
      showSemanticsDebugger: false,
      title: 'Countdowns',
      theme: ThemeData.light().copyWith(
        useMaterial3: false,
        primaryColor: Global.colors.primaryColor,
        colorScheme:
            ColorScheme.fromSeed(seedColor: Global.colors.primaryColor),
        appBarTheme: AppBarTheme(
          color: Colors.white,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 4,
          toolbarHeight: 77,
          centerTitle: false,
          iconTheme: IconThemeData(
            color: Global.colors.secondaryColor,
          ),
          titleTextStyle: TextStyle(
            color: Global.colors.secondaryColor,
            fontWeight: FontWeight.w600,
            fontSize: 24,
          ),
        ),
        scaffoldBackgroundColor: Global.colors.lightBackgroundColor,

        // textTheme: TextTheme(
        //   bodyMedium: TextStyle(
        //     color: Global.colors.darkIconColor,
        //   ),
        //   titleMedium: TextStyle(
        //     color: Global.colors.darkIconColor,
        //   ),
        //   titleLarge: TextStyle(
        //     color: Global.colors.darkIconColor,
        //   ),
        // ),
        listTileTheme: Theme.of(context).listTileTheme.copyWith(
              iconColor: Global.colors.secondaryColor,
            ),
      ),
      darkTheme: ThemeData.dark().copyWith(
        useMaterial3: false,
        brightness: Brightness.dark,
        primaryColor: Global.colors.primaryColor,
        colorScheme:
            ColorScheme.fromSeed(seedColor: Global.colors.primaryColor),
        appBarTheme: AppBarTheme(
          elevation: 0,
          scrolledUnderElevation: 4,
          centerTitle: false,
          toolbarHeight: 77,
          iconTheme: const IconThemeData(
            color: Colors.white,
          ),
          color: Global.colors.darkBackgroundColor,
          surfaceTintColor: Colors.transparent,
          titleTextStyle: TextStyle(
            color: Global.colors.accentColor,
            fontWeight: FontWeight.w600,
            fontSize: 24,
          ),
        ),
        scaffoldBackgroundColor: Global.colors.darkBackgroundColorLighter,
        cupertinoOverrideTheme: const NoDefaultCupertinoThemeData(
          textTheme:
              CupertinoTextThemeData(primaryColor: CupertinoColors.white),
        ),
        shadowColor: Colors.white,
        dialogBackgroundColor: Global.colors.darkBackgroundColor,
      ),
      themeMode: themeMode,
    );
  }
}
