import 'package:flutter/foundation.dart';

import '../models/cliente.dart';
import '../services/api_exception.dart';
import '../services/cliente_service.dart';

class ClienteProvider extends ChangeNotifier {
  final ClienteService _service;

  ClienteProvider(this._service);

  List<Cliente> _clientes = [];
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';

  bool _isSubmitting = false;
  String? _submitError;

  bool get isLoading => _isLoading;
  String? get error => _error;

  bool get isSubmitting => _isSubmitting;
  String? get submitError => _submitError;

  List<Cliente> get clientes {
    if (_searchQuery.isEmpty) return _clientes;
    final query = _searchQuery.toLowerCase();
    return _clientes
        .where((c) => c.nome.toLowerCase().contains(query))
        .toList();
  }

  Future<void> carregar() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _clientes = await _service.getClientes();
    } on ApiException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'Não foi possível carregar os clientes.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void search(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  /// Looks up a client by id across the full (unfiltered) list — used by
  /// "repetir pedido" to find the client regardless of an active search.
  Cliente? buscarPorId(int idCliente) {
    for (final cliente in _clientes) {
      if (cliente.idCliente == idCliente) return cliente;
    }
    return null;
  }

  /// Creates a new client (`POST /clientes`) and appends it to the loaded
  /// list on success. Returns true on success; on failure, [submitError]
  /// explains why.
  Future<bool> criarCliente({
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
    _isSubmitting = true;
    _submitError = null;
    notifyListeners();

    try {
      final idCliente = await _service.criarCliente(
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
      _clientes.add(Cliente(
        idCliente: idCliente,
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
      ));
      _isSubmitting = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _submitError = e.message;
      _isSubmitting = false;
      notifyListeners();
      return false;
    } catch (_) {
      _submitError = 'Não foi possível cadastrar o cliente.';
      _isSubmitting = false;
      notifyListeners();
      return false;
    }
  }

  /// Updates an existing client and reflects it locally on success. Returns
  /// true on success; on failure, [submitError] explains why.
  Future<bool> atualizarCliente(
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
    _isSubmitting = true;
    _submitError = null;
    notifyListeners();

    try {
      await _service.atualizarCliente(
        idCliente,
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
      final index = _clientes.indexWhere((c) => c.idCliente == idCliente);
      if (index != -1) {
        _clientes[index] = Cliente(
          idCliente: idCliente,
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
      }
      _isSubmitting = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _submitError = e.message;
      _isSubmitting = false;
      notifyListeners();
      return false;
    } catch (_) {
      _submitError = 'Não foi possível atualizar o cliente.';
      _isSubmitting = false;
      notifyListeners();
      return false;
    }
  }

}
