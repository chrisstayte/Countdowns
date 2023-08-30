import 'dart:async';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:countdowns/models/event.dart';
import 'package:countdowns/providers/event_provider.dart';
import 'package:countdowns/screens/event_screen/time_label.dart';
import 'package:countdowns/utilities/extensions.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
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
  late final Timer _timer;
  late Color _contentColor;

  @override
  void initState() {
    super.initState();

    _event = context.read<EventProvider>().getEvent(widget.eventKey);
    _contentColor = _event!.backgroundColor.contentColor;

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    TextStyle numberTextStyle = TextStyle(
      fontSize: 38,
      fontFamily: _event!.fontFamily,
      color: _contentColor,
    );

    TextStyle labelTextStyle = TextStyle(
      fontSize: 32,
      fontFamily: _event!.fontFamily,
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

    return Container(
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
                            style: TextStyle(color: _event!.backgroundColor),
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
            flex: 1,
            child:
                Column(mainAxisAlignment: MainAxisAlignment.center, children: [
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
              const SizedBox(height: 10),
              Text(
                DateFormat(
                  _event!.allDayEvent ? "MM/dd/yyyy" : "MM/dd/yyyy hh:mm a",
                ).format(_event!.eventDateTime),
                style: TextStyle(
                  fontSize: 24,
                  fontFamily: _event!.fontFamily,
                  color: _event!.backgroundColor.contentColor,
                ),
              ),
            ]),
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
                        label: _event!.getTimeDifferenceInYears().toString(),
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
                        label: _event!.getTimeDifferenceInDays().toString(),
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
                        label: _event!.getTimeDifferenceInHours().toString(),
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
                        label: _event!.getTimeDifferenceInMinutes().toString(),
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
                        label: _event!.getTimeDifferenceInSeconds().toString(),
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
    );
  }
}
