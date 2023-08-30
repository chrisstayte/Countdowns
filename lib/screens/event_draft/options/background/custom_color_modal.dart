import 'package:countdowns/global/global.dart';
import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

typedef void OnColorChanged(Color color);

class CustomColorModal extends StatefulWidget {
  const CustomColorModal({
    super.key,
    required this.selectedColor,
    required this.onColorChanged,
  });

  final Color selectedColor;
  final OnColorChanged onColorChanged;

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
            children: [
              const Text(
                'Background Color',
                style: TextStyle(
                  fontSize: 22,
                ),
              ),
              const Spacer(),
              Container(
                height: 25,
                width: 25,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _selectedColor,
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton(
                onPressed: () => context.pop(),
                child: const Icon(Icons.check_circle_outline_outlined),
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
              )
            ],
          ),
          const SizedBox(
            height: 15,
          ),
          ColorPicker(
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
          )
        ],
      ),
    );
  }
}
