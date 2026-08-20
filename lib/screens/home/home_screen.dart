import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_bottom_nav_bar.dart';
import '../../providers/auth_provider.dart';
import '../../providers/pedido_provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userName = context.watch<AuthProvider>().userName;
    final displayName = userName.isEmpty ? 'Vendedor' : userName;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, displayName),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.marginMain),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: _buildBentoGrid(context),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNavBar(current: AppTab.home),
    );
  }

  Widget _buildHeader(BuildContext context, String name) {
    return Container(
      color: AppColors.surfaceContainerLowest,
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.marginMain, vertical: AppSpacing.stackLg),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Bem-vindo de volta,', style: AppTextStyles.bodyMd()),
              Text('Olá, $name', style: AppTextStyles.headlineLg()),
            ],
          ),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerHighest,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.surfaceContainerHighest, width: 2),
            ),
            child: const Icon(Icons.person_rounded, color: AppColors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildBentoGrid(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: AppSpacing.gutterGrid,
      mainAxisSpacing: AppSpacing.gutterGrid,
      childAspectRatio: 1.15,
      children: [
        _BentoCard(
          label: 'Novo Pedido',
          icon: Icons.shopping_cart_rounded,
          isPrimary: true,
          onTap: () {
            context.read<PedidoProvider>().reset();
            Navigator.of(context).pushNamed('/novo-pedido/cliente');
          },
        ),
        _BentoCard(
          label: 'Clientes',
          icon: Icons.group_rounded,
          isPrimary: false,
          onTap: () => Navigator.of(context).pushNamed('/clientes'),
        ),
        _BentoCard(
          label: 'Produtos',
          icon: Icons.inventory_2_rounded,
          isPrimary: false,
          onTap: () => Navigator.of(context).pushNamed('/produtos'),
        ),
        _BentoCard(
          label: 'Meus Pedidos',
          icon: Icons.receipt_long_rounded,
          isPrimary: true,
          onTap: () => Navigator.of(context).pushNamed('/meus-pedidos'),
        ),
        _BentoCard(
          label: 'Dashboard',
          icon: Icons.dashboard_rounded,
          isPrimary: true,
          onTap: () => Navigator.of(context).pushNamed('/dashboard'),
        ),
        _BentoCard(
          label: 'Relatórios',
          icon: Icons.description_rounded,
          isPrimary: false,
          onTap: () => Navigator.of(context).pushNamed('/relatorios'),
        ),
      ],
    );
  }
}

class _BentoCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isPrimary;
  final VoidCallback onTap;

  const _BentoCard({
    required this.label,
    required this.icon,
    required this.isPrimary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor =
        isPrimary ? AppColors.primaryContainer : AppColors.onTertiaryFixed;
    final iconBgColor = isPrimary
        ? Colors.white.withValues(alpha: 0.2)
        : AppColors.primaryContainer.withValues(alpha: 0.15);

    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.stackLg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(color: iconBgColor, shape: BoxShape.circle),
                child: Icon(icon,
                    color: isPrimary ? Colors.white : AppColors.primaryContainer),
              ),
              Text(
                label,
                style: AppTextStyles.headlineMd(color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
