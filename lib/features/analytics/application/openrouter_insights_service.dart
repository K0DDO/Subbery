import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import 'analytics_metrics.dart';

class OpenRouterInsightsService {
  OpenRouterInsightsService({
    http.Client? client,
    FlutterSecureStorage? storage,
    this.defaultApiKey = '',
  }) : _client = client ?? http.Client(),
       _storage = storage ?? const FlutterSecureStorage();

  static const storageKey = 'openrouter_api_key';
  static const endpoint = 'https://openrouter.ai/api/v1/chat/completions';
  static const model = 'openai/gpt-4o';
  static const referer = 'https://github.com/subberry/subberry';
  static const appTitle = 'Subberry';

  final http.Client _client;
  final FlutterSecureStorage _storage;
  final String defaultApiKey;

  Future<String?> readApiKey() async {
    final stored = await _storage.read(key: storageKey);
    if (stored != null && stored.trim().isNotEmpty) {
      return stored.trim();
    }
    if (defaultApiKey.trim().isEmpty) return null;
    await _storage.write(key: storageKey, value: defaultApiKey.trim());
    return defaultApiKey.trim();
  }

  Future<void> saveApiKey(String key) async {
    final normalized = key.trim();
    if (normalized.isEmpty) {
      await _storage.delete(key: storageKey);
      return;
    }
    await _storage.write(key: storageKey, value: normalized);
  }

  Future<List<AnalyticsInsight>> generateInsights(
    Map<String, Object?> summary,
  ) async {
    final apiKey = await readApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      throw StateError('OpenRouter API key is missing');
    }

    final response = await _client
        .post(
          Uri.parse(endpoint),
          headers: <String, String>{
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
            'HTTP-Referer': referer,
            'X-Title': appTitle,
          },
          body: jsonEncode(<String, Object?>{
            'model': model,
            'temperature': 0.7,
            'messages': <Map<String, String>>[
              <String, String>{
                'role': 'system',
                'content':
                    'Ты финансовый ассистент приложения Subberry (учёт подписок). '
                    'Отвечай только валидным JSON-массивом из ровно 3 объектов '
                    'без markdown и пояснений. Каждый объект: '
                    '{"title":"...","detail":"..."}. '
                    'title до 56 символов, detail до 140 символов. '
                    'Пиши по-русски, конкретно по данным пользователя, '
                    'без воды и без эмодзи. Дай практичные наблюдения: '
                    'экономия, дубликаты, рост трат, категорию-лидера, '
                    'долгие подписки.',
              },
              <String, String>{
                'role': 'user',
                'content':
                    'Сформируй 3 умные подсказки по этим данным:\n'
                    '${jsonEncode(summary)}',
              },
            ],
          }),
        )
        .timeout(const Duration(seconds: 25));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError(
        'OpenRouter HTTP ${response.statusCode}: ${response.body}',
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Unexpected OpenRouter payload');
    }
    final choices = decoded['choices'];
    if (choices is! List || choices.isEmpty) {
      throw const FormatException('OpenRouter returned no choices');
    }
    final message = choices.first;
    if (message is! Map<String, dynamic>) {
      throw const FormatException('Invalid OpenRouter choice');
    }
    final content = message['message'];
    if (content is! Map<String, dynamic>) {
      throw const FormatException('Invalid OpenRouter message');
    }
    final text = content['content']?.toString() ?? '';
    return parseInsights(text);
  }

  static List<AnalyticsInsight> parseInsights(String raw) {
    final trimmed = raw.trim();
    final jsonSlice = _extractJsonArray(trimmed);
    final decoded = jsonDecode(jsonSlice);
    if (decoded is! List) {
      throw const FormatException('Insights JSON must be an array');
    }

    final insights = <AnalyticsInsight>[];
    for (final item in decoded.take(3)) {
      if (item is! Map) continue;
      final title = item['title']?.toString().trim() ?? '';
      final detail = item['detail']?.toString().trim() ?? '';
      if (title.isEmpty || detail.isEmpty) continue;
      insights.add(
        AnalyticsInsight(
          type: AnalyticsInsightType.ai,
          title: title,
          detail: detail,
        ),
      );
    }
    if (insights.isEmpty) {
      throw const FormatException('No usable insights in model response');
    }
    return insights;
  }

  static String _extractJsonArray(String text) {
    final start = text.indexOf('[');
    final end = text.lastIndexOf(']');
    if (start >= 0 && end > start) {
      return text.substring(start, end + 1);
    }
    return text;
  }
}
