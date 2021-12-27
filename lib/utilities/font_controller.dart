import 'package:flutter/material.dart';

class FontController with ChangeNotifier {
  String _font = 'ComicNeue';
  String get font => _font;

  void comicNeue() {
    _font = 'ComicNeue';
    notifyListeners();
  }

  void defaultFont() {
    _font = '';
    notifyListeners();
  }
}
