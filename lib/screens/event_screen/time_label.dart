import 'package:flutter/material.dart';

class TimeLabel extends StatelessWidget {
  const TimeLabel({
    super.key,
    required this.label,
    this.rightSide = false,
    required this.style,
  });

  final String label;
  final bool rightSide;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: rightSide
          ? const EdgeInsets.only(left: 5)
          : const EdgeInsets.only(right: 5),
      child: Text(label, style: style),
    );
  }
}
