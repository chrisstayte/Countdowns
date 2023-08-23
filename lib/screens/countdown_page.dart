import 'dart:async';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:countdowns/global/global.dart';
import 'package:countdowns/models/countdown_event.dart';
import 'package:countdowns/models/event.dart';
import 'package:countdowns/providers/event_provider.dart';
import 'package:countdowns/screens/edit_countdown_page.dart';
import 'package:countdowns/utilities/countdowns_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/src/provider.dart';

class CountdownPage extends StatefulWidget {
  //final CountdownEvent countdownEvent;
  final dynamic countdownEventKey;

  const CountdownPage({Key? key, required this.countdownEventKey})
      : super(key: key);

  @override
  _CountdownPageState createState() => _CountdownPageState();
}

class _CountdownPageState extends State<CountdownPage> {
  bool _eventOccured = false;
  late Timer _timer;
  late final Event _countdownEvent;

  int seconds = 0;
  int minutes = 0;
  int hours = 0;
  int days = 0;
  int months = 0;
  int years = 0;

  @override
  void initState() {
    super.initState();
    var provider = Provider.of<EventProvider>(context, listen: false);
    var key = provider.box.keys.elementAt(int.parse(widget.countdownEventKey));
    _countdownEvent = provider.box.get(key) ??
        Event(title: "ERROR", eventDate: DateTime.now());

    _getTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _getTime());
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  bool _getTime() {
    DateTime currentTime = DateTime.now();
    Duration timeDifference = _countdownEvent.eventDate.difference(currentTime);

    if (timeDifference < Duration.zero) {
      if (!_eventOccured) {
        seconds = 0;
        minutes = 0;
        hours = 0;
        days = 0;
        years = 0;

        setState(() => _eventOccured = true);
      }
      return true;
    } else {
      setState(() {
        seconds = timeDifference.inSeconds % 60;
        minutes = timeDifference.inMinutes % 60;
        hours = timeDifference.inHours % 24;
        days = (timeDifference.inDays % 365);
        years = (timeDifference.inDays / 365.0).floor();
      });
      return false;
    }
  }

  Color _backgroundColor() =>
      _countdownEvent.backgroundColor ?? Global.colors.defaultBackgroundColor;

  Color _contentColor() => _countdownEvent.contentColor != null
      ? _countdownEvent.contentColor!
      : _countdownEvent.backgroundColor != null
          ? _countdownEvent.backgroundColor!.computeLuminance() > 0.5
              ? Colors.black
              : Colors.white
          : Colors.white;

  TextStyle numberStyle() => TextStyle(
        fontSize: 50,
        fontWeight: FontWeight.bold,
        color: _contentColor(),
        fontFamily: _countdownEvent.fontFamily,
      );

  TextStyle labelStyle() => TextStyle(
        fontSize: 19,
        fontWeight: FontWeight.w300,
        color: _contentColor(),
        fontFamily: _countdownEvent.fontFamily,
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(
          color: _contentColor(),
        ),
        title: Icon(
          _countdownEvent.icon ?? Icons.calendar_today,
          color: _contentColor(),
          size: 32.0,
        ),
        elevation: 0,
        backgroundColor: _backgroundColor(),
        actions: [
          PopupMenuButton<int>(
            icon: Icon(
              Icons.more_vert,
              color: _contentColor(),
            ),
            color: _contentColor(),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 1,
                child: Text(
                  'Edit',
                  style: TextStyle(
                    color: _backgroundColor(),
                  ),
                ),
              ),
              PopupMenuItem(
                value: 2,
                child: Text(
                  'Delete',
                  style: TextStyle(
                    color: _backgroundColor(),
                  ),
                ),
              ),
            ],
            onSelected: (value) async {
              switch (value) {
                case 1:
                  // await Navigator.push(
                  //   context,
                  //   MaterialPageRoute(
                  //     builder: (context) {
                  //       return EditCountdownPage(
                  //           countdownEvent: _countdownEvent);
                  //     },
                  //   ),
                  // );
                  setState(() {
                    _eventOccured = _getTime();
                  });
                  break;
                case 2:
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        backgroundColor: _contentColor(),
                        title: Text(
                          'Delete This Countdown?',
                          style: TextStyle(
                            color: _backgroundColor(),
                          ),
                        ),
                        actions: [
                          TextButton(
                            child: Text(
                              "Yes",
                              style: TextStyle(
                                color: _backgroundColor(),
                              ),
                            ),
                            onPressed: () {
                              // context
                              //     .read<CountdownsProvider>()
                              //     .deleteEvent(_countdownEvent);
                              // Navigator.of(context)
                              //   ..pop()
                              //   ..pop();
                            },
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(
                              'No',
                              style: TextStyle(
                                color: _backgroundColor(),
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

          // )
        ],
      ),
      backgroundColor: _backgroundColor(),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 15.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Visibility(
              visible: _eventOccured,
              child: Chip(
                backgroundColor: _contentColor(),
                avatar: CircleAvatar(
                  backgroundColor: _backgroundColor(),
                  child: Icon(
                    Icons.check,
                    color: _contentColor(),
                  ),
                ),
                label: Text(
                  'Complete',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _backgroundColor(),
                  ),
                ),
              ),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: AutoSizeText(
                    _countdownEvent.title,
                    overflow: TextOverflow.visible,
                    maxLines: 2,
                    minFontSize: 14,
                    textAlign: TextAlign.center,
                    style: numberStyle(),
                  ),
                ),
              ],
            ),
            SizedBox(
              height: 40,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "${_countdownEvent.eventDate.month.toString()}/${_countdownEvent.eventDate.day.toString()}/${_countdownEvent.eventDate.year.toString()}",
                    style: labelStyle(),
                  ),
                ],
              ),
            ),
            Expanded(
                child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FittedBox(
                      child: Text(
                        years.toString(),
                        style: numberStyle(),
                      ),
                    ),
                    const SizedBox(
                      width: 10,
                    ),
                    Text("Years", style: labelStyle())
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      days.toString(),
                      style: numberStyle(),
                    ),
                    const SizedBox(
                      width: 10,
                    ),
                    Text(
                      "Days",
                      style: labelStyle(),
                    )
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      hours.toString(),
                      textAlign: TextAlign.center,
                      style: numberStyle(),
                    ),
                    const SizedBox(
                      width: 10,
                    ),
                    Text("Hours", style: labelStyle())
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      minutes.toString(),
                      style: numberStyle(),
                    ),
                    const SizedBox(
                      width: 10,
                    ),
                    Text(
                      "Minutes",
                      style: labelStyle(),
                    )
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      seconds.toString(),
                      style: numberStyle(),
                    ),
                    const SizedBox(
                      width: 10,
                    ),
                    Text(
                      "Seconds",
                      style: labelStyle(),
                    )
                  ],
                )
              ],
            ))
          ],
        ),
      ),
    );
  }
}
