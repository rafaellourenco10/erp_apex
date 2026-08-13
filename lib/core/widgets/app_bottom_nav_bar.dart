import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../theme/app_theme.dart';

enum AppTab { home, pedidos, perfil, none }

/// Shared bottom navigation bar (#1A1A1A background) matching the mockups'
/// Home / Pedidos / Perfil tabs.
class AppBottomNavBar extends StatelessWidget {
  final AppTab current;

  const AppBottomNavBar({super.key, this.current = AppTab.none});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.onTertiaryFixed,
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.marginMain, vertical: AppSpacing.stackMd),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _NavItem(
              icon: Icons.home_rounded,
              label: 'Home',
              active: current == AppTab.home,
              onTap: () => _go(context, '/home'),
            ),
            _NavItem(
              icon: Icons.shopping_cart_rounded,
              label: 'Pedidos',
              active: current == AppTab.pedidos,
              onTap: () => _go(context, '/meus-pedidos'),
            ),
            _NavItem(
              icon: Icons.person_rounded,
              label: 'Perfil',
              active: current == AppTab.perfil,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Perfil em breve.')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _go(BuildContext context, String route) {
    if (ModalRoute.of(context)?.settings.name == route) return;
    Navigator.of(context).pushNamedAndRemoveUntil(route, (r) => false);
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = active
        ? AppColors.primaryContainer
        : Colors.white.withValues(alpha: 0.6);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.defaultR),
      child: SizedBox(
        width: 64,
        height: 56,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
