import 'package:audioplayers/audioplayers.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:countdowns/constants.dart';
import 'package:countdowns/providers/event_provider.dart';
import 'package:countdowns/providers/local_settings_provider.dart';
import 'package:countdowns/providers/timer_provider.dart';
import 'package:countdowns/screens/event_screen/time_label.dart';
import 'package:countdowns/utilities/extensions.dart';
import 'package:countdowns/widgets/event_icon.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class EventScreen extends ConsumerWidget {
  const EventScreen({super.key, required this.eventKey});

  final String? eventKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final event = ref.watch(eventByIdProvider(eventKey));
    final now = ref.watch(clockProvider);
    if (event == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Event Not Found')),
      );
    }
    final contentColor = event.textColor;
    TextStyle numberTextStyle = TextStyle(
      fontSize: 38,
      fontFamily: event.fontFamily,
      color: contentColor,
    );

    TextStyle labelTextStyle = TextStyle(
      fontSize: 32,
      fontFamily: event.fontFamily,
      color: contentColor,
    );

    Duration timeDifference = event.timeLeft(now);

    return Hero(
      tag: event.id ?? event.title,
      child: Material(
        type: MaterialType.transparency,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: event.color,
            gradient: event.backgroundGradient,
          ),
          child: Scaffold(
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              iconTheme: IconThemeData(color: contentColor),
              centerTitle: true,
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  var settings = ref.read(localSettingsProvider);
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
                  context.pop();
                },
              ),
              title: EventIcon(
                event.iconSlug ?? 'calendar',
                color: contentColor,
                size: 32,
              ),
              actions: [
                PopupMenuButton<int>(
                  icon: Icon(Icons.more_vert, color: contentColor),
                  color: contentColor,
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 1,
                      child: Text(
                        'Edit',
                        style: TextStyle(color: event.color),
                      ),
                    ),
                    PopupMenuItem(
                      value: 2,
                      child: Text(
                        'Delete',
                        style: TextStyle(color: event.color),
                      ),
                    ),
                  ],
                  onSelected: (value) async {
                    switch (value) {
                      case 1:
                        var settings = ref.read(localSettingsProvider);
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
                        await context.pushNamed(
                          AppRoutes.eventEdit,
                          pathParameters: {'id': event.id.toString()},
                        );
                        break;
                      case 2:
                        if (!(context.mounted)) return;
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              backgroundColor: contentColor,
                              title: Text(
                                'Delete This Countdown?',
                                style: TextStyle(color: event.color),
                              ),
                              actions: [
                                TextButton(
                                  child: Text(
                                    "Yes",
                                    style: TextStyle(
                                      color: event.color,
                                    ),
                                  ),
                                  onPressed: () async {
                                    var settings = ref.read(
                                      localSettingsProvider,
                                    );
                                    if (settings.hapticFeedback) {
                                      HapticFeedback.lightImpact();
                                    }
                                    if (settings.soundEffects) {
                                      AudioPlayer().play(
                                        AssetSource('sounds/trash.mp3'),
                                        ctx: AudioContext(
                                          iOS: AudioContextIOS(
                                            category:
                                                AVAudioSessionCategory.ambient,
                                          ),
                                        ),
                                        mode: PlayerMode.lowLatency,
                                      );
                                    }
                                    await ref
                                        .read(eventsControllerProvider)
                                        .deleteEvent(event.id!);
                                    if (context.mounted) {
                                      context.pop();
                                      context.goNamed(AppRoutes.home);
                                    }
                                  },
                                ),
                                TextButton(
                                  onPressed: () => context.pop(),
                                  child: Text(
                                    'No',
                                    style: TextStyle(
                                      color: event.color,
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        );
                        break;
                    }
                  },
                ),
              ],
            ),
            backgroundColor: Colors.transparent,
            body: Column(
              children: [
                Expanded(
                  child: AutoSizeText(
                    event.title,
                    maxLines: 2,
                    minFontSize: 32,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 48,
                      fontFamily: event.fontFamily,
                      color: event.textColor,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10.0),
                  child: Text(
                    DateFormat(
                      event.allDay ? "MM/dd/yyyy" : "MM/dd/yyyy hh:mm a",
                    ).format(event.dateTime),
                    style: TextStyle(
                      fontSize: 24,
                      fontFamily: event.fontFamily,
                      color: event.textColor,
                    ),
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: Column(
                    children: [
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            TimeLabel(
                              label: timeDifference.timeDifferenceOnlyYears
                                  .toString(),
                              style: numberTextStyle,
                            ),
                            TimeLabel(
                              label: 'Years',
                              style: labelTextStyle,
                              rightSide: true,
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            TimeLabel(
                              label: timeDifference.timeDifferenceOnlyDays
                                  .toString(),
                              style: numberTextStyle,
                            ),
                            TimeLabel(
                              label: 'Days',
                              style: labelTextStyle,
                              rightSide: true,
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            TimeLabel(
                              label: timeDifference.timeDifferenceOnlyHours > 0
                                  ? timeDifference.timeDifferenceOnlyHours
                                        .toString()
                                  : '0',
                              style: numberTextStyle,
                            ),
                            TimeLabel(
                              label: 'Hours',
                              style: labelTextStyle,
                              rightSide: true,
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            TimeLabel(
                              label: timeDifference.timeDifferenceOnlyMinutes
                                  .toString(),
                              style: numberTextStyle,
                            ),
                            TimeLabel(
                              label: 'Minutes',
                              style: labelTextStyle,
                              rightSide: true,
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            TimeLabel(
                              label: timeDifference.timeDifferenceOnlySeconds
                                  .toString(),
                              style: numberTextStyle,
                            ),
                            TimeLabel(
                              label: 'Seconds',
                              style: labelTextStyle,
                              rightSide: true,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
