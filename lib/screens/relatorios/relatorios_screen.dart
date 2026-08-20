import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/app_bottom_nav_bar.dart';
import '../../core/widgets/state_views.dart';
import '../../models/pedido.dart';
import '../../providers/historico_pedidos_provider.dart';
import '../../services/pdf_report_service.dart';
import '../../services/pedido_service.dart';

class RelatoriosScreen extends StatefulWidget {
  const RelatoriosScreen({super.key});

  @override
  State<RelatoriosScreen> createState() => _RelatoriosScreenState();
}

class _RelatoriosScreenState extends State<RelatoriosScreen> {
  late DateTimeRange _periodo;
  PedidoStatus? _filtroStatus;
  bool _exportandoPeriodo = false;
  int? _exportandoPedidoId;

  @override
  void initState() {
    super.initState();
    final hoje = DateTime.now();
    _periodo = DateTimeRange(
      start: DateTime(hoje.year, hoje.month, hoje.day).subtract(const Duration(days: 30)),
      end: DateTime(hoje.year, hoje.month, hoje.day),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HistoricoPedidosProvider>().carregar();
    });
  }

  bool _dentroDoPeriodo(Pedido pedido) {
    final data = DateTime(pedido.data.year, pedido.data.month, pedido.data.day);
    return !data.isBefore(_periodo.start) && !data.isAfter(_periodo.end);
  }

  List<Pedido> _filtrar(List<Pedido> pedidos) {
    return pedidos
        .where(_dentroDoPeriodo)
        .where((p) => _filtroStatus == null || p.status == _filtroStatus)
        .toList();
  }

  Future<void> _selecionarPeriodo() async {
    final novoPeriodo = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _periodo,
      locale: const Locale('pt', 'BR'),
    );
    if (novoPeriodo != null) {
      setState(() => _periodo = novoPeriodo);
    }
  }

  Future<void> _exportarPeriodo(List<Pedido> pedidosFiltrados) async {
    setState(() => _exportandoPeriodo = true);
    try {
      final bytes = await PdfReportService.gerarPeriodo(
        pedidos: pedidosFiltrados,
        inicio: _periodo.start,
        fim: _periodo.end,
      );
      await Printing.sharePdf(bytes: bytes, filename: 'relatorio_vendas.pdf');
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível gerar o relatório.')),
        );
      }
    } finally {
      if (mounted) setState(() => _exportandoPeriodo = false);
    }
  }

  Future<void> _exportarPedido(Pedido pedido) async {
    setState(() => _exportandoPedidoId = pedido.idPedido);
    try {
      final itens = await context.read<PedidoService>().getItensPedido(pedido.idPedido);
      final bytes = await PdfReportService.gerarPedido(pedido.copyWith(itens: itens));
      await Printing.sharePdf(bytes: bytes, filename: 'pedido_${pedido.idPedido}.pdf');
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível gerar o PDF deste pedido.')),
        );
      }
    } finally {
      if (mounted) setState(() => _exportandoPedidoId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Relatórios')),
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
                  Text('Relatórios', style: AppTextStyles.headlineLg()),
                  const SizedBox(height: 2),
                  Text('Filtre por período e exporte em PDF.', style: AppTextStyles.bodyMd()),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.marginMain, AppSpacing.stackLg, AppSpacing.marginMain, 0),
              child: InkWell(
                onTap: _selecionarPeriodo,
                borderRadius: BorderRadius.circular(AppRadius.defaultR),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(AppRadius.defaultR),
                    border: Border.all(color: AppColors.surfaceVariant),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.date_range_rounded, color: AppColors.secondary, size: 20),
                      const SizedBox(width: 10),
                      Text(
                        '${Formatters.date(_periodo.start)} - ${Formatters.date(_periodo.end)}',
                        style: AppTextStyles.labelMd(color: AppColors.onSurface),
                      ),
                      const Spacer(),
                      const Icon(Icons.expand_more_rounded, color: AppColors.secondary, size: 20),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(
              height: 56,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.marginMain, vertical: AppSpacing.stackMd),
                children: [
                  _FilterChip(
                    label: 'Todos',
                    selected: _filtroStatus == null,
                    onTap: () => setState(() => _filtroStatus = null),
                  ),
                  const SizedBox(width: 8),
                  for (final status in PedidoStatus.values) ...[
                    _FilterChip(
                      label: status.label,
                      selected: _filtroStatus == status,
                      onTap: () => setState(() => _filtroStatus = status),
                    ),
                    const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
            Expanded(
              child: Consumer<HistoricoPedidosProvider>(
                builder: (context, provider, _) {
                  if (provider.isLoading) return const LoadingView();
                  if (provider.error != null) {
                    return ErrorRetryView(message: provider.error!, onRetry: provider.carregar);
                  }
                  final pedidosFiltrados = _filtrar(provider.pedidos);
                  if (pedidosFiltrados.isEmpty) {
                    return const EmptyView(
                      message: 'Nenhum pedido encontrado neste período.',
                      icon: Icons.description_outlined,
                    );
                  }
                  final valorTotal =
                      pedidosFiltrados.fold<double>(0, (sum, p) => sum + p.valorTotal);
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(AppSpacing.marginMain, 0,
                            AppSpacing.marginMain, AppSpacing.stackMd),
                        child: _ResumoPeriodo(
                          totalPedidos: pedidosFiltrados.length,
                          valorTotal: valorTotal,
                          exportando: _exportandoPeriodo,
                          onExportar: () => _exportarPeriodo(pedidosFiltrados),
                        ),
                      ),
                      Expanded(
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(AppSpacing.marginMain, 0,
                              AppSpacing.marginMain, AppSpacing.marginMain),
                          itemCount: pedidosFiltrados.length,
                          separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.gutterGrid),
                          itemBuilder: (context, index) {
                            final pedido = pedidosFiltrados[index];
                            return _RelatorioPedidoCard(
                              pedido: pedido,
                              exportando: _exportandoPedidoId == pedido.idPedido,
                              onCompartilhar: () => _exportarPedido(pedido),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNavBar(),
    );
  }
}

class _ResumoPeriodo extends StatelessWidget {
  final int totalPedidos;
  final double valorTotal;
  final bool exportando;
  final VoidCallback onExportar;

  const _ResumoPeriodo({
    required this.totalPedidos,
    required this.valorTotal,
    required this.exportando,
    required this.onExportar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.stackMd),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.defaultR),
        border: Border.all(color: AppColors.surfaceVariant),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$totalPedidos pedido(s) no período', style: AppTextStyles.bodyMd()),
                Text(
                  Formatters.currency(valorTotal),
                  style: AppTextStyles.headlineMd().copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(0, 44),
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            onPressed: exportando ? null : onExportar,
            icon: exportando
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.share_rounded, size: 18),
            label: const Text('Exportar'),
          ),
        ],
      ),
    );
  }
}

class _RelatorioPedidoCard extends StatelessWidget {
  final Pedido pedido;
  final bool exportando;
  final VoidCallback onCompartilhar;

  const _RelatorioPedidoCard({
    required this.pedido,
    required this.exportando,
    required this.onCompartilhar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.stackMd),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.defaultR),
        border: Border.all(color: AppColors.surfaceContainer),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('#${pedido.idPedido} · ${pedido.clienteNome}',
                    style: AppTextStyles.labelLg(), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text(
                  '${Formatters.date(pedido.data)} · ${pedido.status.label}',
                  style: AppTextStyles.bodyMd(color: AppColors.onSurfaceVariant),
                ),
              ],
            ),
          ),
          Text(Formatters.currency(pedido.valorTotal), style: AppTextStyles.labelLg()),
          const SizedBox(width: 4),
          IconButton(
            onPressed: exportando ? null : onCompartilhar,
            icon: exportando
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.picture_as_pdf_rounded, color: AppColors.primaryContainer),
            tooltip: 'Compartilhar PDF',
          ),
        ],
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
