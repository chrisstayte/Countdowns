import 'dart:async';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:countdowns/models/event.dart';
import 'package:countdowns/utilities/settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class CountdownSquare extends StatefulWidget {
  const CountdownSquare({super.key, required this.event});

  final Event event;

  @override
  State<CountdownSquare> createState() => _CountdownSquareState();
}

class _CountdownSquareState extends State<CountdownSquare> {
  late int _years;
  late int _days;
  late int _hours;
  late int _minutes;
  late int _seconds;
  late Timer _timer;

  bool _eventOccured = false;

  @override
  void initState() {
    super.initState();
    _updateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateTime());
  }

  void _updateTime() {
    Duration timeDifference = widget.event.getTimeDifference();

    if (timeDifference < Duration.zero) {
      setState(() {
        _eventOccured = true;
      });
      _timer.cancel();
      return;
    }

    setState(() {
      _seconds = timeDifference.inSeconds % 60;
      _minutes = timeDifference.inMinutes % 60;
      _hours = timeDifference.inHours % 24;
      _days = (timeDifference.inDays % 365);
      _years = (timeDifference.inDays / 365.0).floor();
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (context.read<SettingsProvider>().settings.hapticFeedback) {
          HapticFeedback.selectionClick();
        }
        context.push(
          '/event/${widget.event.key}',
        );
      },
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: widget.event.backgroundColor ?? const Color(0xff7877E6),
        ),
        width: 169,
        height: 169,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AutoSizeText(
              widget.event.title,
              maxLines: 2,
              minFontSize: 12,
              maxFontSize: 18,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 18,
                fontFamily: widget.event.fontFamily,
                color: widget.event.contentColor ?? Colors.white,
              ),
            ),
            const Spacer(),
            Row(
              children: [
                AutoSizeText(
                  _days.toString(),
                  maxLines: 1,
                  minFontSize: 12,
                  maxFontSize: 18,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 18,
                    fontFamily: widget.event.fontFamily,
                    color: widget.event.contentColor ?? Colors.white,
                  ),
                ),
                const SizedBox(
                  width: 5,
                ),
                AutoSizeText(
                  'Days',
                  maxLines: 1,
                  minFontSize: 12,
                  maxFontSize: 18,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 18,
                    fontFamily: widget.event.fontFamily,
                    color: widget.event.contentColor ?? Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(
              height: 8,
            ),
            Row(
              children: [
                AutoSizeText(
                  '${_hours.toString()} hr, ${_minutes.toString()} min',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    fontFamily: widget.event.fontFamily,
                    color: widget.event.contentColor ?? Colors.white,
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
