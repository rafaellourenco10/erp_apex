import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/state_views.dart';
import '../../models/pedido.dart';
import '../../providers/cliente_provider.dart';
import '../../providers/historico_pedidos_provider.dart';
import '../../providers/pedido_provider.dart';
import '../../providers/produto_provider.dart';
import '../../services/pedido_service.dart';

class DetalhePedidoScreen extends StatefulWidget {
  final Pedido pedido;

  const DetalhePedidoScreen({super.key, required this.pedido});

  @override
  State<DetalhePedidoScreen> createState() => _DetalhePedidoScreenState();
}

class _DetalhePedidoScreenState extends State<DetalhePedidoScreen> {
  late Future<List<PedidoItemResumo>> _itensFuture;
  late Pedido _pedido;
  bool _isCancelando = false;
  bool _isRepetindo = false;

  Pedido get pedido => _pedido;

  @override
  void initState() {
    super.initState();
    _pedido = widget.pedido;
    _carregarItens();
  }

  void _carregarItens() {
    _itensFuture =
        context.read<PedidoService>().getItensPedido(pedido.idPedido);
  }

  Future<void> _confirmarCancelamento(BuildContext context) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar pedido?'),
        content: Text('O pedido #${pedido.idPedido} será cancelado.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Voltar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Cancelar pedido'),
          ),
        ],
      ),
    );
    if (confirmar != true || !context.mounted) return;

    setState(() => _isCancelando = true);
    final historico = context.read<HistoricoPedidosProvider>();
    final sucesso = await historico.cancelarPedido(pedido.idPedido);
    if (!context.mounted) return;

    setState(() {
      _isCancelando = false;
      if (sucesso) _pedido = _pedido.copyWith(status: PedidoStatus.cancelado);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          sucesso
              ? 'Pedido #${pedido.idPedido} cancelado.'
              : historico.cancelError ?? 'Não foi possível cancelar o pedido.',
        ),
      ),
    );
  }

  /// Pre-fills the cart with this order's client and items (matched against
  /// the current catalog, so prices and stock limits are up to date), then
  /// jumps to "Adicionar Produtos" so the vendor can review/adjust before
  /// confirming. Items whose product no longer exists are skipped.
  Future<void> _repetirPedido(BuildContext context) async {
    setState(() => _isRepetindo = true);

    final clienteProvider = context.read<ClienteProvider>();
    final produtoProvider = context.read<ProdutoProvider>();
    final pedidoProvider = context.read<PedidoProvider>();

    final carregamentos = <Future<void>>[
      if (clienteProvider.clientes.isEmpty) clienteProvider.carregar(),
      if (produtoProvider.produtos.isEmpty) produtoProvider.carregar(),
    ];
    if (carregamentos.isNotEmpty) await Future.wait(carregamentos);
    if (!context.mounted) return;

    List<PedidoItemResumo> itens;
    try {
      itens = await _itensFuture;
    } catch (_) {
      setState(() => _isRepetindo = false);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível carregar os itens deste pedido.')),
      );
      return;
    }

    final cliente = clienteProvider.buscarPorId(pedido.idCliente);
    if (cliente == null) {
      setState(() => _isRepetindo = false);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível encontrar o cliente deste pedido.')),
      );
      return;
    }

    pedidoProvider.reset();
    pedidoProvider.selecionarCliente(cliente);

    var adicionados = 0;
    for (final item in itens) {
      final produto = produtoProvider.buscarPorId(item.idProduto);
      if (produto == null || produto.estoque <= 0) continue;
      final quantidade =
          item.quantidade > produto.estoque ? produto.estoque : item.quantidade;
      pedidoProvider.setQuantidade(produto, quantidade);
      adicionados++;
    }

    setState(() => _isRepetindo = false);
    if (!context.mounted) return;

    if (adicionados == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Nenhum item deste pedido está disponível no catálogo atual.')),
      );
      return;
    }

    if (adicionados < itens.length) {
      final faltando = itens.length - adicionados;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(faltando == 1
              ? '1 item não está mais disponível e foi removido.'
              : '$faltando itens não estão mais disponíveis e foram removidos.'),
        ),
      );
    }

    Navigator.of(context).pushNamed('/novo-pedido/produtos');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Detalhe do Pedido')),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.marginMain, AppSpacing.stackLg, AppSpacing.marginMain, AppSpacing.stackLg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildInfoCard(),
                  const SizedBox(height: AppSpacing.stackLg),
                  FutureBuilder<List<PedidoItemResumo>>(
                    future: _itensFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 32),
                          child: LoadingView(),
                        );
                      }
                      if (snapshot.hasError) {
                        return ErrorRetryView(
                          message: 'Não foi possível carregar os itens do pedido.',
                          onRetry: () => setState(_carregarItens),
                        );
                      }
                      final itens = snapshot.data ?? [];
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text('Itens (${itens.length})',
                              style: AppTextStyles.headlineSm()),
                          const SizedBox(height: AppSpacing.gutterGrid),
                          for (final item in itens) ...[
                            _buildItemRow(item),
                            const SizedBox(height: AppSpacing.gutterGrid),
                          ],
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: AppSpacing.stackMd),
                  SizedBox(
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed:
                          _isRepetindo ? null : () => _repetirPedido(context),
                      icon: _isRepetindo
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2.5, color: Colors.white),
                            )
                          : const Icon(Icons.replay_rounded),
                      label: const Text('Repetir Pedido'),
                    ),
                  ),
                  if (pedido.status != PedidoStatus.cancelado) ...[
                    const SizedBox(height: AppSpacing.stackMd),
                    SizedBox(
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: _isCancelando
                            ? null
                            : () => _confirmarCancelamento(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.error,
                          foregroundColor: Colors.white,
                        ),
                        icon: _isCancelando
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2.5, color: Colors.white),
                              )
                            : const Icon(Icons.cancel_rounded),
                        label: const Text('Cancelar Pedido'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.marginMain),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Pedido #${pedido.idPedido}', style: AppTextStyles.headlineSm()),
                  Text(pedido.clienteNome, style: AppTextStyles.bodyMd(color: AppColors.secondary)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryFixedDim.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Text(pedido.status.label,
                    style: AppTextStyles.labelMd(color: AppColors.onPrimaryContainer)),
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            children: [
              const Icon(Icons.calendar_today_rounded, size: 18, color: AppColors.secondary),
              const SizedBox(width: 8),
              Text(Formatters.date(pedido.data), style: AppTextStyles.bodyMd(color: AppColors.secondary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildItemRow(PedidoItemResumo item) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.secondaryContainer),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainer,
              borderRadius: BorderRadius.circular(AppRadius.defaultR),
            ),
            child: const Icon(Icons.inventory_2_outlined, color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(width: AppSpacing.stackLg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.nome, style: AppTextStyles.labelLg(), maxLines: 1, overflow: TextOverflow.ellipsis),
                Text('Qtd: ${item.quantidade}', style: AppTextStyles.labelMd()),
              ],
            ),
          ),
          Text(Formatters.currency(item.subtotal), style: AppTextStyles.labelLg()),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.marginMain),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        border: const Border(top: BorderSide(color: AppColors.secondaryContainer)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 16,
              offset: const Offset(0, -4)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Total do Pedido', style: AppTextStyles.bodyMd(color: AppColors.secondary)),
            Text(
              Formatters.currency(pedido.valorTotal),
              style: AppTextStyles.headlineLg(color: AppColors.primaryContainer),
            ),
          ],
        ),
      ),
    );
  }
}
