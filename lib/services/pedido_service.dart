import '../core/constants/api_constants.dart';
import '../models/item_pedido.dart';
import '../models/pedido.dart';
import 'api_service.dart';

class PedidoService {
  final ApiService _api;

  PedidoService(this._api);

  /// Creates the order header and returns the generated `id_pedido`.
  Future<int> criarPedido({required int idCliente}) async {
    final data = await _api.post(ApiConstants.pedidos, {
      'id_cliente': idCliente,
    });
    return data['id_pedido_gerado'] as int;
  }

  /// Inserts a single order item and returns the generated `id_item`.
  Future<int> adicionarItem(int idPedido, ItemPedido item) async {
    final data =
        await _api.post(ApiConstants.itensPedido, item.toJson(idPedido));
    return data['id_item_gerado'] as int;
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
