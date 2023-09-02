import 'package:audioplayers/audioplayers.dart';
import 'package:countdowns/providers/settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

typedef OnColorChanged = void Function(Color color);

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
      onTap: () {
        var settings = context.read<SettingsProvider>().settings;
        if (settings.hapticFeedback) {
          HapticFeedback.lightImpact();
        }
        if (settings.soundEffects) {
          AudioPlayer()
              .play(AssetSource('sounds/tap.mp3'), mode: PlayerMode.lowLatency);
        }
        onColorChanged(color);
      },
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
