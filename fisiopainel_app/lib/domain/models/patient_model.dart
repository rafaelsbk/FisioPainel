import 'audit_fields.dart';

class PatientModel {
  final int? id; // Pode ser nulo na criação
  final String completeName; // No Django é complete_name
  final String? address;
  final String? cep;
  final String? estado;
  final String? cidade;
  final String? bairro;
  final String? numero;
  final String? complemento;
  final String? email;
  final String? phoneNumber; // No Django é numero_telefone
  final String? cpf;
  final String? rg;
  final bool isActive;
  final int? profissionalResponsavelId;
  final AuditFields? audit;

  PatientModel({
    this.id,
    required this.completeName,
    this.address,
    this.cep,
    this.estado,
    this.cidade,
    this.bairro,
    this.numero,
    this.complemento,
    this.email,
    this.phoneNumber,
    this.cpf,
    this.rg,
    this.isActive = true,
    this.profissionalResponsavelId,
    this.audit,
  });
}
