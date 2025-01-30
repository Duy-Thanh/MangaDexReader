import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../models/settings.dart';

class LanguageSettingsScreen extends StatelessWidget {
  const LanguageSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Languages'),
        elevation: 0,
      ),
      body: Consumer<SettingsProvider>(
        builder: (context, settings, _) => ListView(
          children: Language.supportedLanguages.map((lang) {
            return SwitchListTile(
              title: Text(lang.name),
              secondary: Text(_getLanguageFlag(lang.code)),
              value: settings.enabledLanguageCodes.contains(lang.code),
              onChanged: (enabled) => settings.toggleLanguage(lang.code),
            );
          }).toList(),
        ),
      ),
    );
  }

  String _getLanguageFlag(String code) {
    switch (code) {
      case 'en':
        return '🇺🇸';
      case 'vi':
        return '🇻🇳';
      case 'ja':
        return '🇯🇵';
      case 'ko':
        return '🇰🇷';
      case 'zh':
        return '🇨🇳';
      case 'zh-hk':
        return '🇭🇰';
      case 'fr':
        return '🇫🇷';
      case 'de':
        return '🇩🇪';
      case 'es':
        return '🇪🇸';
      case 'it':
        return '🇮🇹';
      case 'ru':
        return '🇷🇺';
      case 'pt':
        return '🇵🇹';
      case 'pl':
        return '🇵🇱';
      case 'th':
        return '🇹🇭';
      case 'id':
        return '🇮🇩';
      default:
        return '🏳️';
    }
  }
}
