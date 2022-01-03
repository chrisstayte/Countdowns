import 'dart:async';

import 'package:countdowns/models/countdown_event.dart';
import 'package:countdowns/screens/countdown_page.dart';

import 'package:flutter/material.dart';

/// This countdown card is used to show on the homescreen.
/// It takes a [CountdownEvent] object and sets the information on the card accordingly
class CountdownCard extends StatelessWidget {
  final CountdownEvent countdownEvent;

  const CountdownCard({Key? key, required this.countdownEvent})
      : super(key: key);

  List<Widget> _getStatus() {
    List<Widget> widgets = [];

    DateTime currentDate = DateTime.now();

    int numberOfDays = countdownEvent.eventDate.difference(currentDate).inDays;

    if (numberOfDays < 0) {
      widgets = [
        Icon(
          Icons.done,
          color: countdownEvent.contentColor != null
              ? countdownEvent.contentColor
              : countdownEvent.color != null
                  ? countdownEvent.color!.computeLuminance() > 0.5
                      ? Colors.black
                      : Colors.white
                  : null,
        ),
        Text(
          '${countdownEvent.eventDate.month}.${countdownEvent.eventDate.day}.${countdownEvent.eventDate.year}',
          style: TextStyle(
            color: countdownEvent.contentColor != null
                ? countdownEvent.contentColor
                : countdownEvent.color != null
                    ? countdownEvent.color!.computeLuminance() > 0.5
                        ? Colors.black
                        : Colors.white
                    : null,
            fontSize: 12,
            fontWeight: FontWeight.w300,
            fontFamily: countdownEvent.fontFamily,
          ),
        )
      ];
    } else if (numberOfDays > 0) {
      widgets = [
        Text(
          //numberOfDays.toString(),
          numberOfDays.toString(),
          style: TextStyle(
            color: countdownEvent.contentColor != null
                ? countdownEvent.contentColor
                : countdownEvent.color != null
                    ? countdownEvent.color!.computeLuminance() > 0.5
                        ? Colors.black
                        : Colors.white
                    : null,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            fontFamily: countdownEvent.fontFamily,
          ),
        ),
        Text(
          numberOfDays == 1 ? 'DAY' : 'DAYS',
          style: TextStyle(
            color: countdownEvent.contentColor != null
                ? countdownEvent.contentColor
                : countdownEvent.color != null
                    ? countdownEvent.color!.computeLuminance() > 0.5
                        ? Colors.black
                        : Colors.white
                    : null,
            fontSize: 12,
            fontWeight: FontWeight.w300,
            fontFamily: countdownEvent.fontFamily,
          ),
        ),
      ];
    } else {
      widgets = [
        Icon(
          Icons.done,
          color: countdownEvent.contentColor != null
              ? countdownEvent.contentColor
              : countdownEvent.color != null
                  ? countdownEvent.color!.computeLuminance() > 0.5
                      ? Colors.black
                      : Colors.white
                  : null,
        ),
        Text(
          'TODAY',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w300,
            color: countdownEvent.contentColor != null
                ? countdownEvent.contentColor
                : countdownEvent.color != null
                    ? countdownEvent.color!.computeLuminance() > 0.5
                        ? Colors.black
                        : Colors.white
                    : null,
            fontFamily: countdownEvent.fontFamily,
          ),
        )
      ];
    }

    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 74,
      child: Card(
        color: countdownEvent.color ?? Colors.blue,
        elevation: 1.0,
        child: Row(
          children: [
            SizedBox(
              width: 44,
              child: Align(
                alignment: Alignment.center,
                child: Icon(
                  countdownEvent.icon ?? Icons.calendar_today,
                  color: countdownEvent.contentColor != null
                      ? countdownEvent.contentColor
                      : countdownEvent.color != null
                          ? countdownEvent.color!.computeLuminance() > 0.5
                              ? Colors.black
                              : Colors.white
                          : null,
                  size: 24,
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 15.0),
                child: Text(
                  countdownEvent.title,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: countdownEvent.contentColor != null
                        ? countdownEvent.contentColor
                        : countdownEvent.color != null
                            ? countdownEvent.color!.computeLuminance() > 0.5
                                ? Colors.black
                                : Colors.white
                            : null,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    fontFamily: countdownEvent.fontFamily,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: _getStatus(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
