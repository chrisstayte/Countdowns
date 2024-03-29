import 'package:audioplayers/audioplayers.dart';
import 'package:countdowns/providers/settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

typedef IconSelectedCallback = void Function(IconData? selectedIcon);

class IconContainer extends StatelessWidget {
  IconContainer({
    super.key,
    IconData? selectedIcon,
    required this.onIconChanged,
  }) {
    _selectedIcon = selectedIcon;
  }

  IconData? _selectedIcon;
  IconSelectedCallback onIconChanged;

  static final List<IconData> _icons = [
    Icons.calendar_today,
    Icons.celebration,
    Icons.cake,
    Icons.local_dining,
    Icons.icecream,
    Icons.holiday_village,
    Icons.hiking,
    Icons.sports,
    Icons.sports_football,
    Icons.sports_baseball,
    Icons.sports_basketball,
    Icons.sports_esports,
    Icons.alarm,
    Icons.airplane_ticket,
    Icons.airplanemode_active,
    Icons.airline_seat_flat,
    Icons.photo,
    Icons.wifi,
    Icons.warning,
    Icons.baby_changing_station,
    Icons.apartment,
    Icons.card_giftcard,
    Icons.computer,
    Icons.book,
    Icons.bookmark,
    Icons.piano,
    Icons.donut_large,
    Icons.camera,
    Icons.animation,
    Icons.sports_cricket,
    Icons.agriculture,
    Icons.horizontal_distribute_sharp,
    Icons.music_note,
    Icons.music_video,
    Icons.snooze,
    Icons.school,
    Icons.work,
    Icons.business,
    Icons.group,
    Icons.add_to_drive,
    Icons.blender,
    Icons.block,
    Icons.cabin,
    Icons.cached,
    Icons.delete,
    Icons.delete_forever,
    Icons.tram_sharp,
    Icons.train,
    Icons.traffic,
    Icons.map,
    Icons.flutter_dash,
    Icons.golf_course,
    Icons.tty_sharp,
    Icons.attractions,
    Icons.assignment_sharp,
    Icons.camera_rear,
    Icons.cloud_sharp,
    Icons.coronavirus,
    Icons.motion_photos_auto,
    Icons.email,
    Icons.phone,
    Icons.wallet_giftcard,
    Icons.smart_button,
    Icons.brunch_dining_rounded,
    Icons.bakery_dining,
    Icons.library_add,
    Icons.favorite,
    Icons.park,
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      padding: const EdgeInsets.all(8),
      crossAxisCount: 5,
      mainAxisSpacing: 5,
      crossAxisSpacing: 5,
      children: _icons
          .map(
            (iconData) => GestureDetector(
              onTap: () {
                var settings = context.read<SettingsProvider>().settings;
                if (settings.hapticFeedback) {
                  HapticFeedback.lightImpact();
                }
                if (settings.soundEffects) {
                  AudioPlayer().play(AssetSource('sounds/tap.mp3'),
                      ctx: const AudioContext(
                        iOS: AudioContextIOS(
                          category: AVAudioSessionCategory.ambient,
                        ),
                      ),
                      mode: PlayerMode.lowLatency);
                }
                onIconChanged(iconData);
              },
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: iconData == _selectedIcon
                      ? Theme.of(context).scaffoldBackgroundColor
                      : Theme.of(context).cardColor,
                  border: Border.all(
                    color: iconData == _selectedIcon
                        ? Theme.of(context).primaryColor
                        : Theme.of(context).unselectedWidgetColor,
                    width: iconData == _selectedIcon ? 4 : 2,
                  ),
                ),
                child: Icon(
                  iconData,
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}
