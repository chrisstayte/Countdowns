import 'dart:async';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:countdowns/models/countdown_event.dart';
import 'package:countdowns/utilities/countdowns_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/src/provider.dart';

class CountdownPage extends StatefulWidget {
  final CountdownEvent countdownEvent;

  const CountdownPage({Key? key, required this.countdownEvent})
      : super(key: key);

  @override
  _CountdownPageState createState() => _CountdownPageState();
}

class _CountdownPageState extends State<CountdownPage> {
  @override
  void initState() {
    _getTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _getTime());
    super.initState();
  }

  @override
  void dispose() {
    _timer.cancel();

    super.dispose();
  }

  late Timer _timer;

  int seconds = 0;
  int minutes = 0;
  int hours = 0;
  int days = 0;
  int months = 0;
  int years = 0;

  void _getTime() {
    DateTime currentTime = DateTime.now();
    Duration timeDifference =
        widget.countdownEvent.eventDate.difference(currentTime);

    setState(() {
      seconds = timeDifference.inSeconds % 60;
      minutes = timeDifference.inMinutes % 60;
      hours = timeDifference.inHours % 24;
      days = (timeDifference.inDays % 365);

      //TODO: calculate months
      years = (timeDifference.inDays / 365.0).floor();
    });
  }

  late TextStyle numberStyle = TextStyle(
    fontSize: 50,
    fontWeight: FontWeight.bold,
    color: widget.countdownEvent.contentColor != null
        ? widget.countdownEvent.contentColor
        : widget.countdownEvent.color != null
            ? widget.countdownEvent.color!.computeLuminance() > 0.5
                ? Colors.black
                : Colors.white
            : null,
    fontFamily: widget.countdownEvent.fontFamily,
  );

  late TextStyle labelStyle = TextStyle(
    fontSize: 19,
    fontWeight: FontWeight.w300,
    color: widget.countdownEvent.contentColor != null
        ? widget.countdownEvent.contentColor
        : widget.countdownEvent.color != null
            ? widget.countdownEvent.color!.computeLuminance() > 0.5
                ? Colors.black
                : Colors.white
            : null,
    fontFamily: widget.countdownEvent.fontFamily,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(
          color: widget.countdownEvent.contentColor != null
              ? widget.countdownEvent.contentColor
              : widget.countdownEvent.color != null
                  ? widget.countdownEvent.color!.computeLuminance() > 0.5
                      ? Colors.black
                      : Colors.white
                  : null,
        ),
        title: Icon(
          widget.countdownEvent.icon ?? Icons.calendar_today,
          color: widget.countdownEvent.contentColor != null
              ? widget.countdownEvent.contentColor
              : widget.countdownEvent.color != null
                  ? widget.countdownEvent.color!.computeLuminance() > 0.5
                      ? Colors.black
                      : Colors.white
                  : null,
          size: 32.0,
        ),
        elevation: 0,
        backgroundColor: widget.countdownEvent.color ?? Colors.blue,
        actions: [
          IconButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text('Delete This Countdown?'),
                    actions: [
                      TextButton(
                        child: const Text(
                          "Yes",
                        ),
                        onPressed: () {
                          context
                              .read<CountdownsProvider>()
                              .deleteEvent(widget.countdownEvent);
                          Navigator.of(context)
                            ..pop()
                            ..pop();
                        },
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          'No',
                        ),
                      ),
                    ],
                  );
                },
              );
            },
            icon: Icon(
              Icons.delete,
              color: widget.countdownEvent.contentColor != null
                  ? widget.countdownEvent.contentColor
                  : widget.countdownEvent.color != null
                      ? widget.countdownEvent.color!.computeLuminance() > 0.5
                          ? Colors.black
                          : Colors.white
                      : null,
            ),
          )
        ],
      ),
      backgroundColor: widget.countdownEvent.color ?? Colors.blue,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 15.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: AutoSizeText(
                    widget.countdownEvent.title,
                    overflow: TextOverflow.visible,
                    maxLines: 2,
                    textAlign: TextAlign.center,
                    style: numberStyle,
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
                    "${widget.countdownEvent.eventDate.month.toString()}/${widget.countdownEvent.eventDate.day.toString()}/${widget.countdownEvent.eventDate.year.toString()}",
                    style: labelStyle,
                  ),
                ],
              ),
            ),
            Expanded(
                child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      flex: 1,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          FittedBox(
                            child: Text(
                              years.toString(),
                              style: numberStyle,
                            ),
                          ),
                          Text("Years", style: labelStyle)
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            months.toString(),
                            style: numberStyle,
                          ),
                          Text(
                            "Months",
                            style: labelStyle,
                          )
                        ],
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      flex: 1,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            days.toString(),
                            style: numberStyle,
                          ),
                          Text(
                            "Days",
                            style: labelStyle,
                          )
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            hours.toString(),
                            textAlign: TextAlign.center,
                            style: numberStyle,
                          ),
                          Text("Hours", style: labelStyle)
                        ],
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      flex: 1,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            minutes.toString(),
                            style: numberStyle,
                          ),
                          Text(
                            "Minutes",
                            style: labelStyle,
                          )
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            seconds.toString(),
                            style: numberStyle,
                          ),
                          Text(
                            "Seconds",
                            style: labelStyle,
                          )
                        ],
                      ),
                    ),
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
