import 'package:audioplayers/audioplayers.dart';
import 'package:countdowns/global/global.dart';
import 'package:countdowns/providers/local_settings_provider.dart';

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DatePickerScreen extends ConsumerStatefulWidget {
  const DatePickerScreen({super.key, this.eventDateTime, required this.allDay});

  final DateTime? eventDateTime;
  final bool allDay;

  @override
  ConsumerState<DatePickerScreen> createState() => _DatePickerScreenState();
}

class _DatePickerScreenState extends ConsumerState<DatePickerScreen> {
  late DateTime _dateTime;
  late bool _allDay;

  @override
  void initState() {
    _dateTime = widget.eventDateTime ?? DateTime.now();
    _allDay = widget.allDay;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final year = DateTime.now().year;
    final firstDate = DateTime(year - 100);
    final lastDate = DateTime(year + 100);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Date'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
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
        actions: [
          IconButton(
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
              context.pop((date: _dateTime, allDay: _allDay));
            },
            icon: const Icon(Icons.check),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: Global.styles.containerCornerRadius,
                color: Theme.of(context).cardColor,
              ),
              child: CalendarDatePicker(
                initialDate: _dateTime,
                firstDate: _dateTime.isBefore(firstDate)
                    ? _dateTime
                    : firstDate,
                lastDate: _dateTime.isAfter(lastDate) ? _dateTime : lastDate,
                onDateChanged: (dateTime) => _dateTime = DateTime(
                  dateTime.year,
                  dateTime.month,
                  dateTime.day,
                  _dateTime.hour,
                  _dateTime.minute,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                borderRadius: Global.styles.containerCornerRadius,
                color: Theme.of(context).cardColor,
              ),
              child: Column(
                children: [
                  ListTile(
                    title: _allDay ? const Text('All Day') : null,
                    leading: !_allDay
                        ? TextButton(
                            onPressed: () async {
                              await showTimePicker(
                                context: context,
                                initialTime: TimeOfDay(
                                  hour: _dateTime.hour,
                                  minute: _dateTime.minute,
                                ),
                              ).then((value) {
                                if (value != null) {
                                  setState(() {
                                    _dateTime = DateTime(
                                      _dateTime.year,
                                      _dateTime.month,
                                      _dateTime.day,
                                      value.hour,
                                      value.minute,
                                    );
                                  });
                                }
                              });
                            },
                            child: Text(
                              DateFormat("hh:mm a").format(_dateTime),
                            ),
                          )
                        : null,
                    trailing: Switch.adaptive(
                      value: _allDay,
                      onChanged: (value) => setState(() => _allDay = value),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
