import 'package:countdown/screens/home_page.dart';
import 'package:countdown/utilities/my_countdowns.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MyCountdowns()),
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
      theme: ThemeData(
        primarySwatch: Colors.grey,
        // textTheme: GoogleFonts.latoTextTheme(
        //   Theme.of(context).textTheme,
        // ),
        textTheme: Theme.of(context).textTheme.apply(),
        appBarTheme: const AppBarTheme(
          color: Colors.white,
          titleTextStyle: TextStyle(
            color: Colors.black,
            fontSize: 22,
          ),
        ),
      ),
      darkTheme: ThemeData(
        primarySwatch: Colors.grey,
        textTheme: Theme.of(context).textTheme.apply(
              bodyColor: Colors.black,
            ),
        appBarTheme: const AppBarTheme(
          foregroundColor: Colors.white,
          color: Colors.black,
          actionsIconTheme: IconThemeData(color: Colors.white),
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 22,
          ),
        ),
      ),
      themeMode: ThemeMode.light,
      home: const HomePage(title: 'My Countdowns'),
    );
  }
}
