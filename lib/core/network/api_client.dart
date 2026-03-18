import 'dart:convert';
import 'package:connectify/core/network/token_storage.dart';
import 'package:http/http.dart' as http;

class ApiClient {
  final TokenStorage tokenStorage;
  final http.Client _client;

  ApiClient({required this.tokenStorage, http.Client? client}) : _client = client ?? http.Client();

  final baseUrl = 'https://connectify-api-server-49287274728.us-west1.run.app';

  Future<http.Response> get(String path) async {
    final url = _buildUri(path);
    final headers = await _defaultHeaders();
    try {
      final response = await _client.get(url, headers: headers);
      _logResponse('GET', url, headers, null, response);

      if (response.statusCode >= 400) {
        _logHttpError('GET', url, response);
      }

      return response;
    } catch (error, stackTrace) {
      _logException('GET', url, error, stackTrace);
      rethrow;
    }
  }

  Future<http.Response> post(String path, {Map<String, dynamic>? body}) async {
    final url = _buildUri(path);
    final headers = await _defaultHeaders();
    final encodedBody = jsonEncode(body);
    try {
      final response = await _client.post(url, headers: headers, body: encodedBody);
      _logResponse('POST', url, headers, encodedBody, response);

      if (response.statusCode >= 400) {
        _logHttpError('POST', url, response);
      }

      return response;
    } catch (error, stackTrace) {
      _logException('POST', url, error, stackTrace);
      rethrow;
    }
  }

  Future<http.Response> put(String path, {Map<String, dynamic>? body}) async {
    final url = _buildUri(path);
    final headers = await _defaultHeaders();
    final encodedBody = jsonEncode(body);
    try {
      final response = await _client.put(url, headers: headers, body: encodedBody);
      _logResponse('PUT', url, headers, encodedBody, response);

      if (response.statusCode >= 400) {
        _logHttpError('PUT', url, response);
      }

      return response;
    } catch (error, stackTrace) {
      _logException('PUT', url, error, stackTrace);
      rethrow;
    }
  }

  Future<http.Response> patch(String path, {Map<String, dynamic>? body}) async {
    final url = _buildUri(path);
    final headers = await _defaultHeaders();
    final encodedBody = jsonEncode(body);
    try {
      final response = await _client.patch(url, headers: headers, body: encodedBody);
      _logResponse('PATCH', url, headers, encodedBody, response);

      if (response.statusCode >= 400) {
        _logHttpError('PATCH', url, response);
      }

      return response;
    } catch (error, stackTrace) {
      _logException('PATCH', url, error, stackTrace);
      rethrow;
    }
  }

  Future<http.Response> delete(String path, {Map<String, dynamic>? body}) async {
    final url = _buildUri(path);
    final headers = await _defaultHeaders();
    final encodedBody = body == null ? null : jsonEncode(body);
    try {
      final response = await _client.delete(url, headers: headers, body: encodedBody);
      _logResponse('DELETE', url, headers, encodedBody, response);

      if (response.statusCode >= 400) {
        _logHttpError('DELETE', url, response);
      }

      return response;
    } catch (error, stackTrace) {
      _logException('DELETE', url, error, stackTrace);
      rethrow;
    }
  }

  Future<http.Response> putAbsolute(String url, {required List<int> bodyBytes, Map<String, String>? headers}) async {
    final uri = Uri.parse(url);
    try {
      final response = await _client.put(uri, headers: headers, body: bodyBytes);
      _logResponse('PUT', uri, headers ?? const {}, '[bytes:${bodyBytes.length}]', response);

      if (response.statusCode >= 400) {
        _logHttpError('PUT', uri, response);
      }

      return response;
    } catch (error, stackTrace) {
      _logException('PUT', uri, error, stackTrace);
      rethrow;
    }
  }

  Uri _buildUri(String path) {
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$baseUrl$normalizedPath');
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
    final sanitizedHeaders = Map<String, String>.from(headers);
    if (sanitizedHeaders.containsKey('Authorization')) {
      sanitizedHeaders['Authorization'] = 'Bearer ***';
    }

    print('''\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      $method ${url.toString()}
      Headers: $sanitizedHeaders
      Request Body: $requestBody
    
      Response Code: ${response.statusCode}
      Response Body: ${response.body}
      ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      ''');
  }

  void _logHttpError(String method, Uri url, http.Response response) {
    print('''\n❌ API ERROR
      $method ${url.toString()}
      Status Code: ${response.statusCode}
      Error Body: ${response.body}
      ''');
  }

  void _logException(String method, Uri url, Object error, StackTrace stackTrace) {
    print('''\n❌ API EXCEPTION
      $method ${url.toString()}
      Error: $error
      StackTrace: $stackTrace
      ''');
  }
}
