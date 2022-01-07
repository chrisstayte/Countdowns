import 'package:countdowns/utilities/settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/src/provider.dart';

class ColorPickerMaterialModal extends StatefulWidget {
  //const ColorPickerMaterialModal.empty({Key? key}) : super(key: key);
  ColorPickerMaterialModal(
      {Key? key, Color? this.color, required ColorCallback this.colorCallback})
      : super(key: key);

  Color? color;
  ColorCallback colorCallback;
  @override
  _ColorPickerMaterialModalState createState() =>
      _ColorPickerMaterialModalState();
}

typedef void ColorCallback(Color color);

class _ColorPickerMaterialModalState extends State<ColorPickerMaterialModal> {
  Color? _selectedColor;

  @override
  void initState() {
    _selectedColor = widget.color;
    super.initState();
  }

  final List<Color> _colors = [
    const Color(0XFFBB84E7),
    const Color(0XFFA3C4F3),
    const Color(0XFF568D66),
    const Color(0XFFF15152),
    const Color(0XFFFF9500),
    const Color(0XFF0a9396),
    const Color(0XFFF7E7CE),
    Colors.green,
    Colors.blue,
    Colors.orange,
    Colors.red,
    Colors.purple,
    Colors.grey,
    Colors.lightBlue,
    Colors.lightGreen,
    Colors.deepPurple,
    Colors.black,
    Colors.pink,
    Colors.white,
    Colors.brown,
    Colors.green,
    Colors.blue,
    Colors.orange,
    Colors.red,
    Colors.purple,
    Colors.grey,
    Colors.lightBlue,
    Colors.lightGreen,
    Colors.deepPurple,
    Colors.black,
    Colors.pink,
    Colors.white,
    Colors.brown,
    Colors.green,
    Colors.blue,
    Colors.orange,
    Colors.red,
    Colors.purple,
    Colors.grey,
    Colors.lightBlue,
    Colors.lightGreen,
    Colors.deepPurple,
    Colors.black,
    Colors.pink,
    Colors.white,
    Colors.brown,
    Colors.green,
    Colors.blue,
    Colors.orange,
    Colors.red,
    Colors.purple,
    Colors.grey,
    Colors.lightBlue,
    Colors.lightGreen,
    Colors.deepPurple,
    Colors.black,
    Colors.pink,
    Colors.white,
    Colors.brown,
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
            _colors.length,
            (index) {
              return GestureDetector(
                onTap: () {
                  setState(
                    () {
                      _selectedColor = _colors[index];
                      widget.colorCallback(_selectedColor!);
                    },
                  );
                },
                child: Container(
                  height: 25,
                  width: 25,
                  child: _selectedColor == _colors[index]
                      ? Icon(
                          Icons.check,
                          size: 34,
                          color: _selectedColor != null
                              ? _selectedColor!.computeLuminance() > 0.5
                                  ? Colors.black
                                  : Colors.white
                              : null,
                        )
                      : null,
                  decoration: BoxDecoration(
                    color: _colors[index],
                    shape: BoxShape.circle,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
