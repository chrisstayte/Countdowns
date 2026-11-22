import 'dart:math' as math;

import 'package:countdowns/models/background_catalog.dart';
import 'package:material_ui/material_ui.dart';

/// A named catalogue colour. The catalogue itself (collections, featured
/// picks) is in background_catalog.dart. Existing events may hold other
/// colours; those are kept as they are and shown as a "Current" swatch.
class PaletteColor {
  const PaletteColor(this.name, this.color);
  final String name;
  final Color color;
}

const lavender = Color(0xFF7877E6);
const charcoal = Color(0xFF8A8796);
const sun = Color(0xFFF7BC33);
const tomato = Color(0xFFFF564A);
const peach = Color(0xFFFEA08B);
const tangerine = Color(0xFFFE7228);
const lime = Color(0xFF83C236);
const cobalt = Color(0xFF597FFE);
const sky = Color(0xFF66B6FE);
const bubblegum = Color(0xFFFE607C);
const mint = Color(0xFF5FD3B5);
const lilac = Color(0xFFC9A7F5);

/// Every catalogue colour, in collection order (see background_catalog.dart).
final List<PaletteColor> palette = [
  for (final c in colourCollections) ...c.colours,
];

bool isPaletteColor(int argb) => palette.any((c) => c.color.toARGB32() == argb);

/// How a gradient is laid out across a shape.
enum GradientDirection {
  down('Down', '↓'),
  up('Up', '↑'),
  right('Right', '→'),
  left('Left', '←'),
  diagonalDown('Diagonal down', '↘'),
  diagonalUp('Diagonal up', '↗'),
  radial('From the center', '◎'),
  sweep('Round', '↻');

  const GradientDirection(this.label, this.arrow);
  final String label;
  final String arrow;
}

class GradientPreset {
  const GradientPreset(this.id, this.name, this.colors);
  final String id;
  final String name;
  final List<Color> colors;
}

/// The id stored for events that used the old automatic gradient.
const legacyGradientId = 'legacy';

/// Every catalogue gradient, in collection order (see
/// background_catalog.dart).
final List<GradientPreset> gradientLibrary = [
  for (final c in gradientCollections) ...c.gradients,
];

GradientPreset? gradientById(String? id) =>
    gradientLibrary.where((g) => g.id == id).firstOrNull;

/// The old app's gradient: the colour to its complementary hue.
List<Color> legacyGradientColors(Color base) {
  final hsl = HSLColor.fromColor(base);
  return [base, hsl.withHue((hsl.hue + 180) % 360).toColor()];
}

/// The colours of an event's gradient, or null if it has none.
List<Color>? gradientColors(String? id, Color base) {
  if (id == null) return null;
  if (id == legacyGradientId) return legacyGradientColors(base);
  return gradientById(id)?.colors;
}

Gradient buildGradient(List<Color> colors, GradientDirection direction) {
  switch (direction) {
    case GradientDirection.down:
      return LinearGradient(
        colors: colors,
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      );
    case GradientDirection.up:
      return LinearGradient(
        colors: colors,
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
      );
    case GradientDirection.right:
      return LinearGradient(
        colors: colors,
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      );
    case GradientDirection.left:
      return LinearGradient(
        colors: colors,
        begin: Alignment.centerRight,
        end: Alignment.centerLeft,
      );
    case GradientDirection.diagonalDown:
      return LinearGradient(
        colors: colors,
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    case GradientDirection.diagonalUp:
      return LinearGradient(
        colors: colors,
        begin: Alignment.bottomLeft,
        end: Alignment.topRight,
      );
    case GradientDirection.radial:
      return RadialGradient(colors: colors, radius: 0.9);
    case GradientDirection.sweep:
      // Close the loop so the seam is invisible.
      return SweepGradient(
        colors: [...colors, colors.first],
        startAngle: 0,
        endAngle: math.pi * 2,
      );
  }
}

const ink = Color(0xFF1C1633);

/// Ink or white, whichever reads better on [background].
Color autoTextColor(Color background) {
  double contrast(Color a, Color b) {
    final la = a.computeLuminance(), lb = b.computeLuminance();
    final hi = math.max(la, lb), lo = math.min(la, lb);
    return (hi + 0.05) / (lo + 0.05);
  }

  return contrast(background, ink) >= contrast(background, Colors.white)
      ? ink
      : Colors.white;
}

/// Picks text colour for a gradient by its average colour.
Color autoTextColorFor(List<Color> colors) {
  double r = 0, g = 0, b = 0;
  for (final c in colors) {
    r += c.r;
    g += c.g;
    b += c.b;
  }
  final n = colors.length;
  return autoTextColor(
    Color.from(alpha: 1, red: r / n, green: g / n, blue: b / n),
  );
}
