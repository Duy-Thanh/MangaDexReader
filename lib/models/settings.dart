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

  ProxySettings copyWith({
    bool? useProxy,
    String? proxyType,
    String? proxyHost,
    int? proxyPort,
    String? username,
    String? password,
  }) {
    return ProxySettings(
      useProxy: useProxy ?? this.useProxy,
      proxyType: proxyType ?? this.proxyType,
      proxyHost: proxyHost ?? this.proxyHost,
      proxyPort: proxyPort ?? this.proxyPort,
      username: username ?? this.username,
      password: password ?? this.password,
    );
  }

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

enum ReadingDirection {
  LTR,
  RTL,
}

enum BrightnessMode {
  LIGHT,
  DARK,
  SYSTEM,
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
    Language(code: 'zh', name: 'Chinese (Simplified)'),
    Language(code: 'zh-hk', name: 'Chinese (Traditional)'),
    Language(code: 'fr', name: 'French'),
    Language(code: 'de', name: 'German'),
    Language(code: 'es', name: 'Spanish'),
    Language(code: 'it', name: 'Italian'),
    Language(code: 'ru', name: 'Russian'),
    Language(code: 'pt', name: 'Portuguese'),
    Language(code: 'pl', name: 'Polish'),
    Language(code: 'th', name: 'Thai'),
    Language(code: 'id', name: 'Indonesian'),
  ];
}

class Settings {
  final bool useProxy;
  final String proxyType; // 'system', 'http', 'socks5'
  final String proxyHost;
  final int proxyPort;
  final String? username;
  final String? password;
  final bool dataSavingMode;

  Settings({
    this.useProxy = false,
    this.proxyType = 'system',
    this.proxyHost = '',
    this.proxyPort = 8080,
    this.username,
    this.password,
    this.dataSavingMode = false,
  });

  Settings copyWith({
    bool? useProxy,
    String? proxyType,
    String? proxyHost,
    int? proxyPort,
    String? username,
    String? password,
    bool? dataSavingMode,
  }) {
    return Settings(
      useProxy: useProxy ?? this.useProxy,
      proxyType: proxyType ?? this.proxyType,
      proxyHost: proxyHost ?? this.proxyHost,
      proxyPort: proxyPort ?? this.proxyPort,
      username: username ?? this.username,
      password: password ?? this.password,
      dataSavingMode: dataSavingMode ?? this.dataSavingMode,
    );
  }

  factory Settings.fromJson(Map<String, dynamic> json) {
    return Settings(
      useProxy: json['useProxy'] ?? false,
      proxyType: json['proxyType'] ?? 'system',
      proxyHost: json['proxyHost'] ?? '',
      proxyPort: json['proxyPort'] ?? 8080,
      username: json['username'],
      password: json['password'],
      dataSavingMode: json['dataSavingMode'] ?? false,
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
      'dataSavingMode': dataSavingMode,
    };
  }
}
