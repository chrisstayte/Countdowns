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

  final Map<String, String> _fonts = {
    'Default': 'Default',
    'LibreBaskerville': 'Baskerville',
    'CarnivaleeFreakshow': 'Carnivalee Freakshow',
    'ComicNeue': 'Comic Neue',
    'GoodTimes': 'Good Times',
    'Roboto': 'Roboto',
    'LuxuriousRoman': 'Luxurious Roman',
    'Starjedi': 'Not Starwars',
    'Sunnyspells': 'Sunnyspells',
    'NewWaltDisney': 'Not Disney',
  };

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      builder: (context, scrollController) {
        return ListView.builder(
          controller: scrollController,
          itemCount: _fonts.length,
          itemBuilder: (context, index) {
            String fontName = _fonts.keys.toList()[index];
            String fontDisplayName = _fonts.values.toList()[index];
            return ListTile(
              title: Text(
                fontDisplayName,
                style: TextStyle(
                  fontFamily: fontName,
                ),
              ),
              trailing: _selectedFont == _fonts.keys.toList()[index]
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
