import 'package:countdowns/global/global.dart';
import 'package:countdowns/screens/home_page.dart';
import 'package:countdowns/utilities/countdowns_provider.dart';
import 'package:countdowns/utilities/settings_provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
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
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      debugShowMaterialGrid: false,
      showPerformanceOverlay: false,
      showSemanticsDebugger: false,
      title: 'Countdowns',
      theme: ThemeData.light().copyWith(
        appBarTheme: AppBarTheme(
          color: Global.colors.lightIconColor,
          elevation: 0,
          iconTheme: IconThemeData(
            //color: Color(0XFF536372),
            color: Global.colors.lightIconColorDarker,
          ),
          actionsIconTheme: IconThemeData(
            //color: Color(0XFF536372),
            color: Global.colors.lightIconColorDarker,
          ),
          titleTextStyle: TextStyle(
            color: Global.colors.darkIconColor,
            fontFamily: 'DiarioDeAndy',
            fontSize: 26,
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            primary: Global.colors.lightIconColorDarker,
          ),
        ),
        scaffoldBackgroundColor: Global.colors.lightIconColor,
        chipTheme: Theme.of(context).chipTheme.copyWith(
              backgroundColor: Global.colors.lightIconColorDarker,
              labelStyle: TextStyle(
                color: Global.colors.lightIconColor,
              ),
            ),
        textTheme: TextTheme(
          bodyText2: TextStyle(
            color: Global.colors.darkIconColor,
          ),
          subtitle1: TextStyle(
            color: Global.colors.darkIconColor,
          ),
          headline6: TextStyle(
            color: Global.colors.darkIconColor,
          ),
        ),
        listTileTheme: Theme.of(context).listTileTheme.copyWith(
              iconColor: Global.colors.lightIconColorDarker,
            ),
      ),
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
            fontFamily: 'DiarioDeAndy',
            fontSize: 26,
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            primary: Global.colors.darkIconColorLighter,
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
      themeMode: context.watch<SettingsProvider>().settings.darkMode
          ? ThemeMode.dark
          : ThemeMode.light,
      home: const HomePage(title: 'Countdowns'),
    );
  }
}
