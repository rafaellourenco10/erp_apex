import '../models/pedido.dart';

/// Aggregations for the period sales report PDF. Cancelled orders are
/// listed and counted separately, but never add to revenue.
class ResumoPeriodo {
  final double faturamento;
  final int pedidosValidos;
  final double ticketMedio;
  final int cancelados;
  final double valorCancelado;
  final Map<PedidoStatus, ({int qtd, double valor})> porStatus;

  /// Revenue per day (periods up to 31 days) or per month (longer ones),
  /// oldest first, with empty buckets included so the chart has no gaps.
  final List<({DateTime inicio, double valor})> serie;
  final bool seriePorMes;

  /// Top clients by revenue, highest first.
  final List<({String nome, int pedidos, double valor})> topClientes;

  const ResumoPeriodo._({
    required this.faturamento,
    required this.pedidosValidos,
    required this.ticketMedio,
    required this.cancelados,
    required this.valorCancelado,
    required this.porStatus,
    required this.serie,
    required this.seriePorMes,
    required this.topClientes,
  });

  factory ResumoPeriodo.from(
    List<Pedido> pedidos, {
    required DateTime inicio,
    required DateTime fim,
    int top = 5,
  }) {
    final validos = pedidos
        .where((p) => p.status != PedidoStatus.cancelado)
        .toList();
    final cancelados = pedidos
        .where((p) => p.status == PedidoStatus.cancelado)
        .toList();
    final faturamento = validos.fold<double>(0, (s, p) => s + p.valorTotal);

    final porMes = fim.difference(inicio).inDays > 31;
    DateTime bucket(DateTime d) =>
        porMes ? DateTime(d.year, d.month) : DateTime(d.year, d.month, d.day);
    final serie = <DateTime, double>{};
    for (
      var d = bucket(inicio);
      !d.isAfter(bucket(fim));
      d = porMes
          ? DateTime(d.year, d.month + 1)
          : DateTime(d.year, d.month, d.day + 1)
    ) {
      serie[d] = 0;
    }
    for (final p in validos) {
      final b = bucket(p.data);
      if (serie.containsKey(b)) serie[b] = serie[b]! + p.valorTotal;
    }

    final clientes = <String, ({int pedidos, double valor})>{};
    for (final p in validos) {
      final atual = clientes[p.clienteNome] ?? (pedidos: 0, valor: 0.0);
      clientes[p.clienteNome] = (
        pedidos: atual.pedidos + 1,
        valor: atual.valor + p.valorTotal,
      );
    }
    final ranking =
        clientes.entries
            .map(
              (e) =>
                  (nome: e.key, pedidos: e.value.pedidos, valor: e.value.valor),
            )
            .toList()
          ..sort((a, b) => b.valor.compareTo(a.valor));

    return ResumoPeriodo._(
      faturamento: faturamento,
      pedidosValidos: validos.length,
      ticketMedio: validos.isEmpty ? 0 : faturamento / validos.length,
      cancelados: cancelados.length,
      valorCancelado: cancelados.fold<double>(0, (s, p) => s + p.valorTotal),
      porStatus: {
        for (final s in PedidoStatus.values)
          s: (
            qtd: pedidos.where((p) => p.status == s).length,
            valor: pedidos
                .where((p) => p.status == s)
                .fold<double>(0, (soma, p) => soma + p.valorTotal),
          ),
      },
      serie: [for (final e in serie.entries) (inicio: e.key, valor: e.value)],
      seriePorMes: porMes,
      topClientes: ranking.take(top).toList(),
    );
  }
}
