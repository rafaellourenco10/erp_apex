import 'package:flutter/foundation.dart';

import '../models/cliente.dart';
import '../services/api_exception.dart';
import '../services/cliente_service.dart';

class ClienteProvider extends ChangeNotifier {
  final ClienteService _service;

  ClienteProvider(this._service);

  List<Cliente> _clientes = [];
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';

  bool get isLoading => _isLoading;
  String? get error => _error;

  List<Cliente> get clientes {
    if (_searchQuery.isEmpty) return _clientes;
    final query = _searchQuery.toLowerCase();
    return _clientes
        .where((c) => c.nome.toLowerCase().contains(query))
        .toList();
  }

  Future<void> carregar() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _clientes = await _service.getClientes();
    } on ApiException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'Não foi possível carregar os clientes.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void search(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  /// Looks up a client by id across the full (unfiltered) list — used by
  /// "repetir pedido" to find the client regardless of an active search.
  Cliente? buscarPorId(int idCliente) {
    for (final cliente in _clientes) {
      if (cliente.idCliente == idCliente) return cliente;
    }
    return null;
  }
}
