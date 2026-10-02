import '../../models/caminhao.dart';
import '../../models/pedido.dart';

/// Pure aggregations behind the dashboard, computed from the orders and
/// trucks the providers already load — kept out of the widgets so they can
/// be unit tested.
class DashboardResumo {
  final double faturamento;
  final int pedidosAtivos;
  final double ticketMedio;
  final int pendentes;
  final double valorEmAberto;
  final Map<PedidoStatus, int> porStatus;

  /// Revenue per month (oldest first) for the last [meses] months,
  /// including the current one. Cancelled orders don't count.
  final List<({DateTime mes, double valor})> vendasPorMes;
  final Map<CaminhaoStatus, int> frota;
  final List<Pedido> recentes;

  const DashboardResumo._({
    required this.faturamento,
    required this.pedidosAtivos,
    required this.ticketMedio,
    required this.pendentes,
    required this.valorEmAberto,
    required this.porStatus,
    required this.vendasPorMes,
    required this.frota,
    required this.recentes,
  });

  factory DashboardResumo.from(
    List<Pedido> pedidos,
    List<Caminhao> caminhoes, {
    DateTime? hoje,
    int meses = 6,
  }) {
    final agora = hoje ?? DateTime.now();
    final ativos = pedidos
        .where((p) => p.status != PedidoStatus.cancelado)
        .toList();
    final pendentes = pedidos
        .where((p) => p.status == PedidoStatus.pendente)
        .toList();
    final faturamento = ativos.fold<double>(0, (s, p) => s + p.valorTotal);

    final vendas = [
      for (var i = meses - 1; i >= 0; i--)
        (mes: DateTime(agora.year, agora.month - i), valor: 0.0),
    ];
    for (final p in ativos) {
      final i = vendas.indexWhere(
        (v) => v.mes.year == p.data.year && v.mes.month == p.data.month,
      );
      if (i != -1) {
        vendas[i] = (mes: vendas[i].mes, valor: vendas[i].valor + p.valorTotal);
      }
    }

    final recentes = [...pedidos]..sort((a, b) => b.data.compareTo(a.data));

    return DashboardResumo._(
      faturamento: faturamento,
      pedidosAtivos: ativos.length,
      ticketMedio: ativos.isEmpty ? 0 : faturamento / ativos.length,
      pendentes: pendentes.length,
      valorEmAberto: pendentes.fold<double>(0, (s, p) => s + p.valorTotal),
      porStatus: {
        for (final s in PedidoStatus.values)
          s: pedidos.where((p) => p.status == s).length,
      },
      vendasPorMes: vendas,
      frota: {
        for (final s in CaminhaoStatus.values)
          s: caminhoes.where((c) => c.status == s).length,
      },
      recentes: recentes.take(5).toList(),
    );
  }
}
