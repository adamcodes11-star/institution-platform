import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/institution.dart';

class InstitutionService {
  static const String _baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8080',
  );

  Future<List<Institution>> getAllInstitutions() async {
    final response = await http
        .get(Uri.parse('$_baseUrl/api/institutions'))
        .timeout(const Duration(seconds: 15));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Unable to load institutions (${response.statusCode})',
      );
    }

    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is! List) {
      throw const FormatException('Invalid institution response');
    }

    return decoded
        .whereType<Map<String, dynamic>>()
        .map(Institution.fromJson)
        .toList();
  }
}
