import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';

enum CaminhaoStatus { livre, emCarga, emRota }

extension CaminhaoStatusLabel on CaminhaoStatus {
  String get label {
    switch (this) {
      case CaminhaoStatus.livre:
        return 'Livre';
      case CaminhaoStatus.emCarga:
        return 'Em carga';
      case CaminhaoStatus.emRota:
        return 'Em rota';
    }
  }

  /// Color used to represent this status in badges/chips (livre = sucesso,
  /// emCarga = atenção, emRota = neutro/info) — reuses tokens already
  /// defined in [AppColors] rather than introducing new ones.
  Color get color {
    switch (this) {
      case CaminhaoStatus.livre:
        return AppColors.success;
      case CaminhaoStatus.emCarga:
        return AppColors.primaryContainer;
      case CaminhaoStatus.emRota:
        return AppColors.tertiary;
    }
  }

  /// The raw string this status is sent/received as over the API
  /// (e.g. `POST /caminhoes/{id}/status`), mirroring [caminhaoStatusFromString].
  String get apiValue {
    switch (this) {
      case CaminhaoStatus.livre:
        return 'LIVRE';
      case CaminhaoStatus.emCarga:
        return 'EM_CARGA';
      case CaminhaoStatus.emRota:
        return 'EM_ROTA';
    }
  }
}

/// Parses the `status` column (e.g. "LIVRE", "EM_CARGA", "EM_ROTA") returned
/// by GET /caminhoes, defaulting to [CaminhaoStatus.livre] for unknown or
/// null values.
CaminhaoStatus caminhaoStatusFromString(String? raw) {
  switch (raw?.trim().toUpperCase()) {
    case 'EM_CARGA':
      return CaminhaoStatus.emCarga;
    case 'EM_ROTA':
      return CaminhaoStatus.emRota;
    case 'LIVRE':
    default:
      return CaminhaoStatus.livre;
  }
}

class Caminhao {
  final int idCaminhao;
  final String placa;
  final String? modelo;
  final CaminhaoStatus status;
  final String? motorista;

  const Caminhao({
    required this.idCaminhao,
    required this.placa,
    this.modelo,
    required this.status,
    this.motorista,
  });

  factory Caminhao.fromJson(Map<String, dynamic> json) {
    return Caminhao(
      idCaminhao: json['id_caminhao'] as int,
      placa: json['placa'] as String,
      modelo: json['modelo'] as String?,
      status: caminhaoStatusFromString(json['status'] as String?),
      motorista: json['motorista'] as String?,
    );
  }

  Caminhao copyWith({CaminhaoStatus? status}) {
    return Caminhao(
      idCaminhao: idCaminhao,
      placa: placa,
      modelo: modelo,
      status: status ?? this.status,
      motorista: motorista,
    );
  }
}
