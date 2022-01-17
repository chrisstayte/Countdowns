import 'package:flutter/material.dart';

class Global {
  static final colors = _Colors();
  static final fonts = _Fonts();
}

class _Colors {
  final defaultBackgroundColor = const Color(0XFF857DB1);
}

class _Fonts {
  final Map<String, String> fontMap = const {
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
    'DiarioDeAndy': 'Diario De Andy'
  };
}
