import 'package:audioplayers/audioplayers.dart';
import 'package:countdowns/global/global.dart';
import 'package:countdowns/providers/settings_provider.dart';
import 'package:countdowns/utilities/extensions.dart';
import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

typedef OnColorChanged = void Function(Color color);

class CustomColorModal extends StatefulWidget {
  const CustomColorModal({
    super.key,
    required this.selectedColor,
    required this.onColorChanged,
    required this.gradient,
  });

  final Color selectedColor;
  final OnColorChanged onColorChanged;
  final bool gradient;

  @override
  State<CustomColorModal> createState() => _CustomColorModalState();
}

class _CustomColorModalState extends State<CustomColorModal> {
  late Color _selectedColor;

  @override
  void initState() {
    _selectedColor = widget.selectedColor;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      height: 340,
      decoration: BoxDecoration(
        borderRadius: Global.styles.containerCornerRadius,
        color: Theme.of(context).cardColor,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Background Color',
                style: TextStyle(
                  fontSize: 22,
                ),
              ),
              OutlinedButton(
                onPressed: () {
                  var settings = context.read<SettingsProvider>().settings;
                  if (settings.hapticFeedback) {
                    HapticFeedback.lightImpact();
                  }
                  if (settings.soundEffects) {
                    AudioPlayer().play(AssetSource('sounds/tap.mp3'),
                        mode: PlayerMode.lowLatency);
                  }
                  context.pop();
                },
                style: ButtonStyle(
                  foregroundColor: MaterialStateProperty.all<Color>(
                    Colors.white,
                  ),
                  backgroundColor: MaterialStateProperty.all<Color>(
                    Global.colors.offColor,
                  ),
                  side: MaterialStateProperty.all<BorderSide>(
                    BorderSide(
                      color: Global.colors.offColor,
                    ),
                  ),
                  shape: MaterialStateProperty.all<OutlinedBorder>(
                    RoundedRectangleBorder(
                      borderRadius: Global.styles.containerCornerRadius,
                    ),
                  ),
                  elevation: MaterialStateProperty.all<double>(2),
                ),
                child: const Icon(Icons.check_circle_outline_outlined),
              )
            ],
          ),
          const SizedBox(
            height: 15,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Expanded(
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Container(
                    decoration: BoxDecoration(
                      color: _selectedColor,
                      gradient:
                          widget.gradient ? _selectedColor.gradient : null,
                      borderRadius: Global.styles.containerCornerRadius,
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: ColorPicker(
                  color: _selectedColor,
                  onColorChanged: (color) {
                    setState(() {
                      _selectedColor = color;
                    });
                    widget.onColorChanged(color);
                  },
                  pickersEnabled: const <ColorPickerType, bool>{
                    ColorPickerType.primary: false,
                    ColorPickerType.accent: false,
                    ColorPickerType.bw: false,
                    ColorPickerType.custom: false,
                    ColorPickerType.wheel: true,
                  },
                  wheelSquareBorderRadius:
                      Global.styles.containerCornerRadius.topLeft.x,
                  enableShadesSelection: false,
                  enableTonalPalette: false,
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}
