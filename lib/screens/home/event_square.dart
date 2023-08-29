import 'dart:async';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:countdowns/models/event.dart';
import 'package:countdowns/providers/settings_provider.dart';
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
  late String _premierText;
  late String? _secondaryText;
  late Timer _timer;

  bool _eventOccured = false;

  @override
  void initState() {
    super.initState();
    _updateTimeUI();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateTimeUI());
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _updateTimeUI() {
    // Determine the time difference (also incorporate if it's all day or specific time)
    Duration timeDifference = widget.event.getTimeDifference();

    int years = (timeDifference.inDays / 365).floor();
    // set the premier text
    if (years > 0) {
      _premierText = '${years} years';
      _secondaryText =
          '${timeDifference.inDays % 365} days, ${timeDifference.inHours % 24} hr';
    } else if (timeDifference.inDays > 0) {
      _premierText = '${timeDifference.inDays} days';
      _secondaryText = '${timeDifference.inHours % 24} hr, '
          '${timeDifference.inMinutes % 60} min';
    } else if (timeDifference.inHours > 0) {
      _premierText = '${timeDifference.inHours} hours';
      _secondaryText = '${timeDifference.inMinutes % 60} min, '
          '${timeDifference.inSeconds % 60} sec';
    } else if (timeDifference.inMinutes > 0) {
      _premierText = '${timeDifference.inMinutes} min';
      _secondaryText = '${timeDifference.inSeconds % 60} sec';
    } else if (timeDifference.inSeconds > 0) {
      _premierText = '${timeDifference.inSeconds} sec';
      _secondaryText = null;
    } else {
      _premierText = 'Complete';
      _secondaryText = null;
    }

    setState(() {});
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _premierText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (_secondaryText != null)
                  AutoSizeText(
                    _secondaryText!,
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
      ),
    );
  }
}
