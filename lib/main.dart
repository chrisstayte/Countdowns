import 'dart:convert';
import 'dart:io';

import 'package:countdowns/global/global.dart';
import 'package:countdowns/models/countdown_event.dart';
import 'package:countdowns/models/event.dart';
import 'package:countdowns/providers/event_provider.dart';
import 'package:countdowns/providers/timer_provider.dart';
import 'package:countdowns/router.dart';
import 'package:countdowns/providers/countdowns_provider.dart';
import 'package:countdowns/providers/settings_provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  Hive.registerAdapter(EventAdapter());

  /// Initializes Hive for Flutter and opens the [Event] box.
  await Hive.initFlutter();
  await Hive.openBox<Event>(EventProvider.BoxName);

  // This is done as a precaution of v1 users who have not updated to v2 yet
  loadV1Events();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<EventProvider>(
          create: (_) => EventProvider(),
          lazy: false,
        ),
        ChangeNotifierProvider<SettingsProvider>(
          create: (_) => SettingsProvider(),
          lazy: false,
        ),
        ChangeNotifierProvider<CountdownsProvider>(
          create: (_) => CountdownsProvider(),
        ),
        ChangeNotifierProvider<TimerProvider>(
          create: (_) => TimerProvider(),
        )
      ],
      child: const MyApp(),
    ),
  );

  initializeLocalNotifications();
}

void initializeLocalNotifications() async {
  const initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/countdowns');

  var initializationSettingsIOS = const DarwinInitializationSettings(
    requestAlertPermission: false,
    requestBadgePermission: false,
    requestSoundPermission: false,
  );

  var initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid, iOS: initializationSettingsIOS);
  flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  await flutterLocalNotificationsPlugin.initialize(initializationSettings,
      onDidReceiveNotificationResponse: (payload) {
    // Handle notification tapped logic here
    while (router.canPop()) {
      router.pop();
    }
    router.push('/event/${payload.id}');
  });

  final NotificationAppLaunchDetails? notificationAppLaunchDetails =
      await flutterLocalNotificationsPlugin.getNotificationAppLaunchDetails();

  if (notificationAppLaunchDetails?.didNotificationLaunchApp ?? false) {
    // Handle notification tapped logic here
    while (router.canPop()) {
      router.pop();
    }
    router.push(
        '/event/${notificationAppLaunchDetails?.notificationResponse?.id ?? ''}');
  }
}

void loadV1Events() async {
  final directory = await getApplicationDocumentsDirectory();
  File v1File = File('${directory.path}/countdownevents.json');

  if (v1File.existsSync()) {
    String v1Events = v1File.readAsStringSync();
    List<dynamic> v1EventsList = jsonDecode(v1Events);
    List<CountdownEvent> events =
        v1EventsList.map((e) => CountdownEvent.fromJson(e)).toList();

    final Box<Event> box = Hive.box<Event>(EventProvider.BoxName);

    for (var event in events) {
      Event existingEvent = Event(
        title: event.title,
        eventDateTime: event.eventDate,
        backgroundColor: event.backgroundColor ?? Global.colors.primaryColor,
        icon: event.icon,
      );

      if (event.fontFamily != null) {
        existingEvent.fontFamily = event.fontFamily!;
      }

      box.add(existingEvent);
    }

    v1File.deleteSync();
  }
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
        colorScheme: ColorScheme.fromSeed(
          seedColor: Global.colors.primaryColor,
          brightness: Brightness.dark,
        ),
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
        textButtonTheme: TextButtonThemeData(
          style: ButtonStyle(
            textStyle: MaterialStateProperty.all(
              TextStyle(
                color: Global.colors.accentColor,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            foregroundColor:
                MaterialStateProperty.all(Global.colors.accentColor),
          ),
        ),
        scaffoldBackgroundColor: Global.colors.darkBackgroundColorLighter,
        cupertinoOverrideTheme: const NoDefaultCupertinoThemeData(
          textTheme:
              CupertinoTextThemeData(primaryColor: CupertinoColors.white),
        ),
        // shadowColor: Colors.grey,
      ),
      themeMode: themeMode,
    );
  }
}
