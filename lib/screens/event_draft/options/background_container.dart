import 'package:countdowns/global/global.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

typedef void OnColorChanged(Color color);
typedef void OnGradientChanged(bool gradient);

class BackgroundContainer extends StatelessWidget {
  const BackgroundContainer({
    super.key,
    required this.selectedColor,
    required this.onColorChanged,
    required this.gradient,
    required this.onGradientChanged,
  });

  final Color? selectedColor;
  final OnColorChanged onColorChanged;
  final bool gradient;
  final OnGradientChanged onGradientChanged;

  final List<Color> _colors = const [
    Color(0Xff7877E6),
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.purple,
    Colors.orange,
    Colors.grey,
    Colors.pinkAccent,
    Colors.limeAccent,
    Colors.tealAccent,
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: _colors
              .sublist(
                0,
                _colors.length ~/ 2,
              )
              .map(
                (color) => ColorSelector(
                  color: color,
                  onColorChanged: onColorChanged,
                  selectedColor: selectedColor,
                ),
              )
              .toList(),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: _colors
              .sublist(
                _colors.length ~/ 2,
                _colors.length,
              )
              .map(
                (color) => ColorSelector(
                  color: color,
                  onColorChanged: onColorChanged,
                  selectedColor: selectedColor,
                ),
              )
              .toList(),
        ),
        SizedBox(
          height: 10,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Gradient'),
            Switch.adaptive(value: gradient, onChanged: onGradientChanged)
          ],
        )
      ],
    );
  }
}

class ColorSelector extends StatelessWidget {
  const ColorSelector({
    super.key,
    required this.color,
    required this.onColorChanged,
    required this.selectedColor,
  });

  final Color color;
  final OnColorChanged onColorChanged;
  final Color? selectedColor;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onColorChanged(color),
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            width: 2,
            color: selectedColor == color
                ? Theme.of(context).primaryColor
                : Colors.transparent,
          ),
        ),
        child: Container(
          height: 48,
          width: 48,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}
