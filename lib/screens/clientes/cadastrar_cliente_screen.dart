import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_theme.dart';
import '../../models/cliente.dart';
import '../../providers/cliente_provider.dart';

class CadastrarClienteScreen extends StatefulWidget {
  /// When provided, the screen edits this client instead of creating a new
  /// one (fields pre-filled, title/button text adjusted).
  final Cliente? clienteExistente;

  const CadastrarClienteScreen({super.key, this.clienteExistente});

  bool get isEdicao => clienteExistente != null;

  @override
  State<CadastrarClienteScreen> createState() => _CadastrarClienteScreenState();
}

class _CadastrarClienteScreenState extends State<CadastrarClienteScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _nomeController =
      TextEditingController(text: widget.clienteExistente?.nome);
  late final _emailController =
      TextEditingController(text: widget.clienteExistente?.email);
  late final _telefoneController =
      TextEditingController(text: widget.clienteExistente?.telefone);

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _telefoneController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<ClienteProvider>();
    final nome = _nomeController.text.trim();
    final email = _emailController.text.trim();
    final telefone = _telefoneController.text.trim();

    final sucesso = widget.isEdicao
        ? await provider.atualizarCliente(
            widget.clienteExistente!.idCliente,
            nome: nome,
            email: email,
            telefone: telefone,
          )
        : await provider.criarCliente(nome: nome, email: email, telefone: telefone);

    if (!mounted) return;

    if (sucesso) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.isEdicao
            ? 'Cliente atualizado com sucesso.'
            : 'Cliente cadastrado com sucesso.')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.submitError ?? 'Não foi possível salvar o cliente.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.isEdicao ? 'Editar Cliente' : 'Novo Cliente')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.marginMain),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildField(
                  label: 'NOME',
                  controller: _nomeController,
                  hintText: 'Nome do cliente',
                  keyboardType: TextInputType.name,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Informe o nome do cliente';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.stackLg),
                _buildField(
                  label: 'EMAIL (OPCIONAL)',
                  controller: _emailController,
                  hintText: 'cliente@email.com',
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return null;
                    if (!value.contains('@')) return 'Email inválido';
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.stackLg),
                _buildField(
                  label: 'TELEFONE (OPCIONAL)',
                  controller: _telefoneController,
                  hintText: '(43) 99111-2222',
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: AppSpacing.stackXl),
                Consumer<ClienteProvider>(
                  builder: (context, provider, _) {
                    return ElevatedButton(
                      onPressed: provider.isSubmitting ? null : _submit,
                      child: provider.isSubmitting
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : Text(widget.isEdicao ? 'Salvar' : 'Cadastrar'),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required String hintText,
    required TextInputType keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.labelMd().copyWith(letterSpacing: 0.6)),
        const SizedBox(height: 4),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(hintText: hintText),
          validator: validator,
        ),
      ],
    );
  }
}
