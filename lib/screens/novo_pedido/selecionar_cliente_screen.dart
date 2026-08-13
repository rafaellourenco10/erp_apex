import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/state_views.dart';
import '../../models/cliente.dart';
import '../../providers/cliente_provider.dart';
import '../../providers/pedido_provider.dart';
import 'widgets/pedido_progress_indicator.dart';

class SelecionarClienteScreen extends StatefulWidget {
  const SelecionarClienteScreen({super.key});

  @override
  State<SelecionarClienteScreen> createState() => _SelecionarClienteScreenState();
}

class _SelecionarClienteScreenState extends State<SelecionarClienteScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ClienteProvider>().carregar();
    });
  }

  @override
  Widget build(BuildContext context) {
    final pedidoProvider = context.watch<PedidoProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Novo Pedido')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.marginMain, AppSpacing.stackLg, AppSpacing.marginMain, 0),
            child: const PedidoProgressIndicator(currentStep: 1),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.marginMain, AppSpacing.stackMd, AppSpacing.marginMain, 0),
            child: TextField(
              onChanged: (v) => context.read<ClienteProvider>().search(v),
              decoration: const InputDecoration(
                hintText: 'Buscar cliente...',
                prefixIcon: Icon(Icons.search_rounded),
              ),
            ),
          ),
          Expanded(
            child: Consumer<ClienteProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading) return const LoadingView();
                if (provider.error != null) {
                  return ErrorRetryView(message: provider.error!, onRetry: provider.carregar);
                }
                if (provider.clientes.isEmpty) {
                  return const EmptyView(
                      message: 'Nenhum cliente encontrado.', icon: Icons.group_outlined);
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.marginMain,
                      AppSpacing.stackMd, AppSpacing.marginMain, 120),
                  itemCount: provider.clientes.length,
                  separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.gutterGrid),
                  itemBuilder: (context, index) {
                    final cliente = provider.clientes[index];
                    final selected =
                        pedidoProvider.clienteSelecionado?.idCliente == cliente.idCliente;
                    return _ClienteSelectableCard(
                      cliente: cliente,
                      selected: selected,
                      onTap: () => context.read<PedidoProvider>().selecionarCliente(cliente),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.marginMain),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 16,
                  offset: const Offset(0, -4)),
            ],
          ),
          child: ElevatedButton(
            onPressed: pedidoProvider.podeAvancarParaProdutos
                ? () => Navigator.of(context).pushNamed('/novo-pedido/produtos')
                : null,
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Próximo'),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward_rounded, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ClienteSelectableCard extends StatelessWidget {
  final Cliente cliente;
  final bool selected;
  final VoidCallback onTap;

  const _ClienteSelectableCard({
    required this.cliente,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.defaultR),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.marginMain),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(AppRadius.defaultR),
          border: Border.all(
            color: selected ? AppColors.primaryContainer : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.surfaceVariant,
              child: Text(
                Formatters.initials(cliente.nome),
                style: AppTextStyles.headlineSm(color: AppColors.onSurfaceVariant),
              ),
            ),
            const SizedBox(width: AppSpacing.stackLg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(cliente.nome, style: AppTextStyles.headlineSm()),
                  if (cliente.email != null && cliente.email!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(cliente.email!, style: AppTextStyles.bodyMd()),
                    ),
                ],
              ),
            ),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? AppColors.primaryContainer : AppColors.outlineVariant,
                  width: 2,
                ),
              ),
              alignment: Alignment.center,
              child: selected
                  ? Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(
                          color: AppColors.primaryContainer, shape: BoxShape.circle),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
