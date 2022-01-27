import 'package:countdowns/utilities/settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/src/provider.dart';

class ColorPickerMaterialModal extends StatefulWidget {
  //const ColorPickerMaterialModal.empty({Key? key}) : super(key: key);
  ColorPickerMaterialModal({Key? key, this.color, required this.colorCallback})
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
    const Color(0XFF223843),
    const Color(0XFFD77A61),
    const Color(0XFFBB84E7),
    const Color(0XFFA3C4F3),
    const Color(0XFF568D66),
    const Color(0XFFF15152),
    const Color(0XFFFF9500),
    const Color(0XFF0a9396),
    const Color(0XFFF7E7CE),
    const Color(0XFF6b705c),
    const Color(0XFF1d3557),
    const Color(0xFFfad2e1),
    const Color(0XFFf07167),
    const Color(0XFF3c6e71),
    const Color(0XFF22223b),
    const Color(0XFFfca311),
    const Color(0XFF6a040f),
    const Color(0XFFcdb4db),
    const Color(0XFF1b4332),
    const Color(0XFFee6c4d),
    const Color(0XFF98c1d9),
    const Color(0XFF3d5a80),
    const Color(0XFF822faf),
    const Color(0XFF008000),
    const Color(0XFF484a47),
    const Color(0XFF22333b),
    const Color(0XFFf7fff7),
    const Color(0XFFadb5bd),
    const Color(0XFF312244),
    const Color(0XFFffdab9),
    const Color(0XFFf15bb5),
    const Color(0XFFa3cef1),
    const Color(0XFFF76F8E),
    const Color(0XFF212529),
    const Color(0XFF504136),
    const Color(0XFF4C243B),
    const Color(0XFFFF715B),
    const Color(0XFF1EA896),
    const Color(0XFF4C5454),
    const Color(0XFF724CF9),
    const Color(0XFF32533D),
    Colors.green,
    Colors.blue,
    Colors.orange,
    Colors.red,
    Colors.purple,
    Colors.grey,
    Colors.lightBlue,
    Colors.white,
    Colors.teal,
    Colors.black,
    Colors.yellow,
    Colors.lime,
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
                    },
                  );
                  widget.colorCallback(_selectedColor!);
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
