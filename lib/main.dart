import 'package:countdown/screens/home_page.dart';
import 'package:countdown/utilities/my_countdowns.dart';
import 'package:countdown/utilities/settings.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MyCountdowns()),
        ChangeNotifierProvider(create: (_) => Settings()),
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
    context.read<MyCountdowns>().loadEvents;
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData.light().copyWith(
        textTheme: ThemeData.light().textTheme.apply(
              fontFamily: context.watch<Settings>().fontFamily,
            ),
        primaryTextTheme: ThemeData.light().textTheme.apply(
              fontFamily: context.watch<Settings>().fontFamily,
            ),
        appBarTheme: AppBarTheme(
          color: Colors.white,
          iconTheme: const IconThemeData(color: Colors.black),
          actionsIconTheme: const IconThemeData(color: Colors.black),
          titleTextStyle: TextStyle(
            color: Colors.black,
            fontSize: 22,
            fontFamily: context.watch<Settings>().fontFamily,
          ),
        ),
      ),
      darkTheme: ThemeData.dark().copyWith(
        appBarTheme: const AppBarTheme(
          foregroundColor: Colors.white,
          actionsIconTheme: IconThemeData(color: Colors.white),
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 22,
          ),
        ),
      ),
      themeMode:
          context.watch<Settings>().darkMode ? ThemeMode.dark : ThemeMode.light,
      home: const HomePage(title: 'My Countdowns'),
    );
  }
}
