import 'package:countdowns/utilities/settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/src/provider.dart';

class IconPickerMaterialModal extends StatefulWidget {
  IconPickerMaterialModal({Key? key, this.icon, required this.iconCallback})
      : super(key: key);

  IconData? icon;
  IconCallback iconCallback;

  @override
  _IconPickerMaterialModalState createState() =>
      _IconPickerMaterialModalState();
}

typedef IconCallback = void Function(IconData icon);

class _IconPickerMaterialModalState extends State<IconPickerMaterialModal> {
  IconData? _selectedIcon;

  @override
  void initState() {
    _selectedIcon = widget.icon;
    super.initState();
  }

  final List<IconData> _icons = [
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
    return DraggableScrollableSheet(
      expand: false,
      builder: (context, scrollController) {
        return GridView.count(
          padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 25.0),
          controller: scrollController,
          mainAxisSpacing: 20,
          crossAxisSpacing: 20,
          crossAxisCount: 5,
          children: List.generate(
            _icons.length,
            (index) {
              return IconButton(
                splashColor: Colors.transparent,
                icon: Stack(
                  alignment: AlignmentDirectional.center,
                  children: [
                    _selectedIcon == _icons[index]
                        ? Container(
                            height: 45,
                            width: 45,
                            decoration: BoxDecoration(
                              // color: context
                              //         .watch<SettingsProvider>()
                              //         .settings
                              //         .darkMode
                              //     ? Colors.white
                              // : Colors.black,
                              shape: BoxShape.circle,
                            ),
                          )
                        : const Text(''),
                    Icon(
                      _icons[index],
                      // color: _selectedIcon == _icons[index]
                      //     ? context.watch<SettingsProvider>().settings.darkMode
                      //         ? Colors.black
                      //         : Colors.white
                      //     : context.watch<SettingsProvider>().settings.darkMode
                      //         ? Colors.white
                      //         : Colors.black,
                    ),
                  ],
                ),
                onPressed: () {
                  setState(
                    () {
                      _selectedIcon = _icons[index];
                    },
                  );
                  widget.iconCallback(_selectedIcon!);
                },
              );
            },
          ),
        );
      },
    );
  }
}
