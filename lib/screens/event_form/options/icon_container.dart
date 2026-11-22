import 'package:countdowns/models/event_icons.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:countdowns/providers/local_settings_provider.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

typedef IconSelectedCallback = void Function(IconData? selectedIcon);

class IconContainer extends ConsumerWidget {
  const IconContainer({
    super.key,
    this.selectedIcon,
    required this.onIconChanged,
  });
  final IconData? selectedIcon;
  final IconSelectedCallback onIconChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GridView.count(
      padding: const EdgeInsets.all(8),
      crossAxisCount: 5,
      mainAxisSpacing: 5,
      crossAxisSpacing: 5,
      children: eventIcons
          .map(
            (iconData) => GestureDetector(
              onTap: () {
                var settings = ref.read(localSettingsProvider);
                if (settings.hapticFeedback) {
                  HapticFeedback.lightImpact();
                }
                if (settings.soundEffects) {
                  AudioPlayer().play(
                    AssetSource('sounds/tap.mp3'),
                    ctx: AudioContext(
                      iOS: AudioContextIOS(
                        category: AVAudioSessionCategory.ambient,
                      ),
                    ),
                    mode: PlayerMode.lowLatency,
                  );
                }
                onIconChanged(iconData);
              },
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: iconData == selectedIcon
                      ? Theme.of(context).scaffoldBackgroundColor
                      : Theme.of(context).cardColor,
                  border: Border.all(
                    color: iconData == selectedIcon
                        ? Theme.of(context).primaryColor
                        : Theme.of(context).unselectedWidgetColor,
                    width: iconData == selectedIcon ? 4 : 2,
                  ),
                ),
                child: Icon(iconData),
              ),
            ),
          )
          .toList(),
    );
  }
}
