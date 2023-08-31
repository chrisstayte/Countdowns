import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:countdowns/models/event.dart';
import 'package:countdowns/providers/event_provider.dart';
import 'package:countdowns/providers/settings_provider.dart';
import 'package:countdowns/providers/timer_provider.dart';
import 'package:countdowns/screens/event_screen/time_label.dart';
import 'package:countdowns/utilities/extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class EventScreen extends StatefulWidget {
  const EventScreen({super.key, required this.eventKey});

  final String? eventKey;

  @override
  State<EventScreen> createState() => _EventScreenState();
}

class _EventScreenState extends State<EventScreen> {
  late final Event? _event;
  late Color _contentColor;

  @override
  void initState() {
    super.initState();

    _event = context.read<EventProvider>().getEvent(widget.eventKey);
    _contentColor = _event?.backgroundColor.contentColor ?? Colors.white;
  }

  @override
  Widget build(BuildContext context) {
    context.watch<TimerProvider>();
    TextStyle numberTextStyle = TextStyle(
      fontSize: 38,
      fontFamily: _event?.fontFamily,
      color: _contentColor,
    );

    TextStyle labelTextStyle = TextStyle(
      fontSize: 32,
      fontFamily: _event?.fontFamily,
      color: _contentColor,
    );

    if (_event == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(
          child: Text('Event Not Found'),
        ),
      );
    }

    Duration timeDifference = _event!.getTimeDifference();

    return Hero(
      tag: _event!.key ?? _event!.title,
      child: Material(
        type: MaterialType.transparency,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: _event!.backgroundColor,
            gradient: _event!.backgroundGradient
                ? _event!.backgroundColor.gradient
                : null,
          ),
          child: Scaffold(
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              iconTheme: IconThemeData(color: _contentColor),
              centerTitle: true,
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  var settings = context.read<SettingsProvider>().settings;
                  if (settings.hapticFeedback) {
                    HapticFeedback.lightImpact();
                  }
                  if (settings.soundEffects) {
                    AudioPlayer().play(AssetSource('sounds/tap.mp3'),
                        mode: PlayerMode.lowLatency);
                  }
                  context.pop();
                },
              ),
              title: Icon(
                _event!.icon ?? Icons.event,
                color: _contentColor,
                size: 32,
              ),
              actions: [
                PopupMenuButton<int>(
                  icon: Icon(
                    Icons.more_vert,
                    color: _contentColor,
                  ),
                  color: _contentColor,
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 1,
                      child: Text(
                        'Edit',
                        style: TextStyle(
                          color: _event!.backgroundColor,
                        ),
                      ),
                    ),
                    PopupMenuItem(
                      value: 2,
                      child: Text(
                        'Delete',
                        style: TextStyle(
                          color: _event!.backgroundColor,
                        ),
                      ),
                    ),
                  ],
                  onSelected: (value) async {
                    switch (value) {
                      case 1:
                        var settings =
                            context.read<SettingsProvider>().settings;
                        if (settings.hapticFeedback) {
                          HapticFeedback.lightImpact();
                        }
                        if (settings.soundEffects) {
                          AudioPlayer().play(AssetSource('sounds/tap.mp3'),
                              mode: PlayerMode.lowLatency);
                        }
                        await context.push('/eventDraft/${_event?.key}');
                        setState(() {
                          _contentColor = _event!.backgroundColor.contentColor;
                        });
                        break;
                      case 2:
                        if (!(context.mounted)) return;
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              backgroundColor: _contentColor,
                              title: Text(
                                'Delete This Countdown?',
                                style:
                                    TextStyle(color: _event!.backgroundColor),
                              ),
                              actions: [
                                TextButton(
                                  child: Text(
                                    "Yes",
                                    style: TextStyle(
                                      color: _event!.backgroundColor,
                                    ),
                                  ),
                                  onPressed: () {
                                    var settings = context
                                        .read<SettingsProvider>()
                                        .settings;
                                    if (settings.hapticFeedback) {
                                      HapticFeedback.lightImpact();
                                    }
                                    if (settings.soundEffects) {
                                      AudioPlayer().play(
                                          AssetSource('sounds/trash.mp3'),
                                          mode: PlayerMode.lowLatency);
                                    }
                                    context
                                        .read<EventProvider>()
                                        .deleteEvent(_event!);
                                    Navigator.popUntil(
                                        context, ModalRoute.withName('/'));
                                  },
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: Text(
                                    'No',
                                    style: TextStyle(
                                      color: _event!.backgroundColor,
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
            body: Column(children: [
              Expanded(
                child: AutoSizeText(
                  _event!.title,
                  maxLines: 2,
                  minFontSize: 32,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 48,
                    fontFamily: _event!.fontFamily,
                    color: _event!.backgroundColor.contentColor,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10.0),
                child: Text(
                  DateFormat(
                    _event!.allDayEvent ? "MM/dd/yyyy" : "MM/dd/yyyy hh:mm a",
                  ).format(_event!.eventDateTime),
                  style: TextStyle(
                    fontSize: 24,
                    fontFamily: _event!.fontFamily,
                    color: _event!.backgroundColor.contentColor,
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
              )
            ]),
          ),
        ),
      ),
    );
  }
}
