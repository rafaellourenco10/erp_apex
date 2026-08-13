import 'produto.dart';

/// A line item in the cart being built during the "Novo Pedido" flow.
class ItemPedido {
  final Produto produto;
  int quantidade;

  ItemPedido({required this.produto, this.quantidade = 0});

  double get subtotal => produto.preco * quantidade;

  Map<String, dynamic> toJson(int idPedido) {
    return {
      'id_pedido': idPedido,
      'id_produto': produto.idProduto,
      'quantidade': quantidade,
      'preco_unitario': produto.preco,
    };
  }
}
