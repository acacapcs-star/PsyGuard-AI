import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  AppConfig({
    required this.baseUrl,
    required this.apiKey,
    required this.model,
    required this.appEnv,
    this.isUserProvided = false,
  });

  final String baseUrl;
  final String apiKey;
  final String model;
  final String appEnv;
  final bool isUserProvided;

  bool get isConfigured =>
      baseUrl.isNotEmpty &&
      apiKey.isNotEmpty &&
      !apiKey.contains('REPLACE_WITH');

  AppConfig copyWith({
    String? baseUrl,
    String? apiKey,
    String? model,
    String? appEnv,
    bool? isUserProvided,
  }) {
    return AppConfig(
      baseUrl: baseUrl ?? this.baseUrl,
      apiKey: apiKey ?? this.apiKey,
      model: model ?? this.model,
      appEnv: appEnv ?? this.appEnv,
      isUserProvided: isUserProvided ?? this.isUserProvided,
    );
  }

  factory AppConfig.fromEnv() {
    String value(String key, {String fallback = ''}) {
      String? fromDotEnv;
      try {
        fromDotEnv = dotenv.maybeGet(key);
      } catch (_) {
        fromDotEnv = null; // 網頁版 .env 沒載入時不爆，避免設定頁黑屏
      }
      if (fromDotEnv != null && fromDotEnv.isNotEmpty) {
        return fromDotEnv;
      }
      final fromDefine = switch (key) {
        'API_BASE_URL' => const String.fromEnvironment('API_BASE_URL'),
        'API_KEY' => const String.fromEnvironment('API_KEY'),
        'AI_MODEL' => const String.fromEnvironment('AI_MODEL'),
        'APP_ENV' => const String.fromEnvironment('APP_ENV'),
        _ => '',
      };
      return fromDefine.isNotEmpty ? fromDefine : fallback;
    }

    return AppConfig(
      baseUrl: value('API_BASE_URL'),
      apiKey: value('API_KEY'),
      model: value('AI_MODEL', fallback: 'gpt-4o-mini'),
      appEnv: value('APP_ENV', fallback: 'dev'),
      isUserProvided: false,
    );
  }
}
