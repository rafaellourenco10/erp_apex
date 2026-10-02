import 'package:flutter_test/flutter_test.dart';

import 'package:erp_apex/models/caminhao.dart';
import 'package:erp_apex/models/pedido.dart';
import 'package:erp_apex/screens/dashboard/dashboard_resumo.dart';

Pedido _pedido(int id, DateTime data, PedidoStatus status, double valor) =>
    Pedido(
      idPedido: id,
      idCliente: 1,
      clienteNome: 'C',
      data: data,
      status: status,
      valorTotal: valor,
    );

void main() {
  test('DashboardResumo agrega pedidos e frota ignorando cancelados', () {
    final hoje = DateTime(2026, 10, 2);
    final r = DashboardResumo.from(
      [
        _pedido(1, DateTime(2026, 10, 1), PedidoStatus.pendente, 100),
        _pedido(2, DateTime(2026, 9, 15), PedidoStatus.entregue, 300),
        _pedido(3, DateTime(2026, 9, 20), PedidoStatus.cancelado, 999),
        _pedido(
          4,
          DateTime(2025, 1, 1),
          PedidoStatus.faturado,
          50,
        ), // fora da janela
      ],
      const [
        Caminhao(idCaminhao: 1, placa: 'A', status: CaminhaoStatus.livre),
        Caminhao(idCaminhao: 2, placa: 'B', status: CaminhaoStatus.emRota),
      ],
      hoje: hoje,
    );

    expect(r.faturamento, 450);
    expect(r.pedidosAtivos, 3);
    expect(r.ticketMedio, 150);
    expect(r.pendentes, 1);
    expect(r.valorEmAberto, 100);
    expect(r.porStatus[PedidoStatus.cancelado], 1);
    expect(r.vendasPorMes.length, 6);
    expect(r.vendasPorMes.first.mes, DateTime(2026, 5));
    expect(r.vendasPorMes.last.valor, 100);
    expect(r.vendasPorMes[4].valor, 300);
    expect(r.frota[CaminhaoStatus.livre], 1);
    expect(r.recentes.first.idPedido, 1);
  });
}
