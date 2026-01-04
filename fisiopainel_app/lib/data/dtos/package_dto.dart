import '../../domain/models/package_model.dart';

class PackageDto {
  static PackageModel fromJson(Map<String, dynamic> json) {
    return PackageModel(
      id: json['id'],
      patientId: json['paciente'],
      serviceTypeId: json['tipo_atendimento'],
      quantity: json['quantidade_total'],
      // Converte string "1200.00" para double
      totalValue: double.parse(json['valor_total'].toString()),
      sessionValue: double.parse(json['valor_por_sessao'].toString()),
      status: json['status'] ?? 'ATIVO',
      paymentDate: json['data_pagamento'] != null
          ? DateTime.parse(json['data_pagamento'])
          : null,

      // Se a API mandar o nome expandido, pegamos aqui. Senão, fica null.
      patientName: json['paciente_nome'],
      serviceName: json['tipo_atendimento_nome'],
    );
  }

  static Map<String, dynamic> toJson(PackageModel model) {
    return {
      "paciente": model.patientId,
      "tipo_atendimento": model.serviceTypeId,
      "quantidade_total": model.quantity,
      "valor_total": model.totalValue.toStringAsFixed(
        2,
      ), // Envia como String "1200.00"
      "valor_por_sessao": model.sessionValue.toStringAsFixed(
        2,
      ), // Envia como String "120.00"
      "status": model.status,
      "data_pagamento": model.paymentDate?.toIso8601String(), // ISO 8601
    };
  }
}
