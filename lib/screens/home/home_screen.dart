import 'package:audioplayers/audioplayers.dart';
import 'package:countdowns/constants.dart';
import 'package:countdowns/global/global.dart';
import 'package:countdowns/providers/event_provider.dart';
import 'package:countdowns/providers/local_settings_provider.dart';
import 'package:countdowns/widgets/event_container.dart';
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
    _scrollController =
        ScrollController()..addListener(() {
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
    events.sort(
      context.read<EventProvider>().sortingMethods[context
          .watch<LocalSettingsProvider>()
          .localSettings
          .sortingMethod],
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Events'),
        actions: [
          if (_showButton ||
              context.read<LocalSettingsProvider>().localSettings.squareView ==
                  false)
            IconButton(
              onPressed: () {
                var settings =
                    context.read<LocalSettingsProvider>().localSettings;
                if (settings.hapticFeedback) {
                  HapticFeedback.lightImpact();
                }
                if (settings.soundEffects) {
                  AudioPlayer().play(
                    AssetSource('sounds/tap.mp3'),
                    ctx: AudioContext(
                      iOS: AudioContextIOS(
                        category: AVAudioSessionCategory.ambient,
                      ),
                    ),
                    mode: PlayerMode.lowLatency,
                  );
                }
                context.pushNamed(AppRoutes.eventNew);
              },
              icon: const Icon(Icons.add),
            ),
          IconButton(
            onPressed: () {
              var settings =
                  context.read<LocalSettingsProvider>().localSettings;
              if (settings.hapticFeedback) {
                HapticFeedback.lightImpact();
              }
              if (settings.soundEffects) {
                AudioPlayer().play(
                  AssetSource('sounds/tap.mp3'),
                  ctx: AudioContext(
                    iOS: AudioContextIOS(
                      category: AVAudioSessionCategory.ambient,
                    ),
                  ),
                  mode: PlayerMode.lowLatency,
                );
              }
              context.pushNamed(AppRoutes.settings);
            },
            icon: const Icon(Icons.settings),
          ),
        ],
      ),
      body: ListView(
        physics: const ClampingScrollPhysics(),
        controller: _scrollController,
        padding: const EdgeInsets.only(top: 15, left: 15, right: 15),
        children: [
          CupertinoSlidingSegmentedControl(
            groupValue:
                context.watch<LocalSettingsProvider>().localSettings.squareView,
            onValueChanged: (value) {
              var settings =
                  context.read<LocalSettingsProvider>().localSettings;
              if (settings.hapticFeedback) {
                HapticFeedback.mediumImpact();
              }
              if (settings.soundEffects) {
                AudioPlayer().play(
                  AssetSource('sounds/select.mp3'),
                  ctx: AudioContext(
                    iOS: AudioContextIOS(
                      category: AVAudioSessionCategory.ambient,
                    ),
                  ),
                  mode: PlayerMode.lowLatency,
                );
              }
              context.read<LocalSettingsProvider>().setSquareView(
                value as bool,
              );
            },
            children: const <bool, Widget>{
              true: Padding(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: Icon(Icons.apps),
              ),
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
                context.read<LocalSettingsProvider>().localSettings.squareView
                    ? 1
                    : 2.4,
            crossAxisCount:
                context.read<LocalSettingsProvider>().localSettings.squareView
                    ? 2
                    : 1,
            children: [
              if (context
                      .read<LocalSettingsProvider>()
                      .localSettings
                      .squareView ==
                  true)
                GestureDetector(
                  onTap: () {
                    var settings =
                        context.read<LocalSettingsProvider>().localSettings;
                    if (settings.hapticFeedback) {
                      HapticFeedback.lightImpact();
                    }
                    if (settings.soundEffects) {
                      AudioPlayer().play(
                        AssetSource('sounds/tap.mp3'),
                        ctx: AudioContext(
                          iOS: AudioContextIOS(
                            category: AVAudioSessionCategory.ambient,
                          ),
                        ),
                        mode: PlayerMode.lowLatency,
                      );
                    }
                    context.pushNamed(AppRoutes.eventNew);
                  },
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
                    var settings =
                        context.read<LocalSettingsProvider>().localSettings;
                    if (settings.hapticFeedback) {
                      HapticFeedback.lightImpact();
                    }
                    if (settings.soundEffects) {
                      AudioPlayer().play(
                        AssetSource('sounds/tap.mp3'),
                        ctx: AudioContext(
                          iOS: AudioContextIOS(
                            category: AVAudioSessionCategory.ambient,
                          ),
                        ),
                        mode: PlayerMode.lowLatency,
                      );
                    }
                    context.pushNamed(
                      AppRoutes.event,
                      pathParameters: {'id': event.key.toString()},
                    );
                  },
                  child: EventContainer(event: event),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
