import '../core/constants/api_constants.dart';
import '../models/item_pedido.dart';
import '../models/pedido.dart';
import 'api_service.dart';

class PedidoService {
  final ApiService _api;

  PedidoService(this._api);

  /// Creates the order header and all its items in a single atomic request
  /// (`POST /pedidos_completo`). The backend wraps the insert in one
  /// transaction, so a failure on any item (e.g. insufficient stock) rolls
  /// back the whole order instead of leaving a partial one behind.
  /// Returns the generated `id_pedido`.
  Future<int> criarPedidoCompleto({
    required int idCliente,
    required List<ItemPedido> itens,
  }) async {
    final data = await _api.post(ApiConstants.pedidosCompleto, {
      'id_cliente': idCliente,
      'itens': itens.map((item) => item.toJson()).toList(),
    });
    return data['id_pedido_gerado'] as int;
  }

  /// Fetches the order history (most recent first).
  Future<List<Pedido>> getPedidos() async {
    final data = await _api.get(ApiConstants.pedidos);
    final items = (data['items'] as List<dynamic>? ?? []);
    return items
        .map((e) => Pedido.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Fetches the line items of a single order, for the detail screen.
  Future<List<PedidoItemResumo>> getItensPedido(int idPedido) async {
    final data = await _api.get(
      ApiConstants.itensPedido,
      queryParameters: {'id_pedido': idPedido},
    );
    final items = (data['items'] as List<dynamic>? ?? []);
    return items
        .map((e) => PedidoItemResumo.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
