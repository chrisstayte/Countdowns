import 'package:countdowns/global/global.dart';
import 'package:countdowns/models/event.dart';
import 'package:countdowns/providers/event_provider.dart';
import 'package:countdowns/router.dart';
import 'package:countdowns/screens/home/home_screen.dart';
import 'package:countdowns/screens/home_page.dart';
import 'package:countdowns/utilities/countdowns_provider.dart';
import 'package:countdowns/utilities/settings_provider.dart';
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
        themeMode = ThemeMode.light;
        break;
      case 1:
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
          appBarTheme: AppBarTheme(
            color: Colors.white,
            elevation: 0,
            iconTheme: IconThemeData(
              //color: Color(0XFF536372),
              color: Colors.black,
            ),
            titleTextStyle: TextStyle(
              color: Color(0XFF4A0D67),
              fontWeight: FontWeight.w600,
              fontSize: 24,
            ),
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor: Global.colors.lightIconColorDarker,
            ),
          ),
          scaffoldBackgroundColor: Colors.white,
          chipTheme: Theme.of(context).chipTheme.copyWith(
                backgroundColor: Global.colors.lightIconColorDarker,
                labelStyle: TextStyle(
                  color: Global.colors.lightIconColor,
                ),
              ),
          textTheme: TextTheme(
            bodyMedium: TextStyle(
              color: Global.colors.darkIconColor,
            ),
            titleMedium: TextStyle(
              color: Global.colors.darkIconColor,
            ),
            titleLarge: TextStyle(
              color: Global.colors.darkIconColor,
            ),
          ),
          listTileTheme: Theme.of(context).listTileTheme.copyWith(
              // iconColor: Global.colors.lightIconColorDarker,
              ),
          floatingActionButtonTheme: FloatingActionButtonThemeData(
            backgroundColor: Color(0xff7877E6),
            foregroundColor: Global.colors.lightIconColor,
          )),
      darkTheme: ThemeData.dark().copyWith(
        appBarTheme: AppBarTheme(
          elevation: 0,
          backgroundColor: Global.colors.darkIconColor,
          foregroundColor: Global.colors.lightIconColor,
          actionsIconTheme: IconThemeData(
            color: Global.colors.darkIconColorLighter,
          ),
          iconTheme: IconThemeData(
            //color: Color(0XFF536372),
            color: Global.colors.darkIconColorLighter,
          ),
          titleTextStyle: TextStyle(
            color: Global.colors.lightIconColor,
            fontSize: 26,
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: Global.colors.darkIconColorLighter,
          ),
        ),
        scaffoldBackgroundColor: Global.colors.darkIconColor,
        cupertinoOverrideTheme: const NoDefaultCupertinoThemeData(
          textTheme:
              CupertinoTextThemeData(primaryColor: CupertinoColors.white),
        ),
        switchTheme: SwitchThemeData(
          thumbColor: MaterialStateProperty.all(
            Global.colors.lightIconColor,
          ),
          trackColor: MaterialStateProperty.all(
            Global.colors.lightIconColorDarker,
          ),
        ),
      ),
      themeMode: themeMode,
    );
  }
}
