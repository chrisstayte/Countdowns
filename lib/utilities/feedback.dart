import 'package:audioplayers/audioplayers.dart';
import 'package:countdowns/providers/local_settings_provider.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum Sound { tap, select, success, error, trash }

/// Plays the haptic and sound the person has turned on.
void feedback(WidgetRef ref, [Sound sound = Sound.tap]) {
  final settings = ref.read(localSettingsProvider);
  if (settings.hapticFeedback) {
    switch (sound) {
      case Sound.select:
        HapticFeedback.selectionClick();
      case Sound.error:
        HapticFeedback.vibrate();
      case Sound.success:
        HapticFeedback.mediumImpact();
      case Sound.tap:
      case Sound.trash:
        HapticFeedback.lightImpact();
    }
  }
  if (settings.soundEffects) {
    AudioPlayer().play(
      AssetSource('sounds/${sound.name}.mp3'),
      ctx: AudioContext(
        iOS: AudioContextIOS(category: AVAudioSessionCategory.ambient),
      ),
      mode: PlayerMode.lowLatency,
    );
  }
}
