import '../core/constants/api_constants.dart';
import '../models/caminhao.dart';
import 'api_service.dart';

class CaminhaoService {
  final ApiService _api;

  CaminhaoService(this._api);

  Future<List<Caminhao>> getCaminhoes() async {
    final data = await _api.get(ApiConstants.caminhoes);
    final items = (data['items'] as List<dynamic>? ?? []);
    return items
        .map((e) => Caminhao.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Updates a truck's status (`POST /caminhoes/{id}/status`).
  Future<void> atualizarStatus(int idCaminhao, CaminhaoStatus novoStatus) async {
    await _api.post(
      '${ApiConstants.caminhoes}/$idCaminhao/status',
      {'status': novoStatus.apiValue},
    );
  }
}
