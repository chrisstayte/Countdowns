import 'dart:async';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:countdowns/models/event.dart';
import 'package:countdowns/utilities/extensions.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class EventContainer extends StatefulWidget {
  const EventContainer({super.key, required this.event});

  final Event event;

  @override
  State<EventContainer> createState() => _EventContainerState();
}

class _EventContainerState extends State<EventContainer> {
  Timer? _timer;
  late String premierText;
  late String? secondaryText;

  @override
  void initState() {
    // every second grab the current status of the countdown event, if the event has not passed show the time remaining
    // if the event has passed, show the time since the event has passed
    _updateTimeUI();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) => _updateTimeUI());

    super.initState();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _updateTimeUI() {
    Duration timeDifference = widget.event.getTimeDifference();
    int years = (timeDifference.inDays / 365).floor();
    // set the premier text
    if (years > 0) {
      premierText = '$years years';
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
      constraints: const BoxConstraints(
        // maxWidth: 169,
        maxHeight: 169,
      ),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(
          25,
        ),
        color: widget.event.backgroundColor,
        gradient: widget.event.backgroundGradient
            ? widget.event.backgroundColor.gradient
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: AutoSizeText(
                    widget.event.title,
                    minFontSize: 14,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                    style: TextStyle(
                      fontSize: 26,
                      color: widget.event.backgroundColor.contentColor,
                      fontFamily: widget.event.fontFamily,
                    ),
                  ),
                ),
                if (widget.event.icon != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 5),
                    child: Icon(
                      widget.event.icon,
                      color: widget.event.backgroundColor.contentColor,
                    ),
                  )
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AutoSizeText(
                premierText,
                maxLines: 1,
                minFontSize: 20,
                style: TextStyle(
                  color: widget.event.backgroundColor.contentColor,
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  fontFamily: widget.event.fontFamily,
                ),
              ),
              if (secondaryText != null)
                AutoSizeText(
                  secondaryText!,
                  maxLines: 1,
                  style: TextStyle(
                    color: widget.event.backgroundColor.contentColor
                        .withOpacity(.8),
                    fontSize: 18,
                    fontFamily: widget.event.fontFamily,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
