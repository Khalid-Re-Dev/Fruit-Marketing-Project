import 'package:dio/dio.dart';
import 'package:logging/logging.dart';

class ApiService {
  final Logger _logger = Logger('ApiService');
  final Dio _dio = Dio();
  final String _baseUrl =
      'https://api.example.com'; // Replace with your API URL

  ApiService() {
    _dio.options.baseUrl = _baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 5);
    _dio.options.receiveTimeout = const Duration(seconds: 3);

    // Add interceptors for logging, authentication, etc.
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        // Add auth token if available
        // options.headers['Authorization'] = 'Bearer $token';
        return handler.next(options);
      },
      onResponse: (response, handler) {
        return handler.next(response);
      },
      onError: (DioException e, handler) {
        // Handle errors globally
        _logger.warning('API Error: ${e.message}');
        return handler.next(e);
      },
    ));
  }

  // Generic GET request
  Future<dynamic> get(String path,
      {Map<String, dynamic>? queryParameters}) async {
    try {
      final response = await _dio.get(
        path,
        queryParameters: queryParameters,
      );
      return response.data;
    } catch (e) {
      _logger.warning('GET request error: $e');
      rethrow;
    }
  }

  // Generic POST request
  Future<dynamic> post(String path, {dynamic data}) async {
    try {
      final response = await _dio.post(
        path,
        data: data,
      );
      return response.data;
    } catch (e) {
      _logger.warning('POST request error: $e');
      rethrow;
    }
  }

  // Generic PUT request
  Future<dynamic> put(String path, {dynamic data}) async {
    try {
      final response = await _dio.put(
        path,
        data: data,
      );
      return response.data;
    } catch (e) {
      _logger.warning('PUT request error: $e');
      rethrow;
    }
  }

  // Generic DELETE request
  Future<dynamic> delete(String path) async {
    try {
      final response = await _dio.delete(path);
      return response.data;
    } catch (e) {
      _logger.warning('DELETE request error: $e');
      rethrow;
    }
  }
}
