import '../../domain/models/appointment_model.dart';
import '../../domain/models/audit_fields.dart';

class AppointmentDto {
  static AppointmentModel fromJson(Map<String, dynamic> json) {
    return AppointmentModel(
      id: json['id'],
      packageId: json['pacote'],
      dateTime: json['data_hora'] != null ? DateTime.parse(json['data_hora']) : null,
      status: json['status'],
      professionalId: json['profissional'],
      professionalName: json['nome_profissional'],
      patientName: json['nome_paciente'],
      sessionProgress: json['progresso_sessao'],
      packageTotalValue: json['valor_total_pacote'],
      audit: AuditFields.fromJson(json),
    );
  }

  static Map<String, dynamic> toJson(AppointmentModel model) {
    return {
      "pacote": model.packageId,
      "data_hora": model.dateTime?.toIso8601String(),
      "status": model.status,
      "profissional": model.professionalId,
    };
  }
}
