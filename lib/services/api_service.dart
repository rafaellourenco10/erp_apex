import 'package:dio/dio.dart';

import '../core/constants/api_constants.dart';
import 'api_exception.dart';

/// Thin wrapper around Dio, centralizing base URL, headers and error mapping
/// for the Oracle APEX ORDS backend.
class ApiService {
  final Dio _dio;

  ApiService()
      : _dio = Dio(
          BaseOptions(
            baseUrl: ApiConstants.baseUrl,
            headers: {'Content-Type': 'application/json'},
            connectTimeout: const Duration(seconds: 15),
            receiveTimeout: const Duration(seconds: 15),
          ),
        );

  Future<Map<String, dynamic>> get(String path,
      {Map<String, dynamic>? queryParameters}) async {
    try {
      final response =
          await _dio.get(path, queryParameters: queryParameters);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Future<Map<String, dynamic>> post(
      String path, Map<String, dynamic> body) async {
    try {
      final response = await _dio.post(path, data: body);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  ApiException _mapError(DioException e) {
    final data = e.response?.data;
    final bodyText = _extractMessage(data) ?? e.message ?? '';

    if (bodyText.contains('ORA-20001')) {
      final mensagem = _extractOraMessage(bodyText, 'ORA-20001');
      return ApiException(
        mensagem ?? 'Estoque insuficiente para este produto.',
        estoqueInsuficiente: true,
      );
    }

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const ApiException(
            'Tempo de conexão esgotado. Verifique sua internet e tente novamente.');
      case DioExceptionType.connectionError:
        return const ApiException(
            'Não foi possível conectar ao servidor. Verifique sua internet.');
      default:
        return ApiException(
          bodyText.isNotEmpty
              ? bodyText
              : 'Ocorreu um erro inesperado. Tente novamente.',
        );
    }
  }

  /// Extracts the text after `ORA-<code>:` from a raw Oracle error body,
  /// e.g. `'ORA-20001: Estoque insuficiente para o produto "X".'` becomes
  /// `'Estoque insuficiente para o produto "X".'`. Returns null if the
  /// message has no readable text after the code (e.g. stack trace only).
  String? _extractOraMessage(String bodyText, String oraCode) {
    final match = RegExp('$oraCode:\\s*(.+)').firstMatch(bodyText);
    final texto = match?.group(1)?.split('\n').first.trim();
    return (texto != null && texto.isNotEmpty) ? texto : null;
  }

  String? _extractMessage(dynamic data) {
    if (data == null) return null;
    if (data is String) return data;
    if (data is Map) {
      final candidate = data['message'] ?? data['error'] ?? data['detail'];
      if (candidate != null) return candidate.toString();
      return data.toString();
    }
    return data.toString();
  }
}
