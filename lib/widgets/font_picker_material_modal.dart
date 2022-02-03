import 'package:countdowns/global/global.dart';
import 'package:flutter/material.dart';

class FontPickerMaterialModal extends StatefulWidget {
  FontPickerMaterialModal({Key? key, this.fontName, required this.fontCallback})
      : super(key: key);

  String? fontName;
  FontCallback fontCallback;

  @override
  _FontPickerMaterialModalState createState() =>
      _FontPickerMaterialModalState();
}

typedef void FontCallback(String fontName, String fontDisplayName);

class _FontPickerMaterialModalState extends State<FontPickerMaterialModal> {
  String? _selectedFont;

  @override
  void initState() {
    _selectedFont = widget.fontName ?? 'Default';
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      builder: (context, scrollController) {
        return ListView.builder(
          controller: scrollController,
          itemCount: Global.fonts.fontMap.length,
          itemBuilder: (context, index) {
            String fontName = Global.fonts.fontMap.keys.toList()[index];
            String fontDisplayName =
                Global.fonts.fontMap.values.toList()[index];
            return ListTile(
              title: Text(
                fontDisplayName,
                style: TextStyle(
                  fontFamily: fontName,
                ),
              ),
              trailing:
                  _selectedFont == Global.fonts.fontMap.keys.toList()[index]
                      ? const Icon(Icons.check)
                      : null,
              onTap: () {
                setState(
                  () {
                    _selectedFont = fontName;
                  },
                );
                widget.fontCallback(fontName, fontDisplayName);
              },
            );
          },
        );
      },
    );
  }
}
