import 'dart:ffi';

import 'package:countdowns/models/countdown_event.dart';
import 'package:countdowns/screens/add_countdown_page.dart';
import 'package:countdowns/screens/countdown_page.dart';
import 'package:countdowns/screens/settings_page.dart';
import 'package:countdowns/utilities/countdowns_provider.dart';
import 'package:countdowns/widgets/countdown_card.dart';
import 'package:countdowns/widgets/countdown_card_builder.dart';
import 'package:flutter/cupertino.dart';
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
    // I was loading the list here
    context.read<CountdownsProvider>().loadEvents();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.settings_outlined),
          onPressed: () {
            // UPDATE: Add ios style modal on top another
            // Navigator.push(
            //   context,
            //   PageRouteBuilder(
            //     transitionDuration: const Duration(milliseconds: 500),
            //     pageBuilder: (context, _, __) {
            //       return const SettingsPage();
            //     },
            //     transitionsBuilder: (context, primaryRouteAnimation,
            //         secondaryRouteAnimation, child) {
            //       return CupertinoFullscreenDialogTransition(
            //         primaryRouteAnimation: primaryRouteAnimation,
            //         secondaryRouteAnimation: secondaryRouteAnimation,
            //         child: child,
            //         linearTransition: true,
            //       );
            //     },
            //   ),
            // );
            Navigator.push(
              context,
              MaterialPageRoute(
                fullscreenDialog: true,
                builder: (context) {
                  return const SettingsPage();
                },
              ),
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
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
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: context.watch<CountdownsProvider>().events.isNotEmpty
            ? ListView.builder(
                itemCount: context.read<CountdownsProvider>().events.length,
                itemBuilder: (BuildContext context, int index) {
                  return GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CountdownPage(
                          countdownEvent:
                              context.read<CountdownsProvider>().events[index],
                        ),
                      ),
                    ),
                    child: CountdownCard(
                      countdownEvent:
                          context.read<CountdownsProvider>().events[index],
                    ),
                  );
                },
              )
            : GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) {
                      return const AddCountdownPage();
                    },
                  ),
                ),
                child: Hero(
                  tag: 'emptycard',
                  child: Material(
                    type: MaterialType.transparency,
                    child: const CountdownCardBuilder(
                      title: 'Create a countdown',
                    ),
                  ),
                ),
              ),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
