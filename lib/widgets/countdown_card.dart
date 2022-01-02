import 'dart:async';

import 'package:countdown/models/countdown_event.dart';
import 'package:countdown/screens/countdown_page.dart';
import 'package:countdown/utilities/functions.dart';
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

    int numberOfDays =
        numberOfDaysBetween(currentDate, countdownEvent.eventDate);
    //int numberOfSeconds = numberOfSecondsBetween(currentDate, countdownEvent.eventDate);

    if (numberOfDays < 0) {
      widgets = [
        const Icon(
          Icons.done,
          color: Colors.white,
        ),
        Text(
          '${countdownEvent.eventDate.month}.${countdownEvent.eventDate.day}.${countdownEvent.eventDate.year}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w300,
          ),
        )
      ];
    } else if (numberOfDays > 0) {
      widgets = [
        Text(
          //numberOfDays.toString(),
          numberOfDays.toString(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          numberOfDays == 1 ? 'DAY' : 'DAYS',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w300,
          ),
        ),
      ];
    } else {
      widgets = const [
        Icon(
          Icons.done,
          color: Colors.white,
        ),
        Text(
          'TODAY',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w300,
            color: Colors.white,
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
                  color: Colors.white,
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
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700),
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
