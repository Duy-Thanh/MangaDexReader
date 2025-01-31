import 'package:flutter/material.dart';
import '../models/settings.dart';

class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  void setThemeMode(BrightnessMode mode) {
    switch (mode) {
      case BrightnessMode.light:
        _themeMode = ThemeMode.light;
        break;
      case BrightnessMode.dark:
        _themeMode = ThemeMode.dark;
        break;
      case BrightnessMode.system:
        _themeMode = ThemeMode.system;
        break;
    }
    notifyListeners();
  }

  ThemeMode getThemeMode(BrightnessMode mode) {
    switch (mode) {
      case BrightnessMode.light:
        return ThemeMode.light;
      case BrightnessMode.dark:
        return ThemeMode.dark;
      case BrightnessMode.system:
        return ThemeMode.system;
    }
  }
}
