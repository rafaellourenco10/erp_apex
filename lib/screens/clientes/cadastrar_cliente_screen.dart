import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/input_formatters.dart';
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
  late final _cpfCnpjController =
      TextEditingController(text: widget.clienteExistente?.cpfCnpj);
  late final _enderecoController =
      TextEditingController(text: widget.clienteExistente?.endereco);
  late final _numeroController =
      TextEditingController(text: widget.clienteExistente?.numero);
  late final _complementoController =
      TextEditingController(text: widget.clienteExistente?.complemento);
  late final _bairroController =
      TextEditingController(text: widget.clienteExistente?.bairro);
  late final _cidadeController =
      TextEditingController(text: widget.clienteExistente?.cidade);
  late final _ufController = TextEditingController(text: widget.clienteExistente?.uf);
  late final _cepController = TextEditingController(text: widget.clienteExistente?.cep);

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _telefoneController.dispose();
    _cpfCnpjController.dispose();
    _enderecoController.dispose();
    _numeroController.dispose();
    _complementoController.dispose();
    _bairroController.dispose();
    _cidadeController.dispose();
    _ufController.dispose();
    _cepController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<ClienteProvider>();
    final nome = _nomeController.text.trim();
    final email = _emailController.text.trim();
    final telefone = _telefoneController.text.trim();
    final cpfCnpj = _cpfCnpjController.text.trim();
    final endereco = _enderecoController.text.trim();
    final numero = _numeroController.text.trim();
    final complemento = _complementoController.text.trim();
    final bairro = _bairroController.text.trim();
    final cidade = _cidadeController.text.trim();
    final uf = _ufController.text.trim();
    final cep = _cepController.text.trim();

    final sucesso = widget.isEdicao
        ? await provider.atualizarCliente(
            widget.clienteExistente!.idCliente,
            nome: nome,
            email: email,
            telefone: telefone,
            cpfCnpj: cpfCnpj,
            endereco: endereco,
            numero: numero,
            complemento: complemento,
            bairro: bairro,
            cidade: cidade,
            uf: uf,
            cep: cep,
          )
        : await provider.criarCliente(
            nome: nome,
            email: email,
            telefone: telefone,
            cpfCnpj: cpfCnpj,
            endereco: endereco,
            numero: numero,
            complemento: complemento,
            bairro: bairro,
            cidade: cidade,
            uf: uf,
            cep: cep,
          );

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
                  label: 'EMAIL',
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
                  label: 'TELEFONE',
                  controller: _telefoneController,
                  hintText: '(44) 99999-0000',
                  keyboardType: TextInputType.phone,
                  inputFormatters: [TelefoneInputFormatter()],
                ),
                const SizedBox(height: AppSpacing.stackLg),
                _buildField(
                  label: 'CPF/CNPJ',
                  controller: _cpfCnpjController,
                  hintText: '000.000.000-00',
                  keyboardType: TextInputType.number,
                  inputFormatters: [CpfCnpjInputFormatter()],
                ),
                const SizedBox(height: AppSpacing.stackLg),
                _buildField(
                  label: 'ENDEREÇO',
                  controller: _enderecoController,
                  hintText: 'Rua, avenida...',
                  keyboardType: TextInputType.streetAddress,
                ),
                const SizedBox(height: AppSpacing.stackLg),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildField(
                        label: 'NÚMERO',
                        controller: _numeroController,
                        hintText: '123',
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.gutterGrid),
                    Expanded(
                      flex: 2,
                      child: _buildField(
                        label: 'COMPLEMENTO (OPCIONAL)',
                        controller: _complementoController,
                        hintText: 'Bloco, sala...',
                        keyboardType: TextInputType.text,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.stackLg),
                _buildField(
                  label: 'BAIRRO',
                  controller: _bairroController,
                  hintText: 'Bairro',
                  keyboardType: TextInputType.text,
                ),
                const SizedBox(height: AppSpacing.stackLg),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: _buildField(
                        label: 'CIDADE',
                        controller: _cidadeController,
                        hintText: 'Cidade',
                        keyboardType: TextInputType.text,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.gutterGrid),
                    Expanded(
                      child: _buildField(
                        label: 'UF',
                        controller: _ufController,
                        hintText: 'PR',
                        keyboardType: TextInputType.text,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.stackLg),
                _buildField(
                  label: 'CEP',
                  controller: _cepController,
                  hintText: '87000-000',
                  keyboardType: TextInputType.number,
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
    List<TextInputFormatter>? inputFormatters,
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
          inputFormatters: inputFormatters,
        ),
      ],
    );
  }
}
