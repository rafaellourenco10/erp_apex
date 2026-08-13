import 'package:flutter/foundation.dart';

import '../models/produto.dart';
import '../services/api_exception.dart';
import '../services/produto_service.dart';

class ProdutoProvider extends ChangeNotifier {
  final ProdutoService _service;

  ProdutoProvider(this._service);

  List<Produto> _produtos = [];
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';

  bool get isLoading => _isLoading;
  String? get error => _error;

  List<Produto> get produtos {
    if (_searchQuery.isEmpty) return _produtos;
    final query = _searchQuery.toLowerCase();
    return _produtos
        .where((p) => p.nome.toLowerCase().contains(query))
        .toList();
  }

  Future<void> carregar() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _produtos = await _service.getProdutos();
    } on ApiException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'Não foi possível carregar os produtos.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void search(String query) {
    _searchQuery = query;
    notifyListeners();
  }
}
