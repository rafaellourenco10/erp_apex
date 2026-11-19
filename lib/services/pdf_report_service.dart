import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../core/utils/formatters.dart';
import '../models/cliente.dart';
import '../models/pedido.dart';
import 'pdf_layout.dart';
import 'resumo_periodo.dart';

/// Builds PDF reports (order receipt or period digest) as bytes, ready to
/// hand off to `Printing.sharePdf` — that opens the OS share sheet, where
/// WhatsApp shows up as one of the destinations if installed.
class PdfReportService {
  PdfReportService._();

  static const _l = PdfLayout.texto;

  /// Order receipt. [cliente] adds document/contact/address details when
  /// available; without it only the client name is shown.
  static Future<Uint8List> gerarPedido(
    Pedido pedido, {
    Cliente? cliente,
  }) async {
    final doc = pw.Document(
      title: 'Pedido #${pedido.idPedido}',
      author: 'ERP Simples',
    );
    final unidades = pedido.itens.fold<int>(0, (s, i) => s + i.quantidade);
    final subtotalItens = pedido.itens.fold<double>(
      0,
      (s, i) => s + i.subtotal,
    );

    final dadosCliente = <(String, String)>[
      ('Nome', pedido.clienteNome),
      if (_preenchido(cliente?.cpfCnpj)) ('CPF/CNPJ', cliente!.cpfCnpj!),
      if (_preenchido(cliente?.telefone))
        ('Telefone', Formatters.phone(cliente!.telefone)),
      if (_preenchido(cliente?.email)) ('E-mail', cliente!.email!),
      if (cliente?.enderecoCompleto != null)
        (
          'Endereço',
          [
            cliente!.enderecoCompleto!,
            if (_preenchido(cliente.complemento)) cliente.complemento!,
            if (_preenchido(cliente.cep)) 'CEP ${cliente.cep}',
          ].join(' · '),
        ),
    ];

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: PdfLayout.margem,
        header: (_) => PdfLayout.cabecalho(
          titulo: 'Comprovante de Pedido',
          subtitulo: 'Nº ${pedido.idPedido} · ${Formatters.date(pedido.data)}',
        ),
        footer: PdfLayout.rodape,
        build: (context) => [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                flex: 3,
                child: PdfLayout.caixaInfo('Cliente', dadosCliente),
              ),
              pw.SizedBox(width: 12),
              pw.Expanded(
                flex: 2,
                child: PdfLayout.caixaInfo('Pedido', [
                  ('Número', '#${pedido.idPedido}'),
                  ('Data', Formatters.date(pedido.data)),
                  ('Status', pedido.status.label),
                  ('Produtos', '${pedido.itens.length}'),
                  ('Unidades', '$unidades'),
                ]),
              ),
            ],
          ),
          PdfLayout.tituloSecao('Itens do pedido'),
          if (pedido.itens.isEmpty)
            pw.Text(
              'Nenhum item encontrado.',
              style: _l(color: PdfLayout.suave),
            )
          else
            PdfLayout.tabela(
              cabecalho: ['#', 'Produto', 'Qtd', 'Preço unit.', 'Subtotal'],
              larguras: const {
                0: pw.FixedColumnWidth(24),
                1: pw.FlexColumnWidth(4),
                2: pw.FlexColumnWidth(0.8),
                3: pw.FlexColumnWidth(1.4),
                4: pw.FlexColumnWidth(1.4),
              },
              direita: const {2, 3, 4},
              linhas: [
                for (var i = 0; i < pedido.itens.length; i++)
                  [
                    '${i + 1}',
                    pedido.itens[i].nome,
                    '${pedido.itens[i].quantidade}',
                    Formatters.currency(pedido.itens[i].precoUnitario),
                    Formatters.currency(pedido.itens[i].subtotal),
                  ],
              ],
            ),
          pw.SizedBox(height: 12),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pedido.status == PedidoStatus.cancelado
                    ? pw.Align(
                        alignment: pw.Alignment.topLeft,
                        child: PdfLayout.badge(
                          'PEDIDO CANCELADO',
                          pedido.status.color,
                        ),
                      )
                    : pw.SizedBox(),
              ),
              pw.SizedBox(
                width: 200,
                child: _totais(subtotalItens, pedido.valorTotal),
              ),
            ],
          ),
          pw.SizedBox(height: 48),
          pw.Row(
            children: [
              pw.Expanded(
                child: _linhaAssinatura('Recebido por (nome e assinatura)'),
              ),
              pw.SizedBox(width: 24),
              pw.SizedBox(
                width: 120,
                child: _linhaAssinatura('Data do recebimento'),
              ),
            ],
          ),
        ],
      ),
    );

    return doc.save();
  }

  static Future<Uint8List> gerarPeriodo({
    required List<Pedido> pedidos,
    required DateTime inicio,
    required DateTime fim,
    String? filtro,
  }) async {
    final doc = pw.Document(
      title: 'Relatório de Vendas',
      author: 'ERP Simples',
    );
    final r = ResumoPeriodo.from(pedidos, inicio: inicio, fim: fim);
    final ordenados = [...pedidos]..sort((a, b) => a.data.compareTo(b.data));
    final rotuloSerie = r.seriePorMes
        ? DateFormat('MMM', 'pt_BR')
        : DateFormat('dd');
    final dataPico = r.seriePorMes
        ? DateFormat('MMMM/yyyy', 'pt_BR')
        : DateFormat('dd/MM/yyyy');
    final pico = r.serie.isEmpty
        ? null
        : r.serie.reduce((a, b) => b.valor > a.valor ? b : a);

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: PdfLayout.margem,
        header: (_) => PdfLayout.cabecalho(
          titulo: 'Relatório de Vendas',
          subtitulo:
              '${Formatters.date(inicio)} a ${Formatters.date(fim)}'
              '${filtro != null ? ' · Status: $filtro' : ''}',
        ),
        footer: PdfLayout.rodape,
        build: (context) => [
          pw.Row(
            children: [
              pw.Expanded(
                child: PdfLayout.kpi(
                  'Faturamento',
                  Formatters.currency(r.faturamento),
                  detalhe: 'sem cancelados',
                  destaque: true,
                ),
              ),
              pw.SizedBox(width: 8),
              pw.Expanded(
                child: PdfLayout.kpi(
                  'Pedidos',
                  '${r.pedidosValidos}',
                  detalhe: '${pedidos.length} no total',
                ),
              ),
              pw.SizedBox(width: 8),
              pw.Expanded(
                child: PdfLayout.kpi(
                  'Ticket médio',
                  Formatters.currency(r.ticketMedio),
                  detalhe: 'por pedido',
                ),
              ),
              pw.SizedBox(width: 8),
              pw.Expanded(
                child: PdfLayout.kpi(
                  'Cancelados',
                  '${r.cancelados}',
                  detalhe: Formatters.currency(r.valorCancelado),
                ),
              ),
            ],
          ),
          PdfLayout.tituloSecao(
            r.seriePorMes ? 'Vendas por mês' : 'Vendas por dia',
          ),
          PdfLayout.graficoBarras(
            [
              for (final p in r.serie)
                (rotulo: rotuloSerie.format(p.inicio), valor: p.valor),
            ],
            legenda: pico == null || pico.valor == 0
                ? null
                : 'Pico: ${Formatters.currency(pico.valor)} em ${dataPico.format(pico.inicio)}',
          ),
          PdfLayout.tituloSecao('Pedidos por status'),
          PdfLayout.tabela(
            cabecalho: ['Status', 'Pedidos', 'Valor', '% dos pedidos'],
            larguras: const {
              0: pw.FlexColumnWidth(2),
              1: pw.FlexColumnWidth(1),
              2: pw.FlexColumnWidth(1.6),
              3: pw.FlexColumnWidth(2.4),
            },
            direita: const {1, 2},
            linhas: [
              for (final s in PedidoStatus.values)
                [
                  PdfLayout.badge(s.label, s.color),
                  '${r.porStatus[s]!.qtd}',
                  Formatters.currency(r.porStatus[s]!.valor),
                  _barraPercentual(
                    pedidos.isEmpty ? 0 : r.porStatus[s]!.qtd / pedidos.length,
                    PdfLayout.cor(s.color),
                  ),
                ],
            ],
          ),
          if (r.topClientes.isNotEmpty) ...[
            PdfLayout.tituloSecao('Principais clientes'),
            PdfLayout.tabela(
              cabecalho: ['#', 'Cliente', 'Pedidos', 'Valor', 'Participação'],
              larguras: const {
                0: pw.FixedColumnWidth(24),
                1: pw.FlexColumnWidth(3.4),
                2: pw.FlexColumnWidth(1),
                3: pw.FlexColumnWidth(1.6),
                4: pw.FlexColumnWidth(1.3),
              },
              direita: const {2, 3, 4},
              linhas: [
                for (var i = 0; i < r.topClientes.length; i++)
                  [
                    '${i + 1}',
                    r.topClientes[i].nome,
                    '${r.topClientes[i].pedidos}',
                    Formatters.currency(r.topClientes[i].valor),
                    r.faturamento == 0
                        ? '-'
                        : '${(r.topClientes[i].valor * 100 / r.faturamento).toStringAsFixed(1)}%',
                  ],
              ],
            ),
          ],
          PdfLayout.tituloSecao('Pedidos do período'),
          if (ordenados.isEmpty)
            pw.Text(
              'Nenhum pedido no período.',
              style: _l(color: PdfLayout.suave),
            )
          else
            PdfLayout.tabela(
              cabecalho: ['Pedido', 'Data', 'Cliente', 'Status', 'Total'],
              larguras: const {
                0: pw.FlexColumnWidth(0.9),
                1: pw.FlexColumnWidth(1.1),
                2: pw.FlexColumnWidth(3.2),
                3: pw.FlexColumnWidth(1.3),
                4: pw.FlexColumnWidth(1.4),
              },
              direita: const {4},
              linhas: [
                for (final p in ordenados)
                  [
                    '#${p.idPedido}',
                    Formatters.date(p.data),
                    p.clienteNome,
                    PdfLayout.badge(p.status.label, p.status.color),
                    p.status == PedidoStatus.cancelado
                        ? pw.Text(
                            Formatters.currency(p.valorTotal),
                            style: _l(size: 8.5, color: PdfLayout.suave)
                                .copyWith(
                                  decoration: pw.TextDecoration.lineThrough,
                                ),
                          )
                        : Formatters.currency(p.valorTotal),
                  ],
              ],
            ),
          pw.SizedBox(height: 10),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.SizedBox(
              width: 260,
              child: _totais(
                null,
                r.faturamento,
                rotuloTotal: 'Faturamento do período',
              ),
            ),
          ),
        ],
      ),
    );

    return doc.save();
  }

  static bool _preenchido(String? s) => s != null && s.trim().isNotEmpty;

  static pw.Widget _totais(
    double? subtotal,
    double total, {
    String rotuloTotal = 'Total',
  }) {
    return pw.Column(
      children: [
        if (subtotal != null)
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Subtotal dos itens',
                  style: _l(color: PdfLayout.suave),
                ),
                pw.Text(Formatters.currency(subtotal), style: _l()),
              ],
            ),
          ),
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: pw.BoxDecoration(
            color: PdfLayout.acentoClaro,
            borderRadius: pw.BorderRadius.circular(6),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(rotuloTotal, style: _l(bold: true)),
              pw.Text(
                Formatters.currency(total),
                style: _l(size: 12, bold: true, color: PdfLayout.acento),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _barraPercentual(double fracao, PdfColor cor) {
    final pct = (fracao * 100).round();
    pw.Widget trecho(int flex, PdfColor c) => pw.Expanded(
      flex: flex,
      child: pw.Container(height: 5, color: c),
    );
    return pw.Row(
      children: [
        pw.Expanded(
          child: pw.ClipRRect(
            horizontalRadius: 3,
            verticalRadius: 3,
            child: pw.Row(
              children: [
                if (pct > 0) trecho(pct, cor),
                if (pct < 100) trecho(100 - pct, PdfLayout.zebra),
              ],
            ),
          ),
        ),
        pw.SizedBox(width: 6),
        pw.SizedBox(
          width: 28,
          child: pw.Text(
            '$pct%',
            textAlign: pw.TextAlign.right,
            style: _l(size: 8),
          ),
        ),
      ],
    );
  }

  static pw.Widget _linhaAssinatura(String rotulo) => pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Container(height: 0.8, color: PdfLayout.suave),
      pw.SizedBox(height: 4),
      pw.Text(rotulo, style: _l(size: 7.5, color: PdfLayout.suave)),
    ],
  );
}
