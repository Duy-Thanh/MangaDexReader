class ProxySettings {
  final bool useProxy;
  final String proxyType; // 'system', 'http', 'socks5'
  final String proxyHost;
  final int proxyPort;
  final String? username;
  final String? password;

  ProxySettings({
    this.useProxy = false,
    this.proxyType = 'system',
    this.proxyHost = '',
    this.proxyPort = 8080,
    this.username,
    this.password,
  });

  factory ProxySettings.fromJson(Map<String, dynamic> json) {
    return ProxySettings(
      useProxy: json['useProxy'] ?? false,
      proxyType: json['proxyType'] ?? 'system',
      proxyHost: json['proxyHost'] ?? '',
      proxyPort: json['proxyPort'] ?? 8080,
      username: json['username'],
      password: json['password'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'useProxy': useProxy,
      'proxyType': proxyType,
      'proxyHost': proxyHost,
      'proxyPort': proxyPort,
      'username': username,
      'password': password,
    };
  }
}

class ReadingDirection {
  static const ltr = 'ltr';
  static const rtl = 'rtl';
}

class BrightnessMode {
  static const auto = 'auto';
  static const light = 'light';
  static const dark = 'dark';
}

class Language {
  final String code;
  final String name;
  final bool enabled;

  const Language({
    required this.code,
    required this.name,
    this.enabled = false,
  });

  Language copyWith({bool? enabled}) {
    return Language(
      code: code,
      name: name,
      enabled: enabled ?? this.enabled,
    );
  }

  static const List<Language> supportedLanguages = [
    Language(code: 'en', name: 'English'),
    Language(code: 'vi', name: 'Vietnamese'),
    Language(code: 'ja', name: 'Japanese'),
    Language(code: 'ko', name: 'Korean'),
    Language(code: 'zh', name: 'Chinese'),
    Language(code: 'zh-hk', name: 'Chinese (Traditional)'),
    Language(code: 'fr', name: 'French'),
    Language(code: 'id', name: 'Indonesian'),
    Language(code: 'th', name: 'Thai'),
    Language(code: 'ru', name: 'Russian'),
  ];
}
