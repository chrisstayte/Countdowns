import 'package:countdown/models/event.dart';
import 'package:countdown/widgets/countdown_card.dart';
import 'package:countdown/widgets/countdown_card_empty.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.grey,
        textTheme: Theme.of(context).textTheme.apply(
              bodyColor: Colors.white,
              displayColor: Colors.white,
            ),
        appBarTheme: const AppBarTheme(
          color: Colors.white,
          titleTextStyle: TextStyle(
            color: Colors.black,
            fontSize: 22,
          ),
        ),
      ),
      home: const MyHomePage(title: 'My Countdowns'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<Event> events = [
    Event(
      title: 'Jeff\'s Birthday',
      color: const Color(0XFFBB84E7),
      eventDate: DateTime(2022, 1, 5),
      icon: Icons.celebration,
    ),
    Event(
      title: 'No Icon Given',
      eventDate: DateTime(2023, 3, 4),
      color: Colors.amber,
    ),
    Event(
      title: 'No Icon or Color Given',
      eventDate: DateTime(2023, 3, 4),
    ),
    Event(
      title: 'No Icon or Color Given',
      eventDate: DateTime(2023, 3, 4),
    ),
    Event(
      title: 'No Icon or Color Given',
      eventDate: DateTime(2023, 3, 4),
    ),
    Event(
      title: 'No Icon or Color Given',
      eventDate: DateTime(2023, 3, 4),
    ),
    Event(
      title: 'No Icon or Color Given',
      eventDate: DateTime(2023, 3, 4),
    ),
    Event(
      title: 'No Icon or Color Given',
      eventDate: DateTime(2023, 3, 4),
    ),
  ];

  @override
  void initState() {
    super.initState();

    //events.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(widget.title),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.settings),
          onPressed: () {},
        ),
        actions: [IconButton(onPressed: () {}, icon: const Icon(Icons.add))],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: events.isNotEmpty
            ? ListView.builder(
                itemCount: events.length,
                itemBuilder: (BuildContext context, int index) {
                  return CountdownCard(event: events[index]);
                },
              )
            : const Padding(
                padding: EdgeInsets.only(top: 1.0),
                child: CountdownCardEmpty(),
              ),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
