import 'audit_fields.dart';

class PatientModel {
  final int? id; // Pode ser nulo na criação
  final String completeName; // No Django é complete_name
  final String? address;
  final String? email;
  final String? phoneNumber; // No Django é numero_telefone
  final String? cpf;
  final String? rg;
  final int? profissionalResponsavelId;
  final AuditFields? audit;

  PatientModel({
    this.id,
    required this.completeName,
    this.address,
    this.email,
    this.phoneNumber,
    this.cpf,
    this.rg,
    this.profissionalResponsavelId,
    this.audit,
  });
}
