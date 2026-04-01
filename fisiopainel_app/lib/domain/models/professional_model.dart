import 'audit_fields.dart';
import 'user_role_model.dart';

class ProfessionalModel {
  final int? id;
  final String username;
  final String? password; // Usado apenas na criação
  final String firstName;
  final String lastName;
  final String email;
  final String phoneNumber; // Mapeia para telepone_number
  final String cpf;
  final String crefito;
  final UserRoleModel? usersRoles;
  final double? percentualRepasse;
  final double? valorRepasseFixo;
  final bool isActive;
  final AuditFields? audit;

  ProfessionalModel({
    this.id,
    required this.username,
    this.password,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phoneNumber,
    required this.cpf,
    required this.crefito,
    this.usersRoles,
    this.percentualRepasse,
    this.valorRepasseFixo,
    this.isActive = true,
    this.audit,
  });

  // Getter auxiliar para exibir nome completo
  String get fullName => "$firstName $lastName";
}
