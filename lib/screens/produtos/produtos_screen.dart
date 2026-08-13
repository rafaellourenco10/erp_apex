import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/app_bottom_nav_bar.dart';
import '../../core/widgets/state_views.dart';
import '../../models/produto.dart';
import '../../providers/produto_provider.dart';

class ProdutosScreen extends StatefulWidget {
  const ProdutosScreen({super.key});

  @override
  State<ProdutosScreen> createState() => _ProdutosScreenState();
}

class _ProdutosScreenState extends State<ProdutosScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProdutoProvider>().carregar();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Produtos')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.marginMain),
            child: TextField(
              onChanged: (v) => context.read<ProdutoProvider>().search(v),
              decoration: const InputDecoration(
                hintText: 'Buscar produto...',
                prefixIcon: Icon(Icons.search_rounded),
              ),
            ),
          ),
          Expanded(
            child: Consumer<ProdutoProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading) return const LoadingView();
                if (provider.error != null) {
                  return ErrorRetryView(
                    message: provider.error!,
                    onRetry: provider.carregar,
                  );
                }
                if (provider.produtos.isEmpty) {
                  return const EmptyView(
                    message: 'Nenhum produto encontrado.',
                    icon: Icons.inventory_2_outlined,
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.marginMain, 0, AppSpacing.marginMain, AppSpacing.marginMain),
                  itemCount: provider.produtos.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppSpacing.gutterGrid),
                  itemBuilder: (context, index) =>
                      _ProdutoCard(produto: provider.produtos[index]),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: const AppBottomNavBar(),
    );
  }
}

class _ProdutoCard extends StatelessWidget {
  final Produto produto;

  const _ProdutoCard({required this.produto});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.stackLg),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppRadius.defaultR),
        border: produto.estoqueBaixo
            ? Border.all(color: AppColors.errorContainer)
            : null,
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
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: const Icon(Icons.inventory_2_outlined,
                color: AppColors.onSurfaceVariant, size: 32),
          ),
          const SizedBox(width: AppSpacing.stackLg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(produto.nome, style: AppTextStyles.headlineSm()),
                if (produto.descricao != null && produto.descricao!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    produto.descricao!,
                    style: AppTextStyles.bodyMd(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      Formatters.currency(produto.preco),
                      style: AppTextStyles.headlineSm(color: AppColors.primaryContainer)
                          .copyWith(fontWeight: FontWeight.w700),
                    ),
                    _StockBadge(produto: produto),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StockBadge extends StatelessWidget {
  final Produto produto;

  const _StockBadge({required this.produto});

  @override
  Widget build(BuildContext context) {
    final baixo = produto.estoqueBaixo;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: baixo ? AppColors.lowStock : AppColors.onTertiaryFixed,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (baixo) ...[
            const Icon(Icons.warning_amber_rounded, size: 12, color: Colors.white),
            const SizedBox(width: 4),
          ],
          Text(
            baixo ? 'Estoque baixo (${produto.estoque})' : 'Stock: ${produto.estoque}',
            style: AppTextStyles.labelSm(color: Colors.white),
          ),
        ],
      ),
    );
  }
}
