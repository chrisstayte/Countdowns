import 'dart:async';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:countdowns/global/global.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class EventSquareConstructor extends StatefulWidget {
  const EventSquareConstructor({
    super.key,
    required this.title,
    required this.eventDateTime,
    required this.allDay,
    this.icon,
    this.fontFamily,
  });

  final String title;
  final IconData? icon;
  final String? fontFamily;
  final DateTime eventDateTime;
  final bool allDay;

  @override
  State<EventSquareConstructor> createState() => _EventSquareConstructorState();
}

class _EventSquareConstructorState extends State<EventSquareConstructor> {
  Timer? _timer;
  late String premierText;
  late String? secondaryText;

  @override
  void initState() {
    // every second grab the current status of the countdown event, if the event has not passed show the time remaining
    // if the event has passed, show the time since the event has passed
    _updateTimeUI();
    _timer = Timer.periodic(Duration(seconds: 1), (timer) => _updateTimeUI());

    super.initState();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _updateTimeUI() {
    // Determine the time difference (also incorporate if it's all day or specific time)
    DateTime now = DateTime.now();
    Duration timeDifference;
    if (widget.allDay) {
      DateTime eventDateTimeWithoutTime = DateTime(widget.eventDateTime.year,
          widget.eventDateTime.month, widget.eventDateTime.day);
      timeDifference = eventDateTimeWithoutTime.difference(now);
    } else {
      timeDifference = widget.eventDateTime.difference(now);
    }

    int years = (timeDifference.inDays / 365).floor();
    // set the premier text
    if (years > 0) {
      premierText = '${years} years';
      secondaryText =
          '${timeDifference.inDays % 365} days, ${timeDifference.inHours % 24} hr';
    } else if (timeDifference.inDays > 0) {
      premierText = '${timeDifference.inDays} days';
      secondaryText = '${timeDifference.inHours % 24} hr, '
          '${timeDifference.inMinutes % 60} min';
    } else if (timeDifference.inHours > 0) {
      premierText = '${timeDifference.inHours} hours';
      secondaryText = '${timeDifference.inMinutes % 60} min, '
          '${timeDifference.inSeconds % 60} sec';
    } else if (timeDifference.inMinutes > 0) {
      premierText = '${timeDifference.inMinutes} min';
      secondaryText = '${timeDifference.inSeconds % 60} sec';
    } else if (timeDifference.inSeconds > 0) {
      premierText = '${timeDifference.inSeconds} sec';
      secondaryText = null;
    } else {
      premierText = 'Complete';
      secondaryText = null;
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 169,
      height: 169,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(
          25,
        ),
        color: Global.colors.primaryColor,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: AutoSizeText(
                  widget.title,
                  minFontSize: 14,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.white,
                    fontFamily: widget.fontFamily,
                  ),
                ),
              ),
              if (widget.icon != null)
                Padding(
                  padding: const EdgeInsets.only(left: 5),
                  child: Icon(
                    widget.icon,
                    color: Colors.white,
                  ),
                )
            ],
          ),
          if (widget.eventDateTime != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  premierText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (secondaryText != null)
                  AutoSizeText(
                    secondaryText!,
                    maxLines: 1,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}
