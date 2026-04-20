// lib/api_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'question.dart';

class ApiService {
  static const String _baseUrl = 'https://opentdb.com/api.php';

  static const Map<String, String> _params = {
    'amount': '10',
    'category': '9',
    'difficulty': 'easy',
    'type': 'multiple',
  };

  static Future<List<Question>> fetchQuestions() async {
    try {
      final uri = Uri.parse(_baseUrl).replace(queryParameters: _params);
      final response = await http.get(uri);

      if (response.statusCode != 200) {
        throw Exception(
          'Server error — status code: ${response.statusCode}',
        );
      }

      if (response.body.isEmpty) {
        throw Exception('Empty response from server. Please try again.');
      }

      final Map<String, dynamic> data =
          jsonDecode(response.body) as Map<String, dynamic>;

      final int responseCode = data['response_code'] as int;
      if (responseCode != 0) {
        throw Exception(
          'Trivia API error (code $responseCode). '
          'Wait a few seconds and try again.',
        );
      }

      final List<dynamic> results = data['results'] as List<dynamic>;
      return results
          .map((item) => Question.fromJson(item as Map<String, dynamic>))
          .toList();
    } on http.ClientException catch (e) {
      throw Exception('Network error — check your connection. ($e)');
    } catch (e) {
      rethrow;
    }
  }
}