import '../../domain/models/audit_fields.dart';
import '../../domain/models/package_model.dart';
import 'package:intl/intl.dart';

class PackageDto {
  static PackageModel fromJson(Map<String, dynamic> json) {
    return PackageModel(
      id: json['id'],
      patientId: json['paciente'],
      professionalId: json['profissional'],
      serviceTypeId: json['tipo_atendimento'],
      quantity: json['quantidade_total'],
      totalValue: double.parse(json['valor_total'].toString()),
      sessionValue: double.parse(json['valor_por_sessao'].toString()),
      status: json['status'],
      paymentDate: json['data_pagamento'] != null 
          ? DateTime.parse(json['data_pagamento']) 
          : null,
      startDate: json['data_inicio'] != null
          ? DateTime.parse(json['data_inicio'])
          : null,
      weekDays: json['dias_semana'],
      patientName: json['nome_paciente'],
      professionalName: json['nome_profissional'],
      serviceName: json['nome_atendimento'],
      audit: AuditFields.fromJson(json),
    );
  }

  static Map<String, dynamic> toJson(PackageModel model) {
    final DateFormat formatter = DateFormat('yyyy-MM-dd');
    return {
      "paciente": model.patientId,
      "profissional": model.professionalId,
      "tipo_atendimento": model.serviceTypeId,
      "quantidade_total": model.quantity,
      "valor_total": model.totalValue.toStringAsFixed(2),
      "valor_por_sessao": model.sessionValue.toStringAsFixed(2),
      "status": model.status,
      "data_pagamento": model.paymentDate?.toIso8601String(),
      "data_inicio": model.startDate != null ? formatter.format(model.startDate!) : null,
      "dias_semana": model.weekDays,
    };
  }
}
