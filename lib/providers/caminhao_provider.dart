import 'package:flutter/foundation.dart';

import '../models/caminhao.dart';
import '../services/api_exception.dart';
import '../services/caminhao_service.dart';

/// Drives the "Frota" section of the dashboard — trucks fetched from
/// GET /caminhoes.
class CaminhaoProvider extends ChangeNotifier {
  final CaminhaoService _service;

  CaminhaoProvider(this._service);

  List<Caminhao> _caminhoes = [];
  bool _isLoading = false;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<Caminhao> get caminhoes => _caminhoes;

  Future<void> carregar() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _caminhoes = await _service.getCaminhoes();
    } on ApiException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'Não foi possível carregar a frota.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Updates a truck's status and reflects it locally so the UI updates
  /// immediately, without a full reload.
  Future<bool> atualizarStatus(int idCaminhao, CaminhaoStatus novoStatus) async {
    try {
      await _service.atualizarStatus(idCaminhao, novoStatus);
      final index = _caminhoes.indexWhere((c) => c.idCaminhao == idCaminhao);
      if (index != -1) {
        _caminhoes[index] = _caminhoes[index].copyWith(status: novoStatus);
      }
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      return false;
    } catch (_) {
      _error = 'Não foi possível atualizar o status do caminhão.';
      return false;
    }
  }
}
