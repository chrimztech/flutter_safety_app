import 'package:dio/dio.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  late final Dio dio;

  ApiService._internal() {
    dio = Dio(
      BaseOptions(
        baseUrl: 'https://yourapi.com/api/',
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ),
    );

    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        // Add auth token if needed, e.g.
        // options.headers['Authorization'] = 'Bearer your_token';
        return handler.next(options);
      },
      onResponse: (response, handler) {
        // Log or manipulate response if needed
        return handler.next(response);
      },
      onError: (DioError e, handler) {
        // Handle errors globally
        // e.g. if (e.response?.statusCode == 401) logout();
        return handler.next(e);
      },
    ));
  }

  Future<Response> get(String path) async {
    try {
      return await dio.get(path);
    } on DioError {
      // Handle Dio errors here
      rethrow;
    }
  }

  Future<Response> post(String path, dynamic data) async {
    try {
      return await dio.post(path, data: data);
    } on DioError {
      rethrow;
    }
  }
}
