import 'package:flutter/material.dart';

extension TimeDifference on Duration {
  int get timeDifferenceOnlyYears => inDays > 0 ? (inDays / 365).floor() : 0;
  int get timeDifferenceOnlyDays => inDays > 0 ? inDays % 365 : 0;
  int get timeDifferenceOnlyHours => inHours > 0 ? inHours % 24 : 0;
  int get timeDifferenceOnlyMinutes => inMinutes > 0 ? inMinutes % 60 : 0;
  int get timeDifferenceOnlySeconds => inSeconds > 0 ? inSeconds % 60 : 0;
}

extension GradientColor on Color {
  Color get contentColor {
    return computeLuminance() >= .5
        ? toMaterialColor().shade900
        : toMaterialColor().shade100;
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

  /// Converts a [Color] to a [MaterialColor] by generating a swatch with different shades.
  MaterialColor toMaterialColor() {
    // Define the standard Material Design shade keys.
    const List<int> shadeKeys = <int>[
      50,
      100,
      200,
      300,
      400,
      500,
      600,
      700,
      800,
      900,
    ];

    // Convert the base color to HSL for easier shade manipulation.
    final HSLColor hslColor = HSLColor.fromColor(this);

    // Initialize the swatch map.
    final Map<int, Color> swatch = {};

    // Generate shades by adjusting the lightness.
    for (int i = 0; i < shadeKeys.length; i++) {
      // Calculate the desired lightness for each shade.
      // These values are based on Material Design guidelines.
      double lightness;
      switch (shadeKeys[i]) {
        case 50:
          lightness = 0.95;
          break;
        case 100:
          lightness = 0.90;
          break;
        case 200:
          lightness = 0.80;
          break;
        case 300:
          lightness = 0.70;
          break;
        case 400:
          lightness = 0.60;
          break;
        case 500:
          lightness = hslColor.lightness;
          break;
        case 600:
          lightness = 0.50;
          break;
        case 700:
          lightness = 0.40;
          break;
        case 800:
          lightness = 0.30;
          break;
        case 900:
          lightness = 0.20;
          break;
        default:
          lightness = hslColor.lightness;
      }

      // Create the new shade by adjusting the lightness.
      final HSLColor adjustedHsl = hslColor.withLightness(
        lightness.clamp(0.0, 1.0),
      );
      final Color adjustedColor = adjustedHsl.toColor();

      // Add the new shade to the swatch.
      swatch[shadeKeys[i]] = adjustedColor;
    }

    // Convert channels to hex strings
    String alpha = a.toInt().toRadixString(16).toUpperCase().padLeft(2, '0');
    String red = r.toInt().toRadixString(16).toUpperCase().padLeft(2, '0');
    String green = g.toInt().toRadixString(16).toUpperCase().padLeft(2, '0');
    String blue = b.toInt().toRadixString(16).toUpperCase().padLeft(2, '0');

    // Convert hex strings back to integers for bitwise operations
    int aInt = int.parse(alpha, radix: 16);
    int rInt = int.parse(red, radix: 16);
    int gInt = int.parse(green, radix: 16);
    int bInt = int.parse(blue, radix: 16);

    int value = (aInt << 24) | (rInt << 16) | (gInt << 8) | bInt;

    return MaterialColor(value, swatch);
  }
}
