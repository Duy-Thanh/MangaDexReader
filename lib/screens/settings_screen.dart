import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../models/settings.dart';
import '../utils/network_helper.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io' show Platform;
import '../screens/language_settings_screen.dart';
import '../services/image_cache_service.dart';
import 'package:extended_image/extended_image.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'General',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          // Reading Direction
          _buildSection(
            title: 'Reading Direction',
            child: Consumer<SettingsProvider>(
              builder: (context, settings, _) => Column(
                children: [
                  RadioListTile<ReadingDirection>(
                    title: const Text('Left to Right'),
                    secondary: const Icon(Icons.format_textdirection_l_to_r),
                    value: ReadingDirection.LTR,
                    groupValue: settings.readingDirection,
                    onChanged: (value) =>
                        settings.updateReadingDirection(value!),
                  ),
                  RadioListTile<ReadingDirection>(
                    title: const Text('Right to Left'),
                    secondary: const Icon(Icons.format_textdirection_r_to_l),
                    value: ReadingDirection.RTL,
                    groupValue: settings.readingDirection,
                    onChanged: (value) =>
                        settings.updateReadingDirection(value!),
                  ),
                ],
              ),
            ),
          ),

          // Theme Mode
          _buildSection(
            title: 'Theme',
            child: Consumer<SettingsProvider>(
              builder: (context, settings, _) => Column(
                children: [
                  RadioListTile<BrightnessMode>(
                    title: const Text('Light'),
                    secondary: const Icon(Icons.brightness_7),
                    value: BrightnessMode.light,
                    groupValue: settings.brightnessMode,
                    onChanged: (value) => settings.updateBrightnessMode(value!),
                  ),
                  RadioListTile<BrightnessMode>(
                    title: const Text('Dark'),
                    secondary: const Icon(Icons.brightness_4),
                    value: BrightnessMode.dark,
                    groupValue: settings.brightnessMode,
                    onChanged: (value) => settings.updateBrightnessMode(value!),
                  ),
                  RadioListTile<BrightnessMode>(
                    title: const Text('System'),
                    secondary: const Icon(Icons.brightness_auto),
                    value: BrightnessMode.system,
                    groupValue: settings.brightnessMode,
                    onChanged: (value) => settings.updateBrightnessMode(value!),
                  ),
                ],
              ),
            ),
          ),

          // Language Settings
          _buildSection(
            title: 'Languages',
            child: ListTile(
              leading: const Icon(Icons.language),
              title: const Text('Language Settings'),
              subtitle: Consumer<SettingsProvider>(
                builder: (context, settings, _) => Text(
                  '${settings.enabledLanguageCodes.length} languages enabled',
                ),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LanguageSettingsScreen(),
                  ),
                );
              },
            ),
          ),

          // Add Proxy Settings section
          _buildSection(
            title: 'Proxy Settings',
            child: Consumer<SettingsProvider>(
              builder: (context, settings, _) => Column(
                children: [
                  SwitchListTile(
                    title: const Text('Use Proxy'),
                    subtitle: const Text('Enable proxy for network requests'),
                    value: settings.proxySettings.useProxy,
                    onChanged: (enabled) {
                      settings.updateProxySettings(
                        settings.proxySettings.copyWith(useProxy: enabled),
                      );
                    },
                  ),
                  if (settings.proxySettings.useProxy) ...[
                    ListTile(
                      title: const Text('Proxy Type'),
                      trailing: DropdownButton<String>(
                        value: settings.proxySettings.proxyType,
                        items: const [
                          DropdownMenuItem(
                              value: 'system', child: Text('System')),
                          DropdownMenuItem(value: 'http', child: Text('HTTP')),
                          DropdownMenuItem(
                              value: 'socks5', child: Text('SOCKS5')),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            settings.updateProxySettings(
                              settings.proxySettings.copyWith(proxyType: value),
                            );
                          }
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TextField(
                        decoration: const InputDecoration(
                          labelText: 'Proxy Host',
                          hintText: 'e.g., proxy.example.com',
                        ),
                        onChanged: (value) {
                          settings.updateProxySettings(
                            settings.proxySettings.copyWith(proxyHost: value),
                          );
                        },
                        controller: TextEditingController(
                          text: settings.proxySettings.proxyHost,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TextField(
                        decoration: const InputDecoration(
                          labelText: 'Proxy Port',
                          hintText: 'e.g., 8080',
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          settings.updateProxySettings(
                            settings.proxySettings.copyWith(
                              proxyPort: int.tryParse(value) ?? 8080,
                            ),
                          );
                        },
                        controller: TextEditingController(
                          text: settings.proxySettings.proxyPort.toString(),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Network Test
          _buildSection(
            title: 'Network',
            child: ListTile(
              leading: const Icon(Icons.network_check),
              title: const Text('Test Connection'),
              subtitle: const Text('Check connection to MangaDex'),
              onTap: () async {
                // Show loading indicator
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Row(
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        SizedBox(width: 16),
                        Text('Testing connection...'),
                      ],
                    ),
                    duration: Duration(seconds: 1),
                  ),
                );

                try {
                  final result = await NetworkHelper.testConnection();
                  if (!context.mounted) return;

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          Icon(
                            result ? Icons.check_circle : Icons.error,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 16),
                          Text(
                            result
                                ? 'Connection successful!'
                                : 'Connection failed',
                          ),
                        ],
                      ),
                      backgroundColor: result ? Colors.green : Colors.red,
                    ),
                  );
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(Icons.error, color: Colors.white),
                          const SizedBox(width: 16),
                          Expanded(child: Text('Error: $e')),
                        ],
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
            ),
          ),

          // About Section
          _buildSection(
            title: 'About',
            child: ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('Version'),
              subtitle: const Text('0.1.0'),
              onTap: () {
                showAboutDialog(
                  context: context,
                  applicationName: 'Manga Reader',
                  applicationVersion: '0.1.0',
                  applicationIcon: const Icon(
                    Icons.book_rounded,
                    size: 48,
                    color: Colors.deepPurple,
                  ),
                  children: const [
                    Text('A simple manga reader app built with Flutter.'),
                    SizedBox(height: 8),
                    Text('Powered by MangaDex API'),
                  ],
                );
              },
            ),
          ),

          // Data Saving Mode
          _buildSection(
            title: 'Data Saving',
            child: Column(
              children: [
                FutureBuilder<bool>(
                  future: ImageCacheService.isSystemDataSavingEnabled(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData && snapshot.data!) {
                      return ListTile(
                        leading: const Icon(Icons.data_saver_on),
                        title: Text(Platform.isIOS
                            ? 'Low Data Mode Enabled'
                            : 'Data Saver Enabled'),
                        subtitle: const Text('System data saving is active'),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
                Consumer<SettingsProvider>(
                  builder: (context, settings, _) => SwitchListTile(
                    title: const Text('App Data Saving Mode'),
                    subtitle: const Text(
                        'Reduce data usage by limiting preloading when system data saving is off'),
                    value: settings.dataSavingMode,
                    onChanged: (value) {
                      settings.updateDataSavingMode(value);
                      if (value) {
                        ImageCacheService.clearCache();
                      }
                    },
                  ),
                ),
              ],
            ),
          ),

          // Add Cache section
          _buildSection(
            title: 'Cache',
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.storage),
                  title: const Text('Image Cache'),
                  subtitle: const CacheSizeDisplay(),
                  trailing: TextButton(
                    child: const Text('CLEAR'),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Clear Cache'),
                          content: const Text(
                            'Are you sure you want to clear the image cache? '
                            'This will free up storage space but may increase data usage.',
                          ),
                          actions: [
                            TextButton(
                              child: const Text('CANCEL'),
                              onPressed: () => Navigator.pop(context),
                            ),
                            TextButton(
                              child: const Text('CLEAR'),
                              onPressed: () async {
                                await ImageCacheService.clearCache();
                                // Also clear the cache manager
                                await ImageCacheService.cacheManager
                                    .emptyCache();
                                // Clear extended image cache
                                clearMemoryImageCache();

                                if (!context.mounted) return;
                                Navigator.pop(context);

                                // Find and update the cache size display
                                final cacheSizeState =
                                    context.findAncestorStateOfType<
                                        _CacheSizeDisplayState>();
                                cacheSizeState?._updateCacheSize();

                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Cache cleared'),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

// Add this widget to handle cache size display
class CacheSizeDisplay extends StatefulWidget {
  const CacheSizeDisplay({super.key});

  @override
  State<CacheSizeDisplay> createState() => _CacheSizeDisplayState();
}

class _CacheSizeDisplayState extends State<CacheSizeDisplay> {
  String _cacheSize = 'Calculating...';

  @override
  void initState() {
    super.initState();
    _updateCacheSize();
  }

  Future<void> _updateCacheSize() async {
    final size = await ImageCacheService.getCacheSize();
    if (mounted) {
      setState(() {
        _cacheSize = size;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Text(_cacheSize);
  }
}
