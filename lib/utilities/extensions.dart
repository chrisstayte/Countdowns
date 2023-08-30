import 'package:flutter/material.dart';

extension GradientColor on Color {
  LinearGradient get gradient => LinearGradient(
        colors: [this, withOpacity(0.6)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      );
}
