import 'package:flutter/foundation.dart';

import '../models/cliente.dart';
import '../models/item_pedido.dart';
import '../models/produto.dart';
import '../services/api_exception.dart';
import '../services/pedido_service.dart';

/// Drives the 3-step "Novo Pedido" flow: client selection, cart building,
/// and final submission (POST /pedidos followed by POST /itens_pedido per item).
class PedidoProvider extends ChangeNotifier {
  final PedidoService _service;

  PedidoProvider(this._service);

  Cliente? _clienteSelecionado;
  final Map<int, ItemPedido> _carrinho = {};

  bool _isSubmitting = false;
  String? _submitError;
  int? _idPedidoCriado;

  Cliente? get clienteSelecionado => _clienteSelecionado;

  List<ItemPedido> get itens =>
      _carrinho.values.where((i) => i.quantidade > 0).toList();

  int get totalItensDistintos => itens.length;

  double get valorTotal =>
      itens.fold(0, (sum, item) => sum + item.subtotal);

  bool get podeAvancarParaProdutos => _clienteSelecionado != null;

  bool get podeConfirmar => itens.isNotEmpty;

  bool get isSubmitting => _isSubmitting;

  String? get submitError => _submitError;

  int? get idPedidoCriado => _idPedidoCriado;

  void selecionarCliente(Cliente cliente) {
    _clienteSelecionado = cliente;
    notifyListeners();
  }

  int quantidadeDe(Produto produto) =>
      _carrinho[produto.idProduto]?.quantidade ?? 0;

  void setQuantidade(Produto produto, int quantidade) {
    final qtd = quantidade < 0 ? 0 : quantidade;
    _carrinho[produto.idProduto] =
        ItemPedido(produto: produto, quantidade: qtd);
    notifyListeners();
  }

  void incrementar(Produto produto) {
    setQuantidade(produto, quantidadeDe(produto) + 1);
  }

  void decrementar(Produto produto) {
    setQuantidade(produto, quantidadeDe(produto) - 1);
  }

  /// Submits the order atomically via `POST /pedidos_completo`: the backend
  /// creates the header and all items in a single transaction, so a failure
  /// (e.g. ORA-20001 insufficient stock) leaves nothing partially saved.
  /// Returns true on success; on failure, [submitError] explains why.
  Future<bool> confirmarPedido() async {
    if (_clienteSelecionado == null || itens.isEmpty) return false;

    _isSubmitting = true;
    _submitError = null;
    notifyListeners();

    try {
      final idPedido = await _service.criarPedidoCompleto(
        idCliente: _clienteSelecionado!.idCliente,
        itens: itens,
      );
      _idPedidoCriado = idPedido;
      _isSubmitting = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _submitError = e.message;
      _isSubmitting = false;
      notifyListeners();
      return false;
    } catch (_) {
      _submitError = 'Ocorreu um erro inesperado ao criar o pedido.';
      _isSubmitting = false;
      notifyListeners();
      return false;
    }
  }

  /// Clears the flow so a new order can be started.
  void reset() {
    _clienteSelecionado = null;
    _carrinho.clear();
    _isSubmitting = false;
    _submitError = null;
    _idPedidoCriado = null;
    notifyListeners();
  }
}
