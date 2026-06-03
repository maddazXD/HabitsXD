import 'dart:convert';
import 'package:http/http.dart' as http;

class AIService {
  AIService._();
  static final instance = AIService._();

  static const _defaultApiUrl = 'https://gemini.googleapis.com/v1/chat/completions';
  // NOTE: API key removed to comply with repository push protection.
  // If you intend to ship a built-in key, store it securely outside VCS
  // or use a secrets manager. For local testing, set the key via env or
  // a secure platform-specific mechanism.
  static const _defaultApiKey = '<REDACTED_OR_USE_ENV>'; 
  static const _defaultModel = 'gemini-3.5-flash';

  Future<String> summarizeText({
    required String text,
  }) async {
    final prompt = '''You are a helpful writing assistant. Summarize the following note into a short and clear paragraph in Indonesian, preserving the main ideas and action points.

$text''';
    return _callModel(prompt: prompt);
  }

  Future<String> generateTasksFromText({
    required String text,
  }) async {
    final prompt = '''You are a productivity assistant. Read this note and generate a simple checklist of 3-5 action items in Indonesian that can be turned into tasks.

Note:
$text''';
    return _callModel(prompt: prompt);
  }

  Future<String> suggestTitle({
    required String text,
  }) async {
    final prompt = '''You are a smart assistant for note titles. Read the note content and suggest a concise and meaningful title in Indonesian.

Note:
$text''';
    return _callModel(prompt: prompt);
  }

  Future<String> _callModel({
    required String prompt,
  }) async {
    final response = await http.post(
      Uri.parse(_defaultApiUrl),
      headers: {
        'Authorization': 'Bearer $_defaultApiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': _defaultModel,
        'messages': [
          {'role': 'system', 'content': 'You are an intelligent assistant.'},
          {'role': 'user', 'content': prompt},
        ],
        'temperature': 0.7,
        'max_tokens': 300,
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('AI service error: ${response.statusCode} ${response.body}');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final choices = body['choices'] as List<dynamic>?;
    if (choices == null || choices.isEmpty) {
      throw Exception('AI service returned no response.');
    }

    final message = choices.first['message'] as Map<String, dynamic>?;
    return message?['content'] as String? ?? 'No result';
  }
}
