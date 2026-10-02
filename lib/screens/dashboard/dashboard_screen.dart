import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/app_bottom_nav_bar.dart';
import '../../core/widgets/state_views.dart';
import '../../models/caminhao.dart';
import '../../models/pedido.dart';
import '../../providers/caminhao_provider.dart';
import '../../providers/historico_pedidos_provider.dart';
import 'dashboard_widgets.dart';
import 'dashboard_resumo.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  Future<void> _refresh() => Future.wait([
    context.read<HistoricoPedidosProvider>().carregar(),
    context.read<CaminhaoProvider>().carregar(),
  ]);

  @override
  Widget build(BuildContext context) {
    final pedidos = context.watch<HistoricoPedidosProvider>();
    final frota = context.watch<CaminhaoProvider>();

    Widget body;
    if (pedidos.isLoading && pedidos.pedidos.isEmpty) {
      body = const LoadingView();
    } else if (pedidos.error != null && pedidos.pedidos.isEmpty) {
      body = ErrorRetryView(message: pedidos.error!, onRetry: _refresh);
    } else {
      final resumo = DashboardResumo.from(pedidos.pedidos, frota.caminhoes);
      body = RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.marginMain),
          children: [
            _HeroCard(resumo: resumo),
            const SizedBox(height: AppSpacing.gutterGrid),
            _KpiGrid(resumo: resumo),
            const SizedBox(height: AppSpacing.gutterGrid),
            _Secao(
              titulo: 'Vendas por mês',
              subtitulo: 'Últimos 6 meses, sem cancelados',
              child: GraficoBarras(vendas: resumo.vendasPorMes),
            ),
            const SizedBox(height: AppSpacing.gutterGrid),
            _Secao(
              titulo: 'Pedidos por status',
              child: BarraSegmentada(
                segmentos: [
                  for (final s in PedidoStatus.values)
                    (
                      label: s.label,
                      valor: resumo.porStatus[s]!,
                      cor: s.color,
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.gutterGrid),
            _Secao(
              titulo: 'Frota',
              child: frota.error != null
                  ? Text(
                      frota.error!,
                      style: AppTextStyles.bodyMd(color: AppColors.error),
                    )
                  : Column(
                      children: [
                        BarraSegmentada(
                          segmentos: [
                            for (final s in CaminhaoStatus.values)
                              (
                                label: s.label,
                                valor: resumo.frota[s]!,
                                cor: s.color,
                              ),
                          ],
                        ),
                        for (final c in frota.caminhoes)
                          CaminhaoTile(caminhao: c),
                      ],
                    ),
            ),
            const SizedBox(height: AppSpacing.gutterGrid),
            _Secao(
              titulo: 'Pedidos recentes',
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  for (final p in resumo.recentes) PedidoRecenteTile(pedido: p),
                  if (resumo.recentes.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.stackLg),
                      child: Text(
                        'Nenhum pedido ainda.',
                        style: AppTextStyles.bodyMd(),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Dashboard')),
      body: SafeArea(child: body),
      bottomNavigationBar: const AppBottomNavBar(),
    );
  }
}

/// Dark headline card with total revenue — the first thing the eye lands on.
class _HeroCard extends StatelessWidget {
  final DashboardResumo resumo;

  const _HeroCard({required this.resumo});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.stackXl),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.md),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.onTertiaryFixed, AppColors.onSurface],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.trending_up_rounded,
                color: AppColors.inversePrimary,
                size: 20,
              ),
              const SizedBox(width: AppSpacing.stackMd),
              Text(
                'Faturamento total',
                style: AppTextStyles.labelMd(color: Colors.white70),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.stackMd),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              Formatters.currency(resumo.faturamento),
              style: AppTextStyles.headlineLg(color: Colors.white).copyWith(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.stackLg),
          Row(
            children: [
              _HeroStat(label: 'Pedidos', valor: '${resumo.pedidosAtivos}'),
              const SizedBox(width: AppSpacing.stackXl),
              _HeroStat(
                label: 'Ticket médio',
                valor: Formatters.currency(resumo.ticketMedio),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  final String label;
  final String valor;

  const _HeroStat({required this.label, required this.valor});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.labelSm(color: Colors.white60)),
        const SizedBox(height: 2),
        Text(valor, style: AppTextStyles.labelLg(color: Colors.white)),
      ],
    );
  }
}

class _KpiGrid extends StatelessWidget {
  final DashboardResumo resumo;

  const _KpiGrid({required this.resumo});

  @override
  Widget build(BuildContext context) {
    final totalFrota = resumo.frota.values.fold<int>(0, (s, v) => s + v);
    final livres = resumo.frota[CaminhaoStatus.livre]!;
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _KpiCard(
                icon: Icons.pending_actions_rounded,
                label: 'Pedidos pendentes',
                valor: '${resumo.pendentes}',
              ),
            ),
            const SizedBox(width: AppSpacing.gutterGrid),
            Expanded(
              child: _KpiCard(
                icon: Icons.payments_rounded,
                label: 'Valor em aberto',
                valor: Formatters.currencyCompact(resumo.valorEmAberto),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.gutterGrid),
        Row(
          children: [
            Expanded(
              child: _KpiCard(
                icon: Icons.local_shipping_rounded,
                label: 'Caminhões livres',
                valor: '$livres/$totalFrota',
              ),
            ),
            const SizedBox(width: AppSpacing.gutterGrid),
            Expanded(
              child: _KpiCard(
                icon: Icons.task_alt_rounded,
                label: 'Entregues',
                valor: '${resumo.porStatus[PedidoStatus.entregue]}',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String valor;

  const _KpiCard({
    required this.icon,
    required this.label,
    required this.valor,
  });

  @override
  Widget build(BuildContext context) {
    return _CardBase(
      padding: const EdgeInsets.all(AppSpacing.stackLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.stackMd),
            decoration: BoxDecoration(
              color: AppColors.primaryFixed,
              borderRadius: BorderRadius.circular(AppRadius.defaultR),
            ),
            child: Icon(icon, color: AppColors.primaryContainer, size: 20),
          ),
          const SizedBox(height: AppSpacing.stackMd),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              valor,
              style: AppTextStyles.headlineMd().copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            label,
            style: AppTextStyles.labelMd(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _CardBase extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const _CardBase({required this.child, required this.padding});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.surfaceContainerHigh),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _Secao extends StatelessWidget {
  final String titulo;
  final String? subtitulo;
  final Widget child;
  final EdgeInsetsGeometry padding;

  const _Secao({
    required this.titulo,
    this.subtitulo,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(
      AppSpacing.stackLg,
      0,
      AppSpacing.stackLg,
      AppSpacing.stackLg,
    ),
  });

  @override
  Widget build(BuildContext context) {
    return _CardBase(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.stackLg,
              AppSpacing.stackLg,
              AppSpacing.stackLg,
              AppSpacing.stackMd,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo, style: AppTextStyles.headlineSm()),
                if (subtitulo != null)
                  Text(subtitulo!, style: AppTextStyles.labelSm()),
              ],
            ),
          ),
          Padding(padding: padding, child: child),
        ],
      ),
    );
  }
}
