import 'package:flutter/material.dart';

class Global {
  static final colors = _Colors();
  static final fonts = _Fonts();
  static final styles = _Styles();
}

class _Colors {
  final Color primaryColor = const Color(0Xff7877E6);
  final Color secondaryColor = const Color(0XFF4A0D67);
  final Color accentColor = const Color(0XFFB3B2F7);
  final Color lightBackgroundColor = const Color(0XFFDEE2FF);
  final Color darkBackgroundColor = const Color(0XFF121212);
  final Color darkBackgroundColorLighter = const Color(0XFF282828);
  final Color offColor = Color(0xFFCC5803);
}

class _Styles {
  final BorderRadius containerCornerRadius = BorderRadius.circular(20);
}

class _Fonts {
  // list of fonts associated with theri pretty names
  final Map<String, String> fontMap = const {
    'Default': 'Regular',
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
