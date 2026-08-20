import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../core/utils/formatters.dart';
import '../models/pedido.dart';

/// Builds PDF reports (order summary or period digest) as bytes, ready to
/// hand off to `Printing.sharePdf` — that opens the OS share sheet, where
/// WhatsApp shows up as one of the destinations if installed.
class PdfReportService {
  PdfReportService._();

  static Future<Uint8List> gerarPedido(Pedido pedido) async {
    final doc = pw.Document();

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _header('Comprovante de Pedido #${pedido.idPedido}'),
            pw.SizedBox(height: 16),
            _linhaInfo('Cliente', pedido.clienteNome),
            _linhaInfo('Data', Formatters.date(pedido.data)),
            _linhaInfo('Status', pedido.status.label),
            pw.SizedBox(height: 20),
            _tabelaItens(pedido.itens),
            pw.SizedBox(height: 12),
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text(
                'Total: ${Formatters.currency(pedido.valorTotal)}',
                style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
              ),
            ),
            pw.Spacer(),
            _rodape(),
          ],
        ),
      ),
    );

    return doc.save();
  }

  static Future<Uint8List> gerarPeriodo({
    required List<Pedido> pedidos,
    required DateTime inicio,
    required DateTime fim,
  }) async {
    final doc = pw.Document();
    final valorTotal = pedidos.fold<double>(0, (sum, p) => sum + p.valorTotal);

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => context.pageNumber == 1
            ? pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  _header('Relatório de Vendas'),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    '${Formatters.date(inicio)} a ${Formatters.date(fim)}',
                    style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700),
                  ),
                  pw.SizedBox(height: 16),
                ],
              )
            : pw.SizedBox(),
        build: (context) => [
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
            columnWidths: const {
              0: pw.FlexColumnWidth(1.2),
              1: pw.FlexColumnWidth(2.6),
              2: pw.FlexColumnWidth(1.4),
              3: pw.FlexColumnWidth(1.6),
              4: pw.FlexColumnWidth(1.6),
            },
            children: [
              _linhaCabecalho(['Pedido', 'Cliente', 'Data', 'Status', 'Total']),
              for (final pedido in pedidos)
                _linhaTabela([
                  '#${pedido.idPedido}',
                  pedido.clienteNome,
                  Formatters.date(pedido.data),
                  pedido.status.label,
                  Formatters.currency(pedido.valorTotal),
                ]),
            ],
          ),
          pw.SizedBox(height: 16),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('${pedidos.length} pedido(s) no período',
                  style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700)),
              pw.Text(
                'Total: ${Formatters.currency(valorTotal)}',
                style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
              ),
            ],
          ),
        ],
        footer: (context) => _rodape(),
      ),
    );

    return doc.save();
  }

  static pw.Widget _header(String titulo) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('ERP Simples', style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700)),
          pw.SizedBox(height: 4),
          pw.Text(titulo, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
          pw.Divider(color: PdfColors.grey400),
        ],
      );

  static pw.Widget _linhaInfo(String label, String valor) => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 2),
        child: pw.Row(
          children: [
            pw.SizedBox(
              width: 70,
              child: pw.Text('$label:', style: const pw.TextStyle(color: PdfColors.grey700)),
            ),
            pw.Text(valor, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          ],
        ),
      );

  static pw.Widget _tabelaItens(List<PedidoItemResumo> itens) {
    if (itens.isEmpty) {
      return pw.Text('Nenhum item encontrado.',
          style: const pw.TextStyle(color: PdfColors.grey700));
    }
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
      columnWidths: const {
        0: pw.FlexColumnWidth(3),
        1: pw.FlexColumnWidth(1),
        2: pw.FlexColumnWidth(1.4),
        3: pw.FlexColumnWidth(1.4),
      },
      children: [
        _linhaCabecalho(['Produto', 'Qtd', 'Preço Unit.', 'Subtotal']),
        for (final item in itens)
          _linhaTabela([
            item.nome,
            '${item.quantidade}',
            Formatters.currency(item.precoUnitario),
            Formatters.currency(item.subtotal),
          ]),
      ],
    );
  }

  static pw.TableRow _linhaCabecalho(List<String> colunas) => pw.TableRow(
        decoration: const pw.BoxDecoration(color: PdfColors.grey200),
        children: [
          for (final texto in colunas)
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
              child: pw.Text(texto, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
            ),
        ],
      );

  static pw.TableRow _linhaTabela(List<String> colunas) => pw.TableRow(
        children: [
          for (final texto in colunas)
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
              child: pw.Text(texto, style: const pw.TextStyle(fontSize: 10)),
            ),
        ],
      );

  static pw.Widget _rodape() => pw.Padding(
        padding: const pw.EdgeInsets.only(top: 12),
        child: pw.Text(
          'Emitido em ${Formatters.date(DateTime.now())}',
          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
        ),
      );
}
