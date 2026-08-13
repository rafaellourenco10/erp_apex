import 'package:flutter/foundation.dart';

import '../models/pedido.dart';
import '../services/api_exception.dart';
import '../services/pedido_service.dart';

/// Drives the "Meus Pedidos" screen — order history fetched from
/// GET /pedidos.
class HistoricoPedidosProvider extends ChangeNotifier {
  final PedidoService _service;

  HistoricoPedidosProvider(this._service);

  List<Pedido> _pedidos = [];
  bool _isLoading = false;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<Pedido> get pedidos => _pedidos;

  Future<void> carregar() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _pedidos = await _service.getPedidos();
      _pedidos.sort((a, b) => b.idPedido.compareTo(a.idPedido));
    } on ApiException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'Não foi possível carregar os pedidos.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
