import 'dart:convert';
import 'package:connectify/core/network/token_storage.dart';
import 'package:http/http.dart' as http;

class ApiClient {
  final TokenStorage tokenStorage;
  final http.Client _client;

  ApiClient({required this.tokenStorage, http.Client? client}) : _client = client ?? http.Client();

  final baseUrl = '3.39.233.98:8080';

  Future<http.Response> get(String path) async {
    final url = Uri.http(baseUrl, path);
    final headers = await _defaultHeaders();

    final response = await _client.get(url, headers: headers);
    _logResponse('GET', url, headers, null, response);

    return response;
  }

  Future<http.Response> post(String path, {Map<String, dynamic>? body}) async {
    final url = Uri.http(baseUrl, path);
    final headers = await _defaultHeaders();
    final encodedBody = jsonEncode(body);

    final response = await _client.post(url, headers: headers, body: encodedBody);
    _logResponse('POST', url, headers, encodedBody, response);

    return response;
  }

  Future<Map<String, String>> _defaultHeaders() async {
    final accessToken = await tokenStorage.getToken();

    final headers = <String, String>{'Content-Type': 'application/json'};

    if (accessToken != null) {
      headers['Authorization'] = 'Bearer $accessToken';
    }

    return headers;
  }

  void _logResponse(String method, Uri url, Map<String, String> headers, String? requestBody, http.Response response) {
    print('''\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      $method ${url.toString()}
      Headers: $headers
      Request Body: $requestBody
    
      Response Code: ${response.statusCode}
      Response Body: ${response.body}
      ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      ''');
  }
}
