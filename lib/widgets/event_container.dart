
import 'package:auto_size_text/auto_size_text.dart';
import 'package:countdowns/models/event.dart';
import 'package:countdowns/providers/timer_provider.dart';
import 'package:countdowns/utilities/extensions.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class EventContainer extends StatefulWidget {
  const EventContainer({super.key, required this.event});

  final Event event;

  @override
  State<EventContainer> createState() => _EventContainerState();
}

class _EventContainerState extends State<EventContainer> {
  late String premierText;
  late String? secondaryText;

  void _updateTimeUI() {
    Duration timeDifference = widget.event.getTimeDifference();
    int years = (timeDifference.inDays / 365).floor();
    // set the premier text
    if (years > 0) {
      premierText = '$years years';
      secondaryText =
          '${timeDifference.timeDifferenceOnlyDays} days, ${timeDifference.timeDifferenceOnlyHours} hr';
    } else if (timeDifference.inDays > 0) {
      premierText = '${timeDifference.inDays} days';
      secondaryText = '${timeDifference.timeDifferenceOnlyHours} hr, '
          '${timeDifference.inMinutes % 60} min';
    } else if (timeDifference.inHours > 0) {
      premierText = '${timeDifference.inHours} hours';
      secondaryText = '${timeDifference.timeDifferenceOnlyMinutes} min, '
          '${timeDifference.timeDifferenceOnlySeconds} sec';
    } else if (timeDifference.inMinutes > 0) {
      premierText = '${timeDifference.inMinutes} min';
      secondaryText = '${timeDifference.timeDifferenceOnlySeconds} sec';
    } else if (timeDifference.inSeconds > 0) {
      premierText = '${timeDifference.inSeconds} sec';
      secondaryText = null;
    } else {
      premierText = 'Completed';
      secondaryText =
          'on ${DateFormat("MMMM d, yyyy").format(widget.event.eventDateTime)}';
    }
  }

  @override
  Widget build(BuildContext context) {
    context.watch<TimerProvider>();
    _updateTimeUI();

    return Hero(
      tag: widget.event.key ?? widget.event.title,
      child: Material(
        type: MaterialType.transparency,
        child: Container(
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
                          shadows: const <Shadow>[
                            Shadow(
                              offset: Offset(1.0, 1.0),
                              blurRadius: 2.0,
                              color: Color.fromARGB(125, 0, 0,
                                  0), // Half the opacity compared to previous example
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (widget.event.icon != null)
                      Padding(
                        padding: const EdgeInsets.only(left: 5),
                        child: Icon(
                          widget.event.icon,
                          color: widget.event.backgroundColor.contentColor,
                          size: 30,
                          shadows: const <Shadow>[
                            Shadow(
                              offset: Offset(1.0, 1.0),
                              blurRadius: 2.0,
                              color: Color.fromARGB(125, 0, 0,
                                  0), // Half the opacity compared to previous example
                            ),
                          ],
                        ),
                      )
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: AutoSizeText(
                          premierText,
                          maxLines: 1,
                          minFontSize: 20,
                          style: TextStyle(
                            color: widget.event.backgroundColor.contentColor,
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            fontFamily: widget.event.fontFamily,
                            shadows: const <Shadow>[
                              Shadow(
                                offset: Offset(1.0, 1.0),
                                blurRadius: 2.0,
                                color: Color.fromARGB(125, 0, 0,
                                    0), // Half the opacity compared to previous example
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (widget.event.isPast())
                        Padding(
                          padding: const EdgeInsets.only(left: 5),
                          child: Icon(
                            Icons.check_circle,
                            color: widget.event.backgroundColor.contentColor,
                          ),
                        ),
                    ],
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
                        shadows: const <Shadow>[
                          Shadow(
                            offset: Offset(1.0, 1.0),
                            blurRadius: 2.0,
                            color: Color.fromARGB(125, 0, 0,
                                0), // Half the opacity compared to previous example
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
