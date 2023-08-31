import 'package:auto_size_text/auto_size_text.dart';
import 'package:countdowns/global/global.dart';
import 'package:flutter/material.dart';

typedef OnFontSelected = void Function(String fontFamily);

class FontContainer extends StatelessWidget {
  const FontContainer(
      {super.key, required this.fontFamily, required this.onFontSelected});

  final OnFontSelected onFontSelected;
  final String fontFamily;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      padding: const EdgeInsets.all(8),
      childAspectRatio: 2.0,
      mainAxisSpacing: 5,
      crossAxisSpacing: 5,
      crossAxisCount: 3,
      children: Global.fonts.fontMap.keys
          .map(
            (key) => GestureDetector(
              onTap: () => onFontSelected(key),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: key == fontFamily
                        ? Theme.of(context).primaryColor
                        : Theme.of(context).unselectedWidgetColor,
                    width: key == fontFamily ? 4 : 2,
                  ),
                  color: key == fontFamily
                      ? Theme.of(context).scaffoldBackgroundColor
                      : Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(60),
                ),
                child: Center(
                  child: AutoSizeText(
                    Global.fonts.fontMap[key]!,
                    maxLines: 2,
                    textAlign: TextAlign.center,
                    minFontSize: 12,
                    style: TextStyle(fontFamily: key, fontSize: 17),
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}
