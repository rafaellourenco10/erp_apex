import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

/// Shared 3-step progress bar for the "Novo Pedido" flow
/// (Cliente -> Produtos -> Confirmação).
class PedidoProgressIndicator extends StatelessWidget {
  final int currentStep; // 1, 2 or 3

  const PedidoProgressIndicator({super.key, required this.currentStep});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          _buildStep(1, 'Cliente'),
          _buildConnector(1),
          _buildStep(2, 'Produtos'),
          _buildConnector(2),
          _buildStep(3, 'Confirmação'),
        ],
      ),
    );
  }

  Widget _buildStep(int step, String label) {
    final isDone = step < currentStep;
    final isActive = step == currentStep;
    final circleColor = isDone || isActive
        ? AppColors.primaryContainer
        : AppColors.surfaceVariant;
    final textColor = isDone || isActive
        ? AppColors.primaryContainer
        : AppColors.onSurfaceVariant;

    return Expanded(
      child: Column(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(color: circleColor, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: isDone
                ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
                : Text(
                    '$step',
                    style: AppTextStyles.labelLg(
                      color: isActive ? Colors.white : AppColors.onSurfaceVariant,
                    ),
                  ),
          ),
          const SizedBox(height: 4),
          Text(label,
              style: AppTextStyles.labelSm(color: textColor), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildConnector(int afterStep) {
    final done = afterStep < currentStep;
    return Container(
      width: 32,
      height: 2,
      margin: const EdgeInsets.only(bottom: 16),
      color: done ? AppColors.primaryContainer : AppColors.surfaceVariant,
    );
  }
}
