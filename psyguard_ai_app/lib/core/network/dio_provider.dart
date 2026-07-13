import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/app_config.dart';
import 'app_config_controller.dart';

// 我們把 config 參數加回去，讓其他檔案不會報錯
Dio buildDioForAppConfig(AppConfig config) {
  return Dio(
    BaseOptions(
      // 這裡強制寫死 Google 的網址，徹底無視設定頁面填的內容
      baseUrl: config.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Content-Type': 'application/json'},
    ),
  );
}

final dioProvider = Provider<Dio>((ref) {
  final config = ref.watch(appConfigProvider);
  return buildDioForAppConfig(config);
});