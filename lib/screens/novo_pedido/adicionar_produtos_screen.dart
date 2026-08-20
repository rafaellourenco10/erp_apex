import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/state_views.dart';
import '../../models/produto.dart';
import '../../providers/pedido_provider.dart';
import '../../providers/produto_provider.dart';
import 'widgets/pedido_progress_indicator.dart';

class AdicionarProdutosScreen extends StatefulWidget {
  const AdicionarProdutosScreen({super.key});

  @override
  State<AdicionarProdutosScreen> createState() => _AdicionarProdutosScreenState();
}

class _AdicionarProdutosScreenState extends State<AdicionarProdutosScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProdutoProvider>().carregar();
    });
  }

  @override
  Widget build(BuildContext context) {
    final pedidoProvider = context.watch<PedidoProvider>();
    final cliente = pedidoProvider.clienteSelecionado;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Novo Pedido')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.marginMain, AppSpacing.stackLg, AppSpacing.marginMain, 0),
            child: const PedidoProgressIndicator(currentStep: 2),
          ),
          if (cliente != null)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.stackMd),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainer,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                  border: Border.all(color: AppColors.surfaceVariant),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.person_rounded, size: 16, color: AppColors.secondary),
                    const SizedBox(width: 6),
                    Text.rich(
                      TextSpan(
                        text: 'Cliente: ',
                        style: AppTextStyles.labelMd(color: AppColors.onSurface),
                        children: [
                          TextSpan(
                            text: cliente.nome,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.marginMain, AppSpacing.stackLg, AppSpacing.marginMain, 0),
            child: TextField(
              onChanged: (v) => context.read<ProdutoProvider>().search(v),
              decoration: const InputDecoration(
                hintText: 'Buscar produtos...',
                prefixIcon: Icon(Icons.search_rounded),
              ),
            ),
          ),
          Expanded(
            child: Consumer<ProdutoProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading) return const LoadingView();
                if (provider.error != null) {
                  return ErrorRetryView(message: provider.error!, onRetry: provider.carregar);
                }
                if (provider.produtos.isEmpty) {
                  return const EmptyView(
                      message: 'Nenhum produto encontrado.', icon: Icons.inventory_2_outlined);
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.marginMain,
                      AppSpacing.stackLg, AppSpacing.marginMain, 160),
                  itemCount: provider.produtos.length,
                  separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.gutterGrid),
                  itemBuilder: (context, index) =>
                      _ProdutoQtyCard(produto: provider.produtos[index]),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.marginMain, vertical: AppSpacing.stackLg),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            border: const Border(top: BorderSide(color: AppColors.surfaceVariant)),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 16,
                  offset: const Offset(0, -4)),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${pedidoProvider.totalItensDistintos} ${pedidoProvider.totalItensDistintos == 1 ? "item selecionado" : "itens selecionados"}',
                    style: AppTextStyles.bodyMd(color: AppColors.secondary),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('TOTAL DO PEDIDO',
                          style: AppTextStyles.labelSm().copyWith(letterSpacing: 0.6)),
                      Text(
                        Formatters.currency(pedidoProvider.valorTotal),
                        style: AppTextStyles.headlineMd().copyWith(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.stackMd),
              ElevatedButton(
                onPressed: pedidoProvider.podeConfirmar
                    ? () => Navigator.of(context).pushNamed('/novo-pedido/confirmacao')
                    : null,
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Próximo Passo'),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward_rounded, size: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> _editarQuantidade(
  BuildContext context,
  Produto produto,
  int quantidadeAtual,
) async {
  final pedidoProvider = context.read<PedidoProvider>();
  final controller = TextEditingController(
    text: quantidadeAtual == 0 ? '' : '$quantidadeAtual',
  );

  final novaQuantidade = await showDialog<int>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(produto.nome, maxLines: 1, overflow: TextOverflow.ellipsis),
      content: TextField(
        controller: controller,
        autofocus: true,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        textAlign: TextAlign.center,
        style: AppTextStyles.headlineSm(),
        decoration: InputDecoration(
          hintText: '0',
          helperText: 'Estoque disponível: ${produto.estoque} un',
        ),
        onSubmitted: (value) =>
            Navigator.of(dialogContext).pop(int.tryParse(value) ?? 0),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: () => Navigator.of(dialogContext)
              .pop(int.tryParse(controller.text) ?? 0),
          child: const Text('Confirmar'),
        ),
      ],
    ),
  );

  if (novaQuantidade != null) {
    pedidoProvider.setQuantidade(produto, novaQuantidade);
  }
}

class _ProdutoQtyCard extends StatelessWidget {
  final Produto produto;

  const _ProdutoQtyCard({required this.produto});

  @override
  Widget build(BuildContext context) {
    final pedidoProvider = context.watch<PedidoProvider>();
    final quantidade = pedidoProvider.quantidadeDe(produto);
    final selected = quantidade > 0;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.stackMd),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppRadius.defaultR),
        border: Border.all(
          color: selected
              ? AppColors.primaryContainer.withValues(alpha: 0.3)
              : Colors.transparent,
        ),
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
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainer,
              borderRadius: BorderRadius.circular(AppRadius.sm),
              border: Border.all(color: AppColors.surfaceVariant),
            ),
            child: const Icon(Icons.inventory_2_outlined,
                color: AppColors.onSurfaceVariant, size: 28),
          ),
          const SizedBox(width: AppSpacing.stackLg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(produto.nome,
                    style: AppTextStyles.labelLg(), maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                if (produto.estoqueBaixo)
                  Text('Estoque baixo: ${produto.estoque} un',
                      style: AppTextStyles.labelSm(color: AppColors.lowStock)),
                const SizedBox(height: 4),
                Text.rich(
                  TextSpan(
                    text: Formatters.currency(produto.preco),
                    style: AppTextStyles.labelLg(),
                    children: [
                      TextSpan(text: ' / un', style: AppTextStyles.bodyMd()),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.stackMd),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                  border: Border.all(color: AppColors.surfaceVariant),
                ),
                child: Row(
                  children: [
                    _QtyButton(
                      icon: Icons.remove_rounded,
                      color: AppColors.secondary,
                      onTap: quantidade > 0
                          ? () => context.read<PedidoProvider>().decrementar(produto)
                          : null,
                    ),
                    GestureDetector(
                      onTap: () => _editarQuantidade(context, produto, quantidade),
                      child: SizedBox(
                        width: 32,
                        child: Text(
                          '$quantidade',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.labelMd(color: AppColors.onSurface),
                        ),
                      ),
                    ),
                    _QtyButton(
                      icon: Icons.add_rounded,
                      color: AppColors.primaryContainer,
                      onTap: quantidade < produto.estoque
                          ? () => context.read<PedidoProvider>().incrementar(produto)
                          : null,
                    ),
                  ],
                ),
              ),
              if (selected) ...[
                const SizedBox(height: 8),
                Text('Subtotal', style: AppTextStyles.labelSm()),
                Text(
                  Formatters.currency(produto.preco * quantidade),
                  style: AppTextStyles.headlineSm(color: AppColors.primary),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _QtyButton({required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.full),
      child: SizedBox(
        width: 24,
        height: 24,
        child: Icon(icon, size: 16, color: enabled ? color : AppColors.outlineVariant),
      ),
    );
  }
}
