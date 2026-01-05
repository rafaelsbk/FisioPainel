import 'audit_fields.dart';

class AppointmentModel {
  final int id;
  final int packageId;
  final DateTime? dateTime;
  final String status;
  final int? professionalId;
  final String? professionalName;
  final AuditFields? audit;

  AppointmentModel({
    required this.id,
    required this.packageId,
    this.dateTime,
    required this.status,
    this.professionalId,
    this.professionalName,
    this.audit,
  });

  factory AppointmentModel.fromJson(Map<String, dynamic> json) {
    return AppointmentModel(
      id: json['id'],
      packageId: json['pacote'],
      dateTime: json['data_hora'] != null ? DateTime.parse(json['data_hora']) : null,
      status: json['status'],
      professionalId: json['profissional'],
      // Assuming the API might send professional's name directly
      professionalName: json['nome_profissional'],
      audit: AuditFields.fromJson(json),
    );
  }
}
