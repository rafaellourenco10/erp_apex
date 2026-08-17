import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/app_bottom_nav_bar.dart';
import '../../core/widgets/state_views.dart';
import '../../models/pedido.dart';
import '../../providers/historico_pedidos_provider.dart';
import 'detalhe_pedido_screen.dart';

class MeusPedidosScreen extends StatefulWidget {
  const MeusPedidosScreen({super.key});

  @override
  State<MeusPedidosScreen> createState() => _MeusPedidosScreenState();
}

class _MeusPedidosScreenState extends State<MeusPedidosScreen> {
  PedidoStatus? _filtro;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HistoricoPedidosProvider>().carregar();
    });
  }

  List<Pedido> _filtrar(List<Pedido> pedidos) {
    if (_filtro == null) return pedidos;
    return pedidos.where((p) => p.status == _filtro).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('ERP Simples')),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.marginMain, AppSpacing.stackLg, AppSpacing.marginMain, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Meus Pedidos', style: AppTextStyles.headlineLg()),
                  const SizedBox(height: 2),
                  Text('Gerencie seus pedidos recentes.', style: AppTextStyles.bodyMd()),
                ],
              ),
            ),
            SizedBox(
              height: 56,
              child: Stack(
                children: [
                  ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.marginMain, vertical: AppSpacing.stackMd),
                    children: [
                      _FilterChip(label: 'Todos', selected: _filtro == null, onTap: () => setState(() => _filtro = null)),
                      const SizedBox(width: 8),
                      for (final status in PedidoStatus.values) ...[
                        _FilterChip(
                          label: status.label,
                          selected: _filtro == status,
                          onTap: () => setState(() => _filtro = status),
                        ),
                        const SizedBox(width: 8),
                      ],
                    ],
                  ),
                  const _EdgeFade(alignment: Alignment.centerLeft),
                  const _EdgeFade(alignment: Alignment.centerRight),
                ],
              ),
            ),
            Expanded(
              child: Consumer<HistoricoPedidosProvider>(
                builder: (context, provider, _) {
                  if (provider.isLoading) return const LoadingView();
                  if (provider.error != null) {
                    return ErrorRetryView(
                        message: provider.error!, onRetry: provider.carregar);
                  }
                  final pedidosFiltrados = _filtrar(provider.pedidos);
                  if (pedidosFiltrados.isEmpty) {
                    return const EmptyView(
                      message: 'Nenhum pedido encontrado para este filtro.',
                      icon: Icons.receipt_long_outlined,
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.marginMain, 0,
                        AppSpacing.marginMain, AppSpacing.marginMain),
                    itemCount: pedidosFiltrados.length,
                    separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.gutterGrid),
                    itemBuilder: (context, index) {
                      final pedido = pedidosFiltrados[index];
                      return _PedidoCard(
                        pedido: pedido,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => DetalhePedidoScreen(pedido: pedido),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNavBar(current: AppTab.pedidos),
    );
  }
}

/// Soft fade at one edge of the horizontal filter chips, hinting there's
/// more to scroll instead of abruptly clipping the chip mid-label.
class _EdgeFade extends StatelessWidget {
  final Alignment alignment;

  const _EdgeFade({required this.alignment});

  @override
  Widget build(BuildContext context) {
    final fromLeft = alignment == Alignment.centerLeft;
    return Positioned(
      left: fromLeft ? 0 : null,
      right: fromLeft ? null : 0,
      top: 0,
      bottom: 0,
      child: IgnorePointer(
        child: Container(
          width: 24,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: fromLeft ? Alignment.centerLeft : Alignment.centerRight,
              end: fromLeft ? Alignment.centerRight : Alignment.centerLeft,
              colors: [AppColors.background, AppColors.background.withValues(alpha: 0)],
            ),
          ),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.full),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.onTertiaryFixed : AppColors.surfaceContainer,
          borderRadius: BorderRadius.circular(AppRadius.full),
          // Always present (transparent when selected) so the border width
          // doesn't change the chip's total size — a Border.all() that
          // only exists on the unselected state makes that chip a couple
          // pixels taller than the selected one, and the fixed-height row
          // clips it top/bottom.
          border: Border.all(
              color: selected ? Colors.transparent : AppColors.outlineVariant),
        ),
        child: Text(
          label,
          style: AppTextStyles.labelMd(
              color: selected ? Colors.white : AppColors.onSurfaceVariant),
        ),
      ),
    );
  }
}

class _PedidoCard extends StatelessWidget {
  final Pedido pedido;
  final VoidCallback onTap;

  const _PedidoCard({required this.pedido, required this.onTap});

  ({Color bg, Color fg}) get _statusColors {
    switch (pedido.status) {
      case PedidoStatus.faturado:
        return (bg: AppColors.primaryContainer, fg: Colors.white);
      case PedidoStatus.pendente:
        return (bg: AppColors.primaryFixed, fg: AppColors.onPrimaryFixedVariant);
      case PedidoStatus.aprovado:
        return (bg: AppColors.onTertiaryFixed, fg: Colors.white);
      case PedidoStatus.entregue:
        return (bg: AppColors.success, fg: Colors.white);
      case PedidoStatus.cancelado:
        return (bg: AppColors.errorContainer, fg: AppColors.onErrorContainer);
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColors = _statusColors;
    final cancelado = pedido.status == PedidoStatus.cancelado;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.defaultR),
      child: Opacity(
        opacity: cancelado ? 0.75 : 1,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.marginMain),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(AppRadius.defaultR),
            border: Border.all(color: AppColors.surfaceContainer),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 2)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('#${pedido.idPedido}', style: AppTextStyles.labelLg(color: AppColors.onSurfaceVariant)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColors.bg,
                      borderRadius: BorderRadius.circular(AppRadius.full),
                    ),
                    child: Text(
                      pedido.status.label.toUpperCase(),
                      style: AppTextStyles.labelSm(color: statusColors.fg).copyWith(letterSpacing: 0.6),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.stackMd),
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: AppColors.surfaceContainerHighest,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.storefront_rounded, color: AppColors.onSurfaceVariant),
                  ),
                  const SizedBox(width: AppSpacing.stackMd),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(pedido.clienteNome, style: AppTextStyles.headlineSm()),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today_rounded,
                              size: 14, color: AppColors.onSurfaceVariant),
                          const SizedBox(width: 4),
                          Text(Formatters.date(pedido.data), style: AppTextStyles.bodyMd()),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Valor Total', style: AppTextStyles.bodyMd()),
                  Text(
                    Formatters.currency(pedido.valorTotal),
                    style: AppTextStyles.headlineMd(
                      color: cancelado ? AppColors.onSurfaceVariant : AppColors.primaryContainer,
                    ).copyWith(
                      decoration: cancelado ? TextDecoration.lineThrough : null,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
