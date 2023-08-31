import 'package:countdowns/global/global.dart';
import 'package:countdowns/providers/event_provider.dart';
import 'package:countdowns/widgets/event_container.dart';
import 'package:countdowns/providers/settings_provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
        title: const Text('Events'),
        actions: [
          if (_showButton ||
              context.read<SettingsProvider>().settings.squareView == false)
            IconButton(
              onPressed: () => context.push('/eventDraft'),
              icon: const Icon(Icons.add),
            ),
          IconButton(
            onPressed: () => context.push('/settings'),
            icon: const Icon(Icons.settings),
          ),
        ],
      ),
      body: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        controller: _scrollController,
        padding: const EdgeInsets.only(
          top: 15,
          left: 15,
          right: 15,
        ),
        children: [
          CupertinoSlidingSegmentedControl(
            groupValue: context.watch<SettingsProvider>().settings.squareView,
            onValueChanged: (value) {
              if (context.read<SettingsProvider>().settings.hapticFeedback) {
                HapticFeedback.mediumImpact();
              }
              context.read<SettingsProvider>().setSquareView(value as bool);
            },
            children: const <bool, Widget>{
              true: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: Icon(Icons.apps)),
              false: Padding(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: Icon(Icons.table_rows),
              ),
            },
          ),
          const SizedBox(height: 15),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio:
                context.read<SettingsProvider>().settings.squareView ? 1 : 2.4,
            crossAxisCount:
                context.read<SettingsProvider>().settings.squareView ? 2 : 1,
            children: [
              if (context.read<SettingsProvider>().settings.squareView == true)
                GestureDetector(
                  onTap: () => context.push('/eventDraft'),
                  child: Container(
                    width: 169,
                    height: 169,
                    decoration: BoxDecoration(
                      borderRadius: Global.styles.containerCornerRadius,
                      color: Global.colors.accentColor,
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.add_rounded,
                        color: Color(0XFF4A0D67),
                        size: 50,
                      ),
                    ),
                  ),
                ),
              ...events.map(
                (event) => GestureDetector(
                  onTap: () {
                    if (context
                        .read<SettingsProvider>()
                        .settings
                        .hapticFeedback) {
                      HapticFeedback.lightImpact();
                    }
                    context.push('/event/${event.key}');
                  },
                  child: EventContainer(event: event),
                ),
              )
            ],
          ),
        ],
      ),
    );
  }
}
