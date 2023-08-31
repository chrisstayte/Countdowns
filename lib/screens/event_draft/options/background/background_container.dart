import 'package:audioplayers/audioplayers.dart';
import 'package:countdowns/providers/settings_provider.dart';
import 'package:countdowns/screens/event_draft/options/background/color_selector.dart';
import 'package:countdowns/screens/event_draft/options/background/custom_color_modal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

typedef OnColorChanged = void Function(Color color);
typedef OnGradientChanged = void Function(bool gradient);

class BackgroundContainer extends StatelessWidget {
  const BackgroundContainer({
    super.key,
    required this.selectedColor,
    required this.onColorChanged,
    required this.gradient,
    required this.onGradientChanged,
  });

  final Color selectedColor;
  final OnColorChanged onColorChanged;
  final bool gradient;
  final OnGradientChanged onGradientChanged;

  final List<Color> _colors = const [
    Color(0Xff7877E6),
    Color(0XFF343434),
    Color(0XFFF7BC33),
    Color(0XFFFF564A),
    Color(0XFFFEA08B),
    Color(0XFFFE7228),
    Color(0XFF83C236),
    Color(0XFF597FFE),
    Color(0XFF66B6FE),
    Color(0XFFFE607C),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        const SizedBox(
          height: 25,
        ),
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
        const SizedBox(
          height: 10,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            GestureDetector(
              onTap: () async {
                var settings = context.read<SettingsProvider>().settings;
                if (settings.hapticFeedback) {
                  HapticFeedback.lightImpact();
                }
                if (settings.soundEffects) {
                  AudioPlayer().play(AssetSource('sounds/tap.mp3'),
                      mode: PlayerMode.lowLatency);
                }
                await showModalBottomSheet(
                  context: context,
                  builder: (context) => CustomColorModal(
                    selectedColor: selectedColor,
                    onColorChanged: onColorChanged,
                    gradient: gradient,
                  ),
                  backgroundColor: Colors.transparent,
                );
              },
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    width: 2,
                    color: !_colors.contains(selectedColor)
                        ? Theme.of(context).primaryColor
                        : Colors.transparent,
                  ),
                ),
                child: Container(
                  height: 48,
                  width: 48,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      stops: [0, 1 / 6, 2 / 6, 3 / 6, 4 / 6, 5 / 6, 1],
                      colors: [
                        Colors.red,
                        Colors.orange,
                        Colors.yellow,
                        Colors.green,
                        Colors.blue,
                        Colors.indigo,
                        Colors.purple,
                      ],
                    ),
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
            Row(
              children: [
                const Text(
                  'Gradient',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Switch.adaptive(value: gradient, onChanged: onGradientChanged)
              ],
            ),
          ],
        )
      ],
    );
  }
}
