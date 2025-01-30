import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/settings.dart';
import 'dart:convert';

class SettingsProvider with ChangeNotifier {
  ProxySettings _proxySettings = ProxySettings();
  String _readingDirection = ReadingDirection.ltr;
  String _brightnessMode = BrightnessMode.dark;
  final SharedPreferences _prefs;
  List<Language> _languages = [];

  SettingsProvider(this._prefs) {
    _loadSettings();
  }

  ProxySettings get proxySettings => _proxySettings;
  String get readingDirection => _readingDirection;
  String get brightnessMode => _brightnessMode;
  List<Language> get languages => _languages;
  List<String> get enabledLanguageCodes =>
      _languages.where((l) => l.enabled).map((l) => l.code).toList();

  Future<void> _loadSettings() async {
    final settingsJson = _prefs.getString('proxy_settings');
    if (settingsJson != null) {
      _proxySettings = ProxySettings.fromJson(
        Map<String, dynamic>.from(json.decode(settingsJson)),
      );
    }

    _readingDirection =
        _prefs.getString('reading_direction') ?? ReadingDirection.ltr;
    _brightnessMode =
        _prefs.getString('brightness_mode') ?? BrightnessMode.dark;

    // Load language settings
    final languageSettings = _prefs.getStringList('enabled_languages');
    _languages = Language.supportedLanguages.map((lang) {
      return lang.copyWith(
        enabled: languageSettings?.contains(lang.code) ?? (lang.code == 'en'),
      );
    }).toList();

    notifyListeners();
  }

  Future<void> updateProxySettings(ProxySettings settings) async {
    _proxySettings = settings;
    await _prefs.setString('proxy_settings', json.encode(settings.toJson()));
    notifyListeners();
  }

  Future<void> toggleReadingDirection() async {
    _readingDirection = _readingDirection == ReadingDirection.ltr
        ? ReadingDirection.rtl
        : ReadingDirection.ltr;
    await _prefs.setString('reading_direction', _readingDirection);
    notifyListeners();
  }

  Future<void> toggleBrightnessMode() async {
    switch (_brightnessMode) {
      case BrightnessMode.dark:
        _brightnessMode = BrightnessMode.light;
        break;
      case BrightnessMode.light:
        _brightnessMode = BrightnessMode.auto;
        break;
      default:
        _brightnessMode = BrightnessMode.dark;
    }
    await _prefs.setString('brightness_mode', _brightnessMode);
    notifyListeners();
  }

  Future<void> toggleLanguage(String languageCode) async {
    final index = _languages.indexWhere((l) => l.code == languageCode);
    if (index != -1) {
      _languages[index] = _languages[index].copyWith(
        enabled: !_languages[index].enabled,
      );

      // Save enabled languages
      await _prefs.setStringList(
        'enabled_languages',
        enabledLanguageCodes,
      );

      notifyListeners();
    }
  }
}
