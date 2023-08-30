import 'package:flutter/material.dart';

extension GradientColor on Color {
  Color get contentColor {
    return computeLuminance() >= .5 ? Colors.black : Colors.white;
  }

  LinearGradient get gradient {
    // Convert the color to HSL.
    HSLColor hsl = HSLColor.fromColor(this);

    // Compute the complimentary color.
    double newHue = (hsl.hue + 180.0) % 360.0;
    HSLColor complimentary = hsl.withHue(newHue);

    return LinearGradient(
      colors: [this, complimentary.toColor()],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  //   LinearGradient get gradient => LinearGradient(
//         colors: [this, withOpacity(0.6)],
//         begin: Alignment.topCenter,
//         end: Alignment.bottomCenter,
//       );

  //   LinearGradient get gradient {
  //   // Convert the color to HSL.
  //   HSLColor hsl = HSLColor.fromColor(this);

  //   // Compute luminance.
  //   final double luminance = this.computeLuminance();

  //   // Determine gradient colors based on luminance.
  //   Color lighter =
  //       hsl.withLightness((hsl.lightness + 0.11).clamp(0.0, 1.0)).toColor();
  //   Color darker =
  //       hsl.withLightness((hsl.lightness - 0.11).clamp(0.0, 1.0)).toColor();

  //   final List<Color> gradientColors =
  //       luminance <= 0.5 ? [this, lighter] : [this, darker];

  //   return LinearGradient(
  //     colors: gradientColors,
  //     begin: Alignment.bottomCenter,
  //     end: Alignment.topCenter,
  //   );
  // }
}
