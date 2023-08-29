import 'package:flutter/material.dart';

extension GradientColor on Color {
  LinearGradient get gradient => LinearGradient(
        colors: [this, withOpacity(0.6)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
}
