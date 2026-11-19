import 'package:flutter_test/flutter_test.dart';

import 'package:erp_apex/models/pedido.dart';
import 'package:erp_apex/services/resumo_periodo.dart';

Pedido _p(
  int id,
  String cliente,
  DateTime data,
  PedidoStatus status,
  double valor,
) => Pedido(
  idPedido: id,
  idCliente: id,
  clienteNome: cliente,
  data: data,
  status: status,
  valorTotal: valor,
);

void main() {
  test(
    'ResumoPeriodo separa cancelados, agrupa por dia e ranqueia clientes',
    () {
      final r = ResumoPeriodo.from(
        [
          _p(1, 'Ana', DateTime(2026, 9, 1, 10), PedidoStatus.entregue, 100),
          _p(2, 'Ana', DateTime(2026, 9, 3), PedidoStatus.pendente, 50),
          _p(3, 'Bruno', DateTime(2026, 9, 3), PedidoStatus.faturado, 200),
          _p(4, 'Bruno', DateTime(2026, 9, 2), PedidoStatus.cancelado, 999),
        ],
        inicio: DateTime(2026, 9, 1),
        fim: DateTime(2026, 9, 3),
      );

      expect(r.faturamento, 350);
      expect(r.pedidosValidos, 3);
      expect(r.ticketMedio, closeTo(116.67, 0.01));
      expect(r.cancelados, 1);
      expect(r.valorCancelado, 999);
      expect(r.seriePorMes, isFalse);
      expect(r.serie.map((e) => e.valor), [100, 0, 250]);
      expect(r.topClientes.first.nome, 'Bruno');
      expect(r.topClientes.first.valor, 200);
      expect(r.porStatus[PedidoStatus.cancelado]!.qtd, 1);
    },
  );

  test('ResumoPeriodo agrupa por mês em períodos longos', () {
    final r = ResumoPeriodo.from(
      const [],
      inicio: DateTime(2026, 1, 15),
      fim: DateTime(2026, 4, 2),
    );
    expect(r.seriePorMes, isTrue);
    expect(r.serie.length, 4);
  });
}
