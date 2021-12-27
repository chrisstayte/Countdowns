import 'package:countdown/screens/add_countdown_page.dart';
import 'package:countdown/screens/settings_page.dart';
import 'package:countdown/utilities/my_countdowns.dart';
import 'package:countdown/widgets/countdown_card.dart';
import 'package:countdown/widgets/countdown_card_empty.dart';
import 'package:flutter/material.dart';
import 'package:provider/src/provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
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
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) {
                  return const SettingsPage();
                },
              ),
            );
          },
        ),
        actions: [
          IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) {
                      return const AddCountdownPage();
                    },
                  ),
                );
              },
              icon: const Icon(Icons.add))
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: context.watch<MyCountdowns>().events.isNotEmpty
            ? ListView.builder(
                itemCount: context.watch<MyCountdowns>().events.length,
                itemBuilder: (BuildContext context, int index) {
                  return CountdownCard(
                      event: context.watch<MyCountdowns>().events[index]);
                },
              )
            : const CountdownCardEmpty(),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
