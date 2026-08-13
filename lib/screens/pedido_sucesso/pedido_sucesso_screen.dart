import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../providers/pedido_provider.dart';

class PedidoSucessoScreen extends StatelessWidget {
  const PedidoSucessoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<PedidoProvider>();
    final idPedido = provider.idPedidoCriado;
    final total = provider.valorTotal;

    return Scaffold(
      backgroundColor: AppColors.surfaceContainerLowest,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.marginMain),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 96,
                        height: 96,
                        decoration: const BoxDecoration(
                          color: AppColors.primaryFixed,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const Icon(Icons.check_circle_rounded,
                          color: AppColors.primaryContainer, size: 48),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.stackXl),
                  Text(
                    'Pedido criado com sucesso!',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.headlineLg(),
                  ),
                  const SizedBox(height: AppSpacing.stackSm),
                  Text(
                    'Pedido #$idPedido — ${Formatters.currency(total)}',
                    style: AppTextStyles.bodyLg(color: AppColors.secondary),
                  ),
                  const SizedBox(height: AppSpacing.stackXl),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        context.read<PedidoProvider>().reset();
                        Navigator.of(context).pushNamedAndRemoveUntil(
                            '/novo-pedido/cliente', (r) => r.settings.name == '/home');
                      },
                      child: const Text('Novo Pedido'),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.stackMd),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        context.read<PedidoProvider>().reset();
                        Navigator.of(context)
                            .pushNamedAndRemoveUntil('/meus-pedidos', (r) => false);
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.onSurface,
                        side: const BorderSide(color: AppColors.onSurface),
                        minimumSize: const Size.fromHeight(56),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.defaultR)),
                      ),
                      child: const Text('Ver Meus Pedidos'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
