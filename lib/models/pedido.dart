enum PedidoStatus { pendente, aprovado, faturado, entregue, cancelado }

extension PedidoStatusLabel on PedidoStatus {
  String get label {
    switch (this) {
      case PedidoStatus.pendente:
        return 'Pendente';
      case PedidoStatus.aprovado:
        return 'Aprovado';
      case PedidoStatus.faturado:
        return 'Faturado';
      case PedidoStatus.entregue:
        return 'Entregue';
      case PedidoStatus.cancelado:
        return 'Cancelado';
    }
  }
}

/// Parses the `status` column (e.g. "PENDENTE", "APROVADO") returned by
/// GET /pedidos, defaulting to [PedidoStatus.pendente] for unknown values.
PedidoStatus pedidoStatusFromString(String? raw) {
  switch (raw?.trim().toUpperCase()) {
    case 'APROVADO':
      return PedidoStatus.aprovado;
    case 'FATURADO':
      return PedidoStatus.faturado;
    case 'ENTREGUE':
      return PedidoStatus.entregue;
    case 'CANCELADO':
      return PedidoStatus.cancelado;
    case 'PENDENTE':
    default:
      return PedidoStatus.pendente;
  }
}

class PedidoItemResumo {
  final String nome;
  final int quantidade;
  final double precoUnitario;

  const PedidoItemResumo({
    required this.nome,
    required this.quantidade,
    required this.precoUnitario,
  });

  double get subtotal => quantidade * precoUnitario;

  factory PedidoItemResumo.fromJson(Map<String, dynamic> json) {
    return PedidoItemResumo(
      nome: json['nome_produto'] as String,
      quantidade: json['quantidade'] as int,
      precoUnitario: (json['preco_unitario'] as num).toDouble(),
    );
  }
}

/// An order, as returned by GET /pedidos (header) and, on demand,
/// GET /itens_pedido?id_pedido=X (line items) for the detail screen.
class Pedido {
  final int idPedido;
  final String clienteNome;
  final DateTime data;
  final PedidoStatus status;
  final double valorTotal;
  final List<PedidoItemResumo> itens;

  const Pedido({
    required this.idPedido,
    required this.clienteNome,
    required this.data,
    required this.status,
    required this.valorTotal,
    this.itens = const [],
  });

  factory Pedido.fromJson(Map<String, dynamic> json) {
    return Pedido(
      idPedido: json['id_pedido'] as int,
      clienteNome: json['cliente_nome'] as String? ?? 'Cliente #${json['id_cliente']}',
      data: DateTime.parse(json['data_pedido'] as String),
      status: pedidoStatusFromString(json['status'] as String?),
      valorTotal: (json['valor_total'] as num).toDouble(),
    );
  }

  Pedido copyWith({List<PedidoItemResumo>? itens, PedidoStatus? status}) {
    return Pedido(
      idPedido: idPedido,
      clienteNome: clienteNome,
      data: data,
      status: status ?? this.status,
      valorTotal: valorTotal,
      itens: itens ?? this.itens,
    );
  }
}
