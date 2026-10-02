import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/caminhao.dart';
import '../../models/pedido.dart';
import '../meus_pedidos/detalhe_pedido_screen.dart';

/// Monthly revenue bars drawn with plain widgets (no chart dependency);
/// the current month is highlighted and bars grow in on first build.
class GraficoBarras extends StatelessWidget {
  final List<({DateTime mes, double valor})> vendas;

  const GraficoBarras({super.key, required this.vendas});

  @override
  Widget build(BuildContext context) {
    final max = vendas.fold<double>(0, (m, v) => v.valor > m ? v.valor : m);
    if (max == 0) {
      return SizedBox(
        height: 80,
        child: Center(
          child: Text('Sem vendas no período.', style: AppTextStyles.bodyMd()),
        ),
      );
    }
    return SizedBox(
      height: 180,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < vendas.length; i++)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        vendas[i].valor == 0
                            ? '–'
                            : Formatters.currencyCompact(vendas[i].valor),
                        style: AppTextStyles.labelSm(),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.stackSm),
                    // Bar height is a fraction of whatever space is left, so
                    // labels never push the column past the chart height.
                    Flexible(
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: vendas[i].valor / max),
                        duration: const Duration(milliseconds: 600),
                        curve: Curves.easeOutCubic,
                        builder: (context, fator, _) => FractionallySizedBox(
                          heightFactor: fator.clamp(0.03, 1.0),
                          child: Container(
                            decoration: BoxDecoration(
                              color: i == vendas.length - 1
                                  ? AppColors.primaryContainer
                                  : AppColors.primaryFixedDim,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(6),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.stackMd),
                    Text(
                      Formatters.month(vendas[i].mes),
                      style: AppTextStyles.labelSm(),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// A single proportional bar split by category, plus a legend with counts
/// and percentages. Used for both order status and fleet status.
class BarraSegmentada extends StatelessWidget {
  final List<({String label, int valor, Color cor})> segmentos;

  const BarraSegmentada({super.key, required this.segmentos});

  @override
  Widget build(BuildContext context) {
    final total = segmentos.fold<int>(0, (s, e) => s + e.valor);
    if (total == 0) {
      return Text('Sem dados.', style: AppTextStyles.bodyMd());
    }
    final visiveis = segmentos.where((s) => s.valor > 0).toList();
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.full),
          child: SizedBox(
            height: 12,
            child: Row(
              children: [
                for (var i = 0; i < visiveis.length; i++)
                  Expanded(
                    flex: visiveis[i].valor,
                    child: Container(
                      margin: EdgeInsets.only(
                        right: i < visiveis.length - 1 ? 2 : 0,
                      ),
                      color: visiveis[i].cor,
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.stackLg),
        for (final s in segmentos)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: s.cor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: AppSpacing.stackMd),
                Expanded(child: Text(s.label, style: AppTextStyles.bodyMd())),
                Text('${s.valor}', style: AppTextStyles.labelLg()),
                SizedBox(
                  width: 48,
                  child: Text(
                    '${(s.valor * 100 / total).round()}%',
                    textAlign: TextAlign.right,
                    style: AppTextStyles.labelSm(),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class PedidoRecenteTile extends StatelessWidget {
  final Pedido pedido;

  const PedidoRecenteTile({super.key, required this.pedido});

  @override
  Widget build(BuildContext context) {
    final cores = pedido.status.colors;
    return InkWell(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => DetalhePedidoScreen(pedido: pedido)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.stackLg,
          vertical: AppSpacing.gutterGrid,
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.surfaceContainer,
              child: Text(
                Formatters.initials(pedido.clienteNome),
                style: AppTextStyles.labelMd(color: AppColors.onSurface),
              ),
            ),
            const SizedBox(width: AppSpacing.gutterGrid),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pedido.clienteNome,
                    style: AppTextStyles.labelLg(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '#${pedido.idPedido} · ${Formatters.date(pedido.data)}',
                    style: AppTextStyles.labelSm(),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  Formatters.currency(pedido.valorTotal),
                  style: AppTextStyles.labelLg(),
                ),
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: cores.bg,
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                  child: Text(
                    pedido.status.label,
                    style: AppTextStyles.labelSm(color: cores.fg),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class CaminhaoTile extends StatelessWidget {
  final Caminhao caminhao;

  const CaminhaoTile({super.key, required this.caminhao});

  @override
  Widget build(BuildContext context) {
    final detalhe = [
      caminhao.modelo,
      caminhao.motorista,
    ].where((t) => t != null && t.isNotEmpty).join(' · ');
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.gutterGrid),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.stackMd),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(AppRadius.defaultR),
            ),
            child: const Icon(
              Icons.local_shipping_rounded,
              color: AppColors.onSurfaceVariant,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.gutterGrid),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(caminhao.placa, style: AppTextStyles.labelLg()),
                if (detalhe.isNotEmpty)
                  Text(
                    detalhe,
                    style: AppTextStyles.labelSm(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: caminhao.status.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.full),
            ),
            child: Text(
              caminhao.status.label,
              style: AppTextStyles.labelSm(color: caminhao.status.color),
            ),
          ),
        ],
      ),
    );
  }
}
