import 'package:flutter/material.dart';

class Settings extends ChangeNotifier {
  bool darkMode = false;
  String? fontFamily;

  void setDarkMode(bool isDark) {
    darkMode = isDark;
    notifyListeners();
  }

  void changeFont() {
    fontFamily = 'ComicNeue';
    notifyListeners();
  }
}
