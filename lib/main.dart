import 'dart:convert';
import 'dart:io';

import 'package:countdowns/global/global.dart';
import 'package:countdowns/models/countdown_event.dart';
import 'package:countdowns/models/event.dart';
import 'package:countdowns/providers/event_provider.dart';
import 'package:countdowns/providers/local_settings_provider.dart';
import 'package:countdowns/providers/timer_provider.dart';
import 'package:countdowns/router.dart';
import 'package:countdowns/providers/countdowns_provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  Hive.registerAdapter(EventAdapter());
  await Hive.initFlutter();
  await Hive.openBox<Event>(EventProvider.BoxName);

  // Load local settings before running app
  LocalSettingsProvider localSettingsProvider = LocalSettingsProvider();
  await localSettingsProvider.isReady;

  runApp(
    ChangeNotifierProvider(
      create: (_) => localSettingsProvider,
      child: const MyApp(),
    ),
  );

  initializeLocalNotifications();
}

void initializeLocalNotifications() async {
  const initializationSettingsAndroid = AndroidInitializationSettings(
    '@mipmap/countdowns',
  );

  var initializationSettingsIOS = const DarwinInitializationSettings(
    requestAlertPermission: false,
    requestBadgePermission: false,
    requestSoundPermission: false,
  );

  var initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsIOS,
  );
  flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  // await flutterLocalNotificationsPlugin.initialize(
  //   initializationSettings,
  //   onDidReceiveNotificationResponse: (payload) {
  //     // Handle notification tapped logic here
  //     while (router.canPop()) {
  //       router.pop();
  //     }
  //     router.push('/event/${payload.id}');
  //   },
  // );

  // final NotificationAppLaunchDetails? notificationAppLaunchDetails =
  //     await flutterLocalNotificationsPlugin.getNotificationAppLaunchDetails();

  // if (notificationAppLaunchDetails?.didNotificationLaunchApp ?? false) {
  //   // Handle notification tapped logic here
  //   while (router.canPop()) {
  //     router.pop();
  //   }
  //   router.push(
  //     '/event/${notificationAppLaunchDetails?.notificationResponse?.id ?? ''}',
  //   );
  // }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = createRouter(context);
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    ThemeMode themeMode =
        context.watch<LocalSettingsProvider>().localSettings.themeMode;

    return MaterialApp.router(
      routerConfig: _router,
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
        appBarTheme: AppBarTheme(
          color: Colors.white,
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
        listTileTheme: Theme.of(
          context,
        ).listTileTheme.copyWith(iconColor: Global.colors.secondaryColor),
      ),
      darkTheme: ThemeData(
        primaryColor: Global.colors.primaryColor,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Global.colors.primaryColor,
          brightness: Brightness.dark,
        ),
        appBarTheme: AppBarTheme(
          elevation: 0,
          scrolledUnderElevation: 4,
          centerTitle: false,
          toolbarHeight: 77,
          iconTheme: const IconThemeData(color: Colors.white),
          color: Global.colors.darkBackgroundColor,
          surfaceTintColor: Colors.transparent,
          titleTextStyle: TextStyle(
            color: Global.colors.accentColor,
            fontWeight: FontWeight.w600,
            fontSize: 24,
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: ButtonStyle(
            textStyle: MaterialStateProperty.all(
              TextStyle(
                color: Global.colors.accentColor,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            foregroundColor: MaterialStateProperty.all(
              Global.colors.accentColor,
            ),
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
