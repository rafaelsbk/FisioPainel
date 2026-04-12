import 'audit_fields.dart';

class PhoneModel {
  final int? id;
  final String number;

  PhoneModel({this.id, required this.number});
}

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
  final String? phoneNumber; // Mantemos por compatibilidade, mas o foco será na lista
  final List<PhoneModel>? phones;
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
    this.phones,
    this.cpf,
    this.rg,
    this.isActive = true,
    this.profissionalResponsavelId,
    this.audit,
  });
}
