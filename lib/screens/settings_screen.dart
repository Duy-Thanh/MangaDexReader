import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../models/settings.dart';
import '../utils/network_helper.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io' show Platform;

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _hostController;
  late TextEditingController _portController;
  late TextEditingController _usernameController;
  late TextEditingController _passwordController;
  bool _isVpnActive = false;

  @override
  void initState() {
    super.initState();
    final settings = context.read<SettingsProvider>().proxySettings;
    _hostController = TextEditingController(text: settings.proxyHost);
    _portController =
        TextEditingController(text: settings.proxyPort.toString());
    _usernameController = TextEditingController(text: settings.username);
    _passwordController = TextEditingController(text: settings.password);
    _checkVpnStatus();
  }

  Future<void> _checkVpnStatus() async {
    final vpnActive = await NetworkHelper.isVpnActive();
    if (mounted) {
      setState(() {
        _isVpnActive = vpnActive;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Consumer<SettingsProvider>(
        builder: (context, settings, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // VPN Status
                Card(
                  child: ListTile(
                    leading: Icon(
                      _isVpnActive ? Icons.vpn_lock : Icons.vpn_lock_outlined,
                      color: _isVpnActive ? Colors.green : Colors.red,
                    ),
                    title: Text(
                        'VPN Status: ${_isVpnActive ? 'Active' : 'Inactive'}'),
                    subtitle: const Text(
                      'VPN is recommended for accessing MangaDex in some regions',
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: _checkVpnStatus,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                const SizedBox(height: 24),

                // Language Settings - Move this section up
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Language Settings',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Select languages for manga search and reading',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: settings.languages.map((lang) {
                            return FilterChip(
                              selected: lang.enabled,
                              label: Text(lang.name),
                              selectedColor: Theme.of(context)
                                  .primaryColor
                                  .withOpacity(0.2),
                              checkmarkColor: Theme.of(context).primaryColor,
                              onSelected: (selected) {
                                settings.toggleLanguage(lang.code);
                              },
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Proxy Settings
                const Text(
                  'Proxy Settings',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SwitchListTile(
                  title: const Text('Use Proxy'),
                  value: settings.proxySettings.useProxy,
                  onChanged: (value) {
                    settings.updateProxySettings(
                      ProxySettings(
                        useProxy: value,
                        proxyType: settings.proxySettings.proxyType,
                        proxyHost: _hostController.text,
                        proxyPort: int.tryParse(_portController.text) ?? 8080,
                        username: _usernameController.text,
                        password: _passwordController.text,
                      ),
                    );
                  },
                ),
                if (settings.proxySettings.useProxy) ...[
                  DropdownButtonFormField<String>(
                    value: settings.proxySettings.proxyType,
                    items: const [
                      DropdownMenuItem(
                          value: 'system', child: Text('System Proxy')),
                      DropdownMenuItem(
                          value: 'http', child: Text('HTTP Proxy')),
                      DropdownMenuItem(
                          value: 'socks5', child: Text('SOCKS5 Proxy')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        settings.updateProxySettings(
                          ProxySettings(
                            useProxy: true,
                            proxyType: value,
                            proxyHost: _hostController.text,
                            proxyPort:
                                int.tryParse(_portController.text) ?? 8080,
                            username: _usernameController.text,
                            password: _passwordController.text,
                          ),
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _hostController,
                    decoration: const InputDecoration(
                      labelText: 'Proxy Host',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _portController,
                    decoration: const InputDecoration(
                      labelText: 'Proxy Port',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _usernameController,
                    decoration: const InputDecoration(
                      labelText: 'Username (optional)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    decoration: const InputDecoration(
                      labelText: 'Password (optional)',
                      border: OutlineInputBorder(),
                    ),
                    obscureText: true,
                  ),
                ],

                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Credits & Attribution',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'This app is powered by MangaDex API',
                          style: TextStyle(fontSize: 16),
                        ),
                        TextButton(
                          onPressed: () async {
                            final Uri url = Uri.parse('https://mangadex.org');
                            try {
                              if (!await launchUrl(
                                url,
                                mode: LaunchMode.externalApplication,
                              )) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          'Could not open MangaDex website'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          },
                          child: const Text('Visit MangaDex'),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'All manga content is provided by volunteer scanlation groups. Please support their work!',
                          style: TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'This is a free, non-commercial, open source app with no ads or paid services.',
                          style: TextStyle(
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _hostController.dispose();
    _portController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
