import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/app_bottom_nav_bar.dart';
import '../../core/widgets/state_views.dart';
import '../../models/cliente.dart';
import '../../providers/cliente_provider.dart';

class ClientesScreen extends StatefulWidget {
  const ClientesScreen({super.key});

  @override
  State<ClientesScreen> createState() => _ClientesScreenState();
}

class _ClientesScreenState extends State<ClientesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ClienteProvider>().carregar();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Clientes')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.marginMain, AppSpacing.stackLg, AppSpacing.marginMain, 0),
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
                  return ErrorRetryView(
                    message: provider.error!,
                    onRetry: provider.carregar,
                  );
                }
                if (provider.clientes.isEmpty) {
                  return const EmptyView(
                    message: 'Nenhum cliente encontrado.',
                    icon: Icons.group_outlined,
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.marginMain),
                  itemCount: provider.clientes.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppSpacing.gutterGrid),
                  itemBuilder: (context, index) =>
                      _ClienteCard(cliente: provider.clientes[index]),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primaryContainer,
        foregroundColor: Colors.white,
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cadastro de cliente em breve.')),
          );
        },
        child: const Icon(Icons.add_rounded),
      ),
      bottomNavigationBar: const AppBottomNavBar(),
    );
  }
}

class _ClienteCard extends StatelessWidget {
  final Cliente cliente;

  const _ClienteCard({required this.cliente});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.marginMain),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.defaultR),
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
            backgroundColor: AppColors.primaryContainer.withValues(alpha: 0.1),
            child: Text(
              Formatters.initials(cliente.nome),
              style: AppTextStyles.headlineSm(color: AppColors.primaryContainer),
            ),
          ),
          const SizedBox(width: AppSpacing.marginMain),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(cliente.nome, style: AppTextStyles.headlineSm()),
                const SizedBox(height: AppSpacing.stackSm),
                if (cliente.email != null && cliente.email!.isNotEmpty)
                  _InfoRow(icon: Icons.mail_outline_rounded, text: cliente.email!),
                if (cliente.telefone != null && cliente.telefone!.isNotEmpty)
                  _InfoRow(
                      icon: Icons.call_outlined,
                      text: Formatters.phone(cliente.telefone)),
                if (cliente.cpfCnpj != null && cliente.cpfCnpj!.isNotEmpty)
                  _InfoRow(icon: Icons.badge_outlined, text: cliente.cpfCnpj!),
                if (cliente.enderecoCompleto != null)
                  _InfoRow(
                      icon: Icons.location_on_outlined,
                      text: cliente.enderecoCompleto!),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.onSurfaceVariant),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              style: AppTextStyles.labelMd(),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
