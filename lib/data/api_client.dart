import 'dart:typed_data';

import 'package:dio/dio.dart';

/// An error from the OHS backend, with the server's own message where it gave one.
class ApiException implements Exception {
  ApiException(this.message, {this.status, this.code});

  final String message;
  final int? status;
  final String? code;

  bool get isUnauthorized => status == 401;
  bool get isForbidden => status == 403;
  bool get isOffline => status == null;

  @override
  String toString() => message;
}

typedef TokenReader = Future<String?> Function();
typedef UnauthorizedHandler = void Function(String message);

/// HTTP access to the backend. Pure Dart (no Flutter imports) so it can also be exercised from command-line tools.
///
/// * Adds the bearer token to every request.
/// * Turns error responses into [ApiException] with the server's message.
/// * A 401 on an authenticated request means the session ended (signed out elsewhere, idle, expired):
///   [onUnauthorized] is told so the app can return to the sign-in screen with that reason.
/// * Requests marked `background` (polling) carry `X-Background: 1` so they don't keep an idle session alive.
class ApiClient {
  ApiClient({required String baseUrl, required this.readToken, this.onUnauthorized})
      : _dio = Dio(BaseOptions(
          baseUrl: _normalise(baseUrl),
          connectTimeout: const Duration(seconds: 12),
          receiveTimeout: const Duration(seconds: 30),
          headers: {'Accept': 'application/json'},
        ));

  final Dio _dio;
  final TokenReader readToken;
  UnauthorizedHandler? onUnauthorized;

  /// Platform super-admin support mode: requests act inside this agency (sent as X-Tenant-Id; the server checks the role).
  String? actingTenant;

  String get baseUrl => _dio.options.baseUrl;
  set baseUrl(String value) => _dio.options.baseUrl = _normalise(value);

  /// `http://host:8080` or `http://host:8080/api` → `http://host:8080/api/`
  static String _normalise(String url) {
    var u = url.trim();
    while (u.endsWith('/')) {
      u = u.substring(0, u.length - 1);
    }
    if (!u.endsWith('/api')) u = '$u/api';
    return '$u/';
  }

  Future<dynamic> get(String path, {Map<String, dynamic>? query, bool background = false, bool auth = true}) =>
      _send('GET', path, query: query, background: background, auth: auth);

  Future<dynamic> post(String path, [Object? body, bool auth = true]) => _send('POST', path, body: body, auth: auth);

  Future<dynamic> patch(String path, [Object? body]) => _send('PATCH', path, body: body);

  Future<dynamic> delete(String path) => _send('DELETE', path);

  /// Downloads a file (attachments) as bytes, with the bearer token.
  Future<Uint8List> getBytes(String path) async {
    final token = await readToken();
    try {
      final res = await _dio.get<List<int>>(path.startsWith('/') ? path.substring(1) : path,
          options: Options(responseType: ResponseType.bytes, headers: {
            if (token != null) 'Authorization': 'Bearer $token',
            if (actingTenant != null) 'X-Tenant-Id': actingTenant,
          }));
      return Uint8List.fromList(res.data ?? const []);
    } on DioException catch (e) {
      final error = _toApiException(e);
      if (error.isUnauthorized && token != null) onUnauthorized?.call(error.message);
      throw error;
    }
  }

  /// Multipart upload (evidence photos, documents). Uses bytes so it works on every platform.
  Future<dynamic> upload(String path, {required Uint8List bytes, required String filename, Map<String, String> fields = const {}}) {
    final form = FormData.fromMap({...fields, 'file': MultipartFile.fromBytes(bytes, filename: filename)});
    return _send('POST', path, body: form);
  }

  Future<dynamic> _send(String method, String path,
      {Object? body, Map<String, dynamic>? query, bool background = false, bool auth = true}) async {
    final headers = <String, dynamic>{};
    if (auth) {
      final token = await readToken();
      if (token != null && token.isNotEmpty) headers['Authorization'] = 'Bearer $token';
    }
    if (background) headers['X-Background'] = '1';
    if (auth && actingTenant != null) headers['X-Tenant-Id'] = actingTenant;
    final clean = path.startsWith('/') ? path.substring(1) : path;
    try {
      final res = await _dio.request<dynamic>(clean,
          data: body, queryParameters: query, options: Options(method: method, headers: headers));
      return res.data;
    } on DioException catch (e) {
      final error = _toApiException(e);
      if (error.isUnauthorized && auth && headers.containsKey('Authorization')) {
        onUnauthorized?.call(error.message);
      }
      throw error;
    }
  }

  ApiException _toApiException(DioException e) {
    final res = e.response;
    if (res == null) {
      final reason = switch (e.type) {
        DioExceptionType.connectionTimeout || DioExceptionType.receiveTimeout || DioExceptionType.sendTimeout =>
          'The server took too long to respond.',
        _ => 'Cannot reach the server.',
      };
      return ApiException('$reason Check your connection and the server address (${_dio.options.baseUrl}).');
    }
    final data = res.data;
    String? message;
    String? code;
    if (data is Map) {
      message = (data['message'] ?? data['error'])?.toString();
      code = data['code']?.toString();
      final errors = data['errors'];
      if (errors is Map && errors.isNotEmpty) message = errors.values.join('\n');
    } else if (data is String && data.isNotEmpty && data.length < 300 && !data.trimLeft().startsWith('<')) {
      message = data;
    }
    message ??= switch (res.statusCode) {
      401 => 'Please sign in again.',
      403 => 'You do not have permission to do that.',
      404 => 'Not found.',
      423 => 'This account is temporarily locked.',
      429 => 'Too many attempts. Please wait and try again.',
      _ => 'The server could not complete the request (${res.statusCode}).',
    };
    return ApiException(message, status: res.statusCode, code: code);
  }
}
