import 'audit_fields.dart';

class AppointmentModel {
  final int id;
  final int packageId;
  final DateTime? dateTime;
  final String status;
  final int? professionalId;
  final String? professionalName;
  final String? patientName;
  final String? sessionProgress;
  final String? packageTotalValue;
  final AuditFields? audit;

  AppointmentModel({
    required this.id,
    required this.packageId,
    this.dateTime,
    required this.status,
    this.professionalId,
    this.professionalName,
    this.patientName,
    this.sessionProgress,
    this.packageTotalValue,
    this.audit,
  });
}
