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
  String? _cancelError;

  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get cancelError => _cancelError;
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

  /// Cancels a pending order and reflects the new status locally (so both
  /// this list and the detail screen watching it update immediately,
  /// without a full reload). Returns true on success; on failure,
  /// [cancelError] explains why.
  Future<bool> cancelarPedido(int idPedido) async {
    _cancelError = null;
    try {
      await _service.cancelarPedido(idPedido);
      final index = _pedidos.indexWhere((p) => p.idPedido == idPedido);
      if (index != -1) {
        _pedidos[index] =
            _pedidos[index].copyWith(status: PedidoStatus.cancelado);
      }
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _cancelError = e.message;
      return false;
    } catch (_) {
      _cancelError = 'Não foi possível cancelar o pedido.';
      return false;
    }
  }
}
