import 'package:dio/dio.dart';
import '../constants/api_endpoints.dart';
import '../services/storage_service.dart';

class ApiClient {
  late final Dio _dio;

  ApiClient(StorageService storage) {
    _dio = Dio(BaseOptions(
      baseUrl: ApiEndpoints.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await storage.getToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (err, handler) async {
        if (err.response?.statusCode == 401) {
          await storage.deleteToken();
        }
        handler.next(err);
      },
    ));
  }

  Future<Response<Map<String, dynamic>>> get(
    String path, {
    Map<String, dynamic>? params,
  }) =>
      _dio.get(path, queryParameters: params);

  Future<Response<dynamic>> post(
    String path, {
    dynamic data,
  }) =>
      _dio.post(path, data: data);

  Future<Response<Map<String, dynamic>>> put(
    String path, {
    dynamic data,
  }) =>
      _dio.put(path, data: data);

  Future<Response<Map<String, dynamic>>> delete(String path) =>
      _dio.delete(path);

  Future<Response<dynamic>> postMultipart(
    String path, {
    required FormData formData,
  }) =>
      _dio.post(path, data: formData);
}
