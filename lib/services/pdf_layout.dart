import 'dart:ui' show Color;

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../core/constants/app_colors.dart';
import '../core/utils/formatters.dart';

/// Shared visual building blocks for the PDF reports. Colors come from the
/// app's [AppColors] tokens so the PDFs match the app's look.
class PdfLayout {
  PdfLayout._();

  static PdfColor cor(Color c) => PdfColor.fromInt(c.toARGB32());

  static final escuro = cor(AppColors.onTertiaryFixed);
  static final tinta = cor(AppColors.onSurface);
  static final suave = cor(AppColors.onSurfaceVariant);
  static final borda = cor(AppColors.surfaceContainerHigh);
  static final zebra = cor(AppColors.surfaceContainerLow);
  static final acento = cor(AppColors.primaryContainer);
  static final acentoClaro = cor(AppColors.primaryFixed);

  static const margem = pw.EdgeInsets.fromLTRB(36, 32, 36, 28);

  static pw.TextStyle texto({
    double size = 9.5,
    PdfColor? color,
    bool bold = false,
  }) => pw.TextStyle(
    fontSize: size,
    color: color ?? tinta,
    fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
  );

  /// Dark brand bar with the document title on the right and an accent
  /// stripe below, repeated on every page.
  static pw.Widget cabecalho({
    required String titulo,
    required String subtitulo,
  }) {
    return pw.Column(
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: pw.BoxDecoration(
            color: escuro,
            borderRadius: const pw.BorderRadius.vertical(
              top: pw.Radius.circular(6),
            ),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Row(
                children: [
                  pw.Container(
                    width: 26,
                    height: 26,
                    alignment: pw.Alignment.center,
                    decoration: pw.BoxDecoration(
                      color: acento,
                      borderRadius: pw.BorderRadius.circular(5),
                    ),
                    child: pw.Text(
                      'ES',
                      style: texto(
                        size: 10,
                        color: PdfColors.white,
                        bold: true,
                      ),
                    ),
                  ),
                  pw.SizedBox(width: 10),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'ERP Simples',
                        style: texto(
                          size: 13,
                          color: PdfColors.white,
                          bold: true,
                        ),
                      ),
                      pw.Text(
                        'Gestão de vendas e distribuição',
                        style: texto(size: 8, color: PdfColors.grey400),
                      ),
                    ],
                  ),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    titulo,
                    style: texto(size: 13, color: PdfColors.white, bold: true),
                  ),
                  pw.Text(
                    subtitulo,
                    style: texto(size: 8.5, color: PdfColors.grey400),
                  ),
                ],
              ),
            ],
          ),
        ),
        pw.Container(height: 3, color: acento),
        pw.SizedBox(height: 18),
      ],
    );
  }

  static pw.Widget rodape(pw.Context context) {
    final agora = DateTime.now();
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 14),
      padding: const pw.EdgeInsets.only(top: 6),
      decoration: pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: borda)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Emitido em ${Formatters.date(agora)} às ${DateFormat.Hm().format(agora)} · '
            'Documento sem valor fiscal',
            style: texto(size: 7.5, color: suave),
          ),
          pw.Text(
            'Página ${context.pageNumber} de ${context.pagesCount}',
            style: texto(size: 7.5, color: suave),
          ),
        ],
      ),
    );
  }

  static pw.Widget tituloSecao(String titulo) => pw.Padding(
    padding: const pw.EdgeInsets.only(top: 18, bottom: 8),
    child: pw.Row(
      children: [
        pw.Container(width: 3, height: 12, color: acento),
        pw.SizedBox(width: 6),
        pw.Text(
          titulo.toUpperCase(),
          style: texto(size: 9, bold: true).copyWith(letterSpacing: 0.8),
        ),
      ],
    ),
  );

  static pw.Widget kpi(
    String rotulo,
    String valor, {
    String? detalhe,
    bool destaque = false,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: destaque ? acentoClaro : PdfColors.white,
        border: pw.Border.all(color: destaque ? acentoClaro : borda),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            rotulo.toUpperCase(),
            style: texto(
              size: 7,
              color: suave,
              bold: true,
            ).copyWith(letterSpacing: 0.6),
          ),
          pw.SizedBox(height: 4),
          pw.FittedBox(
            child: pw.Text(
              valor,
              style: texto(
                size: 14,
                bold: true,
                color: destaque ? acento : tinta,
              ),
            ),
          ),
          if (detalhe != null) ...[
            pw.SizedBox(height: 2),
            pw.Text(detalhe, style: texto(size: 7.5, color: suave)),
          ],
        ],
      ),
    );
  }

  static pw.Widget badge(String rotulo, Color cor) {
    final c = PdfLayout.cor(cor);
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: pw.BoxDecoration(
        // PDF fills ignore alpha, so blend the 12% tint over white by hand.
        color: PdfColor(
          0.88 + 0.12 * c.red,
          0.88 + 0.12 * c.green,
          0.88 + 0.12 * c.blue,
        ),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Text(rotulo, style: texto(size: 7.5, color: c, bold: true)),
    );
  }

  /// Zebra-striped table with a dark header. Cells are either a [String] or
  /// a ready [pw.Widget]; columns listed in [direita] are right-aligned.
  static pw.Widget tabela({
    required List<String> cabecalho,
    required List<List<Object>> linhas,
    required Map<int, pw.TableColumnWidth> larguras,
    Set<int> direita = const {},
  }) {
    pw.Widget celula(Object conteudo, int col, {bool header = false}) =>
        pw.Container(
          alignment: direita.contains(col)
              ? pw.Alignment.centerRight
              : pw.Alignment.centerLeft,
          padding: const pw.EdgeInsets.symmetric(horizontal: 7, vertical: 6),
          child: conteudo is pw.Widget
              ? conteudo
              : pw.Text(
                  '$conteudo',
                  style: header
                      ? texto(size: 8, color: PdfColors.white, bold: true)
                      : texto(size: 8.5),
                ),
        );

    return pw.Table(
      columnWidths: larguras,
      border: pw.TableBorder(
        horizontalInside: pw.BorderSide(color: borda, width: 0.5),
      ),
      children: [
        pw.TableRow(
          repeat: true, // header repeats when the table breaks across pages
          decoration: pw.BoxDecoration(color: escuro),
          children: [
            for (var i = 0; i < cabecalho.length; i++)
              celula(cabecalho[i], i, header: true),
          ],
        ),
        for (var r = 0; r < linhas.length; r++)
          pw.TableRow(
            decoration: pw.BoxDecoration(
              color: r.isOdd ? zebra : PdfColors.white,
            ),
            children: [
              for (var i = 0; i < linhas[r].length; i++)
                celula(linhas[r][i], i),
            ],
          ),
      ],
    );
  }

  /// Simple vertical bar chart drawn with containers — the peak bar is
  /// highlighted, and x labels are thinned out to stay legible.
  static pw.Widget graficoBarras(
    List<({String rotulo, double valor})> dados, {
    String? legenda,
  }) {
    final max = dados.fold<double>(0, (m, d) => d.valor > m ? d.valor : m);
    if (max == 0) {
      return pw.Container(
        height: 60,
        alignment: pw.Alignment.center,
        child: pw.Text('Sem vendas no período.', style: texto(color: suave)),
      );
    }
    const altura = 100.0;
    final passo = (dados.length / 10).ceil();
    return pw.Container(
      padding: const pw.EdgeInsets.fromLTRB(10, 10, 10, 6),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: borda),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          if (legenda != null) ...[
            pw.Text(legenda, style: texto(size: 7.5, color: suave)),
            pw.SizedBox(height: 8),
          ],
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              for (var i = 0; i < dados.length; i++)
                pw.Expanded(
                  child: pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 1.5),
                    child: pw.Column(
                      mainAxisAlignment: pw.MainAxisAlignment.end,
                      children: [
                        pw.Container(
                          height: 2 + (altura - 2) * dados[i].valor / max,
                          decoration: pw.BoxDecoration(
                            color: dados[i].valor == max
                                ? acento
                                : cor(AppColors.primaryFixedDim),
                            borderRadius: const pw.BorderRadius.vertical(
                              top: pw.Radius.circular(2),
                            ),
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          i % passo == 0 ? dados[i].rotulo : '',
                          style: texto(size: 6.5, color: suave),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// Label/value pairs inside a bordered box (client and order info).
  static pw.Widget caixaInfo(String titulo, List<(String, String)> linhas) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: borda),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            titulo.toUpperCase(),
            style: texto(
              size: 7.5,
              color: acento,
              bold: true,
            ).copyWith(letterSpacing: 0.6),
          ),
          pw.SizedBox(height: 6),
          for (final (rotulo, valor) in linhas)
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.SizedBox(
                    width: 62,
                    child: pw.Text(rotulo, style: texto(size: 8, color: suave)),
                  ),
                  pw.Expanded(
                    child: pw.Text(valor, style: texto(size: 8.5, bold: true)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
