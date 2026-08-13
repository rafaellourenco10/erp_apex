import '../core/constants/api_constants.dart';
import '../models/produto.dart';
import 'api_service.dart';

class ProdutoService {
  final ApiService _api;

  ProdutoService(this._api);

  Future<List<Produto>> getProdutos() async {
    final data = await _api.get(ApiConstants.produtos);
    final items = (data['items'] as List<dynamic>? ?? []);
    return items
        .map((e) => Produto.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
