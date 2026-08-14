import 'produto.dart';

/// A line item in the cart being built during the "Novo Pedido" flow.
class ItemPedido {
  final Produto produto;
  int quantidade;

  ItemPedido({required this.produto, this.quantidade = 0});

  double get subtotal => produto.preco * quantidade;

  /// Serializa como uma entrada do array `itens` de `POST /pedidos_completo`.
  /// `id_pedido` não entra aqui: é gerado pelo backend dentro da mesma
  /// transação que grava este item.
  Map<String, dynamic> toJson() {
    return {
      'id_produto': produto.idProduto,
      'quantidade': quantidade,
      'preco_unitario': produto.preco,
    };
  }
}
