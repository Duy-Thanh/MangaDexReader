import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/settings.dart';
import 'dart:convert';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../main.dart';

class SettingsProvider with ChangeNotifier {
  ProxySettings _proxySettings = ProxySettings();
  ReadingDirection _readingDirection = ReadingDirection.LTR;
  BrightnessMode _brightnessMode = BrightnessMode.dark;
  bool _dataSavingMode = false;
  final SharedPreferences _prefs;
  List<Language> _languages = [];

  SharedPreferences get prefs => _prefs;

  SettingsProvider(this._prefs) {
    _loadSettings();
  }

  ProxySettings get proxySettings => _proxySettings;
  ReadingDirection get readingDirection => _readingDirection;
  BrightnessMode get brightnessMode => _brightnessMode;
  List<Language> get languages => _languages;
  List<String> get enabledLanguageCodes =>
      _languages.where((l) => l.enabled).map((l) => l.code).toList();
  bool get dataSavingMode => _dataSavingMode;

  Future<void> _loadSettings() async {
    final settingsJson = _prefs.getString('proxy_settings');
    if (settingsJson != null) {
      _proxySettings = ProxySettings.fromJson(
        Map<String, dynamic>.from(json.decode(settingsJson)),
      );
    }

    _readingDirection = ReadingDirection.values.firstWhere(
      (e) => e.toString() == _prefs.getString('reading_direction'),
      orElse: () => ReadingDirection.LTR,
    );

    _brightnessMode = BrightnessMode.values.firstWhere(
      (e) => e.toString() == _prefs.getString('brightnessMode'),
      orElse: () => BrightnessMode.dark,
    );

    final languageSettings = _prefs.getStringList('enabled_languages');
    _languages = Language.supportedLanguages.map((lang) {
      return lang.copyWith(
        enabled: languageSettings?.contains(lang.code) ?? (lang.code == 'en'),
      );
    }).toList();

    _dataSavingMode = _prefs.getBool('data_saving_mode') ?? false;
    notifyListeners();
  }

  Future<void> updateProxySettings(ProxySettings settings) async {
    _proxySettings = settings;
    await _prefs.setString('proxy_settings', json.encode(settings.toJson()));
    notifyListeners();
  }

  void updateReadingDirection(ReadingDirection direction) {
    _readingDirection = direction;
    _prefs.setString('reading_direction', direction.toString());
    notifyListeners();
  }

  void updateBrightnessMode(BrightnessMode mode) {
    _brightnessMode = mode;
    _prefs.setString('brightnessMode', mode.toString());
    // Get ThemeProvider and update theme
    Provider.of<ThemeProvider>(navigatorKey.currentContext!, listen: false)
        .setThemeMode(mode);
    notifyListeners();
  }

  Future<void> toggleLanguage(String languageCode) async {
    final index = _languages.indexWhere((l) => l.code == languageCode);
    if (index != -1) {
      _languages[index] = _languages[index].copyWith(
        enabled: !_languages[index].enabled,
      );

      await _prefs.setStringList(
        'enabled_languages',
        enabledLanguageCodes,
      );

      notifyListeners();
    }
  }

  Future<void> _saveSettings() async {
    await _prefs.setString('reading_direction', _readingDirection.toString());
    await _prefs.setString('brightnessMode', _brightnessMode.toString());
    await _prefs.setStringList(
      'enabled_languages',
      enabledLanguageCodes,
    );
  }

  void toggleReadingDirection() {
    updateReadingDirection(_readingDirection == ReadingDirection.LTR
        ? ReadingDirection.RTL
        : ReadingDirection.LTR);
  }

  void toggleBrightnessMode() {
    switch (_brightnessMode) {
      case BrightnessMode.dark:
        updateBrightnessMode(BrightnessMode.light);
        break;
      case BrightnessMode.light:
        updateBrightnessMode(BrightnessMode.system);
        break;
      case BrightnessMode.system:
        updateBrightnessMode(BrightnessMode.dark);
        break;
    }
  }

  Future<void> updateDataSavingMode(bool value) async {
    _dataSavingMode = value;
    await _prefs.setBool('data_saving_mode', value);
    notifyListeners();
  }
}
