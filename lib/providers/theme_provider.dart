import 'package:flutter/material.dart';
import '../models/settings.dart';

class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  void setThemeMode(BrightnessMode mode) {
    switch (mode) {
      case BrightnessMode.LIGHT:
        _themeMode = ThemeMode.light;
        break;
      case BrightnessMode.DARK:
        _themeMode = ThemeMode.dark;
        break;
      case BrightnessMode.SYSTEM:
        _themeMode = ThemeMode.system;
        break;
    }
    notifyListeners();
  }
}
