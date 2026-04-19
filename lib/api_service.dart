// lib/api_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'question.dart';

class ApiService {
  static const String _baseUrl = 'https://opentdb.com/api.php';

  static const Map<String, String> _params = {
    'amount': '10',
    'category': '9',    // General Knowledge
    'difficulty': 'easy',
    'type': 'multiple',
  };

  // Returns a list of Question objects, or throws a
  // descriptive exception the UI can catch and display
  static Future<List<Question>> fetchQuestions() async {
    try {
      // Step 1: Build the full URL with query parameters
      final uri = Uri.parse(_baseUrl).replace(queryParameters: _params);

      // Step 2: Send the GET request and wait for a response
      final response = await http.get(uri);

      // Step 3: Check the HTTP status code
      if (response.statusCode != 200) {
        throw Exception(
          'Server error — status code: ${response.statusCode}',
        );
      }

      // Step 4: Decode the raw JSON string into a Dart Map
      final Map<String, dynamic> data = jsonDecode(response.body);

      // Step 5: Check the API's own response code
      // 0 = success, 1 = no results, 2 = invalid param, 5 = rate limit
      final int responseCode = data['response_code'];
      if (responseCode != 0) {
        throw Exception(
          'Trivia API error — response code: $responseCode. '
          'Try again in a few seconds.',
        );
      }

      // Step 6: Map each JSON object in "results" to a Question
      final List<dynamic> results = data['results'];
      return results
          .map((item) => Question.fromJson(item))
          .toList();

    } on http.ClientException catch (e) {
      // Covers no internet, DNS failure, connection refused
      throw Exception('Network error — check your connection. ($e)');
    } catch (e) {
      // Re-throw anything else with context
      rethrow;
    }
  }
}