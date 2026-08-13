import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/item_pedido.dart';
import '../../providers/pedido_provider.dart';
import 'widgets/pedido_progress_indicator.dart';

class ConfirmacaoScreen extends StatelessWidget {
  const ConfirmacaoScreen({super.key});

  Future<void> _confirmar(BuildContext context) async {
    final provider = context.read<PedidoProvider>();
    final sucesso = await provider.confirmarPedido();
    if (!context.mounted) return;

    if (sucesso) {
      Navigator.of(context).pushNamedAndRemoveUntil('/pedido-sucesso', (r) => false);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.submitError ?? 'Não foi possível confirmar o pedido.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final pedidoProvider = context.watch<PedidoProvider>();
    final cliente = pedidoProvider.clienteSelecionado;
    final itens = pedidoProvider.itens;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Confirmar Pedido')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.marginMain, AppSpacing.stackLg, AppSpacing.marginMain, 140),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const PedidoProgressIndicator(currentStep: 3),
            const SizedBox(height: AppSpacing.stackXl),
            _buildClienteCard(cliente?.nome ?? '-'),
            const SizedBox(height: AppSpacing.stackLg),
            _buildItensCard(itens),
            const SizedBox(height: AppSpacing.stackMd),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total:',
                    style: AppTextStyles.headlineMd().copyWith(fontWeight: FontWeight.w700)),
                Text(
                  Formatters.currency(pedidoProvider.valorTotal),
                  style: AppTextStyles.headlineLg(color: AppColors.primaryContainer)
                      .copyWith(fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.marginMain),
          decoration: BoxDecoration(
            color: AppColors.background.withValues(alpha: 0.95),
            border: const Border(top: BorderSide(color: AppColors.surfaceContainerHighest)),
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed:
                      pedidoProvider.isSubmitting ? null : () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.onTertiaryFixed,
                    side: const BorderSide(color: AppColors.onTertiaryFixed),
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.full)),
                  ),
                  child: const Text('Voltar'),
                ),
              ),
              const SizedBox(width: AppSpacing.stackMd),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: pedidoProvider.isSubmitting ? null : () => _confirmar(context),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.full)),
                  ),
                  child: pedidoProvider.isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child:
                              CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle_rounded, size: 20),
                            SizedBox(width: 8),
                            Text('Confirmar Pedido'),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClienteCard(String nome) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.marginMain),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppRadius.defaultR),
        border: Border.all(color: AppColors.surfaceContainerHigh),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.person_rounded, color: AppColors.primaryContainer),
              const SizedBox(width: 8),
              Text('Detalhes do Cliente', style: AppTextStyles.headlineSm()),
            ],
          ),
          const SizedBox(height: AppSpacing.stackMd),
          _buildInfoRow('Nome', nome, border: true),
          _buildInfoRow('Data', Formatters.date(DateTime.now()), border: true),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Status', style: AppTextStyles.bodyMd()),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Text('PENDENTE', style: AppTextStyles.labelSm(color: AppColors.onSurface)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool border = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: border
            ? const Border(bottom: BorderSide(color: AppColors.surfaceContainerHigh))
            : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.bodyMd()),
          Text(value, style: AppTextStyles.labelLg()),
        ],
      ),
    );
  }

  Widget _buildItensCard(List<ItemPedido> itens) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.marginMain),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppRadius.defaultR),
        border: Border.all(color: AppColors.surfaceContainerHigh),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.inventory_2_rounded, color: AppColors.primaryContainer),
              const SizedBox(width: 8),
              Text('Itens do Pedido', style: AppTextStyles.headlineSm()),
            ],
          ),
          const SizedBox(height: AppSpacing.stackMd),
          for (var i = 0; i < itens.length; i++)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                border: i < itens.length - 1
                    ? const Border(bottom: BorderSide(color: AppColors.surfaceContainerHigh))
                    : null,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        child: const Icon(Icons.inventory_2_outlined,
                            color: AppColors.onSurfaceVariant, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Text(itens[i].produto.nome, style: AppTextStyles.bodyMd(color: AppColors.onSurface)),
                    ],
                  ),
                  Text('${itens[i].quantidade} un', style: AppTextStyles.labelLg()),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
