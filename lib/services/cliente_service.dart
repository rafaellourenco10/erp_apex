import '../core/constants/api_constants.dart';
import '../models/cliente.dart';
import 'api_service.dart';

class ClienteService {
  final ApiService _api;

  ClienteService(this._api);

  Future<List<Cliente>> getClientes() async {
    final data = await _api.get(ApiConstants.clientes);
    final items = (data['items'] as List<dynamic>? ?? []);
    return items
        .map((e) => Cliente.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
