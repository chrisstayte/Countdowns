import 'package:countdowns/providers/event_provider.dart';
import 'package:countdowns/screens/countdown_page.dart';
import 'package:countdowns/screens/home/event_square.dart';
import 'package:countdowns/utilities/countdowns_provider.dart';
import 'package:countdowns/utilities/settings_provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late ScrollController _scrollController;
  bool _showButton = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()
      ..addListener(() {
        bool showButton = _scrollController.position.pixels > 0;
        if (_showButton != showButton) {
          setState(() {
            _showButton = showButton;
          });
        }
      });
  }

  @override
  Widget build(BuildContext context) {
    var events = context.watch<EventProvider>().events.toList();
    events.sort(context.read<EventProvider>().sortingMethods[
        context.watch<SettingsProvider>().settings.sortingMethod]);

    return Scaffold(
        appBar: AppBar(
          title: const Text('Countdowns'),
          actions: [
            if (_showButton)
              IconButton(
                  onPressed: () => context.push('/add'), icon: Icon(Icons.add)),
            IconButton(
                onPressed: () => context.push('/settings'),
                icon: Icon(Icons.tune_rounded))
          ],
        ),
        body: SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.only(
            top: 15,
            left: 15,
            right: 15,
          ),
          child: Align(
            alignment:
                events.length > 0 ? Alignment.topCenter : Alignment.topLeft,
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                GestureDetector(
                  onTap: () => context.push('/add'),
                  child: Container(
                    width: 169,
                    height: 169,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: Color(0xffb3b2f7),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.add_rounded,
                        color: Color(0XFF4A0D67),
                        size: 50,
                      ),
                    ),
                  ),
                ),
                ...events.map((e) => CountdownSquare(event: e)).toList()
              ],
            ),
          ),
        )

        // floatingActionButton: FloatingActionButton(
        //   onPressed: () => context.push('/add'),
        //   child: Icon(
        //     Icons.add_rounded,
        //   ),
        // ),
        );
  }
}
