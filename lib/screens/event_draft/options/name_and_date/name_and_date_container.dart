import 'package:audioplayers/audioplayers.dart';
import 'package:countdowns/providers/settings_provider.dart';
import 'package:countdowns/screens/event_draft/options/name_and_date/date_picker_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

typedef OnDateTimeChanged = void Function(DateTime dateTime);
typedef OnAllDayChanged = void Function(bool allDay);

class NameAndDateContainer extends StatelessWidget {
  const NameAndDateContainer({
    super.key,
    required this.controller,
    required this.eventDateTime,
    required this.onDateTimeChanged,
    required this.allDay,
    required this.onAllDayChanged,
    required this.shouldShakeName,
  });

  final TextEditingController controller;
  final DateTime eventDateTime;
  final OnDateTimeChanged onDateTimeChanged;
  final bool allDay;
  final OnAllDayChanged onAllDayChanged;
  final bool shouldShakeName;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 15,
        vertical: 15,
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              vertical: 5,
              horizontal: 15,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(
                15,
              ),
              color: Theme.of(context).scaffoldBackgroundColor,
            ),
            child: Row(
              children: [
                Icon(Icons.title),
                const SizedBox(
                  width: 15,
                ),
                Expanded(
                  child: TextField(
                    controller: controller,
                    enableSuggestions: false,
                    decoration: const InputDecoration(
                      hintText: 'Event Name',
                      hintStyle: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                      border: InputBorder.none,
                    ),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Visibility(
                  visible: controller.text.isNotEmpty,
                  child: IconButton(
                    onPressed: () => {
                      controller.clear(),
                      FocusManager.instance.primaryFocus?.unfocus(),
                    },
                    icon: const Icon(
                      Icons.clear,
                    ),
                  ),
                ),
              ],
            ),
          )
              .animate(
                target: shouldShakeName ? 1 : 0,
                autoPlay: false,
              )
              .shakeX(),
          const SizedBox(
            height: 5,
          ),
          GestureDetector(
            onTap: () async {
              // hide the keyboard if it's open
              FocusManager.instance.primaryFocus?.unfocus();
              var settings = context.read<SettingsProvider>().settings;
              if (settings.hapticFeedback) {
                HapticFeedback.lightImpact();
              }
              if (settings.soundEffects) {
                AudioPlayer().play(AssetSource('sounds/tap.mp3'),
                    ctx: const AudioContext(
                      iOS: AudioContextIOS(
                        category: AVAudioSessionCategory.ambient,
                      ),
                    ),
                    mode: PlayerMode.lowLatency);
              }
              await Navigator.of(context)
                  .push(
                MaterialPageRoute(
                  builder: (context) => DatePickerScreen(
                    eventDateTime: eventDateTime,
                    allDay: allDay,
                  ),
                ),
              )
                  .then((result) {
                if (result != null) {
                  onDateTimeChanged(result[0]);
                  onAllDayChanged(result[1]);
                }
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                vertical: 10,
                horizontal: 15,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(
                  15,
                ),
                color: Theme.of(context).scaffoldBackgroundColor,
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_month_rounded,
                    size: 28,
                  ),
                  const SizedBox(
                    width: 15,
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat('MM/dd/yyyy').format(eventDateTime),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        allDay
                            ? 'All Day'
                            : DateFormat("hh:mm a").format(eventDateTime),
                      ),
                    ],
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.arrow_right,
                    size: 28,
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
