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

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HistoricoPedidosProvider>().carregar();
      context.read<CaminhaoProvider>().carregar();
    });
  }

  Future<void> _refresh(BuildContext context) async {
    await Future.wait([
      context.read<HistoricoPedidosProvider>().carregar(),
      context.read<CaminhaoProvider>().carregar(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('ERP Simples')),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => _refresh(context),
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.marginMain),
            children: [
              Text('Dashboard', style: AppTextStyles.headlineLg()),
              const SizedBox(height: 2),
              Text('Visão geral de pedidos e frota.', style: AppTextStyles.bodyMd()),
              const SizedBox(height: AppSpacing.stackXl),
              const _KpiSection(),
              const SizedBox(height: AppSpacing.stackXl),
              Text('Frota', style: AppTextStyles.headlineMd()),
              const SizedBox(height: AppSpacing.stackMd),
              const _FrotaSection(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const AppBottomNavBar(),
    );
  }
}

class _KpiSection extends StatelessWidget {
  const _KpiSection();

  @override
  Widget build(BuildContext context) {
    return Consumer<HistoricoPedidosProvider>(
      builder: (context, provider, _) {
        final pendentes = provider.pedidos
            .where((p) => p.status == PedidoStatus.pendente)
            .toList();
        final valorEmAberto =
            pendentes.fold<double>(0, (soma, p) => soma + p.valorTotal);

        return Row(
          children: [
            Expanded(
              child: _KpiCard(
                icon: Icons.pending_actions_rounded,
                label: 'Pedidos pendentes',
                value: '${pendentes.length}',
              ),
            ),
            const SizedBox(width: AppSpacing.gutterGrid),
            Expanded(
              child: _KpiCard(
                icon: Icons.payments_rounded,
                label: 'Valor em aberto',
                value: Formatters.currency(valorEmAberto),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _KpiCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _KpiCard({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.stackLg),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppRadius.defaultR),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primaryContainer, size: 28),
          const SizedBox(height: AppSpacing.stackMd),
          Text(
            value,
            style: AppTextStyles.headlineMd().copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 2),
          Text(label, style: AppTextStyles.bodyMd()),
        ],
      ),
    );
  }
}

class _FrotaSection extends StatelessWidget {
  const _FrotaSection();

  @override
  Widget build(BuildContext context) {
    return Consumer<CaminhaoProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const SizedBox(height: 200, child: LoadingView());
        }
        if (provider.error != null) {
          return SizedBox(
            height: 200,
            child: ErrorRetryView(
              message: provider.error!,
              onRetry: provider.carregar,
            ),
          );
        }
        if (provider.caminhoes.isEmpty) {
          return const SizedBox(
            height: 200,
            child: EmptyView(
              message: 'Nenhum caminhão cadastrado.',
              icon: Icons.local_shipping_outlined,
            ),
          );
        }
        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: provider.caminhoes.length,
          separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.gutterGrid),
          itemBuilder: (context, index) => _CaminhaoCard(caminhao: provider.caminhoes[index]),
        );
      },
    );
  }
}

class _CaminhaoCard extends StatelessWidget {
  final Caminhao caminhao;

  const _CaminhaoCard({required this.caminhao});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.stackLg),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(AppRadius.defaultR),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: const Icon(Icons.local_shipping_rounded,
                color: AppColors.onSurfaceVariant, size: 26),
          ),
          const SizedBox(width: AppSpacing.stackLg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(caminhao.placa, style: AppTextStyles.headlineSm()),
                    _StatusChip(status: caminhao.status),
                  ],
                ),
                if (caminhao.modelo != null && caminhao.modelo!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(caminhao.modelo!, style: AppTextStyles.bodyMd()),
                ],
                if (caminhao.motorista != null && caminhao.motorista!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.person_outline_rounded,
                          size: 14, color: AppColors.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Text(caminhao.motorista!, style: AppTextStyles.bodyMd()),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final CaminhaoStatus status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: status.color,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Text(
        status.label.toUpperCase(),
        style: AppTextStyles.labelSm(color: Colors.white).copyWith(letterSpacing: 0.6),
      ),
    );
  }
}
