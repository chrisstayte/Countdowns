import 'package:audioplayers/audioplayers.dart';
import 'package:countdowns/providers/local_settings_provider.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

typedef OnColorChanged = void Function(Color color);

class ColorSelector extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () {
        var settings = ref.read(localSettingsProvider);
        if (settings.hapticFeedback) {
          HapticFeedback.lightImpact();
        }
        if (settings.soundEffects) {
          AudioPlayer().play(
            AssetSource('sounds/tap.mp3'),
            mode: PlayerMode.lowLatency,
          );
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
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
      ),
    );
  }
}
