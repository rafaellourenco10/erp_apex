import '../core/constants/api_constants.dart';
import '../models/cliente.dart';
import 'api_service.dart';

class ClienteService {
  final ApiService _api;

  ClienteService(this._api);

  Future<List<Cliente>> getClientes() async {
    final data = await _api.get(ApiConstants.clientes);
    final items = (data['items'] as List<dynamic>? ?? []);
    return items
        .map((e) => Cliente.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Creates a new client (`POST /clientes`). Returns the generated `id_cliente`.
  Future<int> criarCliente({
    required String nome,
    String? email,
    String? telefone,
    String? cpfCnpj,
    String? endereco,
    String? numero,
    String? complemento,
    String? bairro,
    String? cidade,
    String? uf,
    String? cep,
  }) async {
    final data = await _api.post(ApiConstants.clientes, {
      'nome': nome,
      if (email != null && email.isNotEmpty) 'email': email,
      if (telefone != null && telefone.isNotEmpty) 'telefone': telefone,
      if (cpfCnpj != null && cpfCnpj.isNotEmpty) 'cpf_cnpj': cpfCnpj,
      if (endereco != null && endereco.isNotEmpty) 'endereco': endereco,
      if (numero != null && numero.isNotEmpty) 'numero': numero,
      if (complemento != null && complemento.isNotEmpty) 'complemento': complemento,
      if (bairro != null && bairro.isNotEmpty) 'bairro': bairro,
      if (cidade != null && cidade.isNotEmpty) 'cidade': cidade,
      if (uf != null && uf.isNotEmpty) 'uf': uf,
      if (cep != null && cep.isNotEmpty) 'cep': cep,
    });
    return data['id_cliente'] as int;
  }

  /// Updates an existing client (`POST /clientes/{id}`).
  Future<void> atualizarCliente(
    int idCliente, {
    required String nome,
    String? email,
    String? telefone,
    String? cpfCnpj,
    String? endereco,
    String? numero,
    String? complemento,
    String? bairro,
    String? cidade,
    String? uf,
    String? cep,
  }) async {
    await _api.post('${ApiConstants.clientes}/$idCliente', {
      'nome': nome,
      if (email != null && email.isNotEmpty) 'email': email,
      if (telefone != null && telefone.isNotEmpty) 'telefone': telefone,
      if (cpfCnpj != null && cpfCnpj.isNotEmpty) 'cpf_cnpj': cpfCnpj,
      if (endereco != null && endereco.isNotEmpty) 'endereco': endereco,
      if (numero != null && numero.isNotEmpty) 'numero': numero,
      if (complemento != null && complemento.isNotEmpty) 'complemento': complemento,
      if (bairro != null && bairro.isNotEmpty) 'bairro': bairro,
      if (cidade != null && cidade.isNotEmpty) 'cidade': cidade,
      if (uf != null && uf.isNotEmpty) 'uf': uf,
      if (cep != null && cep.isNotEmpty) 'cep': cep,
    });
  }
}
