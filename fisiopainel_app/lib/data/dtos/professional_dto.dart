import '../../domain/models/audit_fields.dart';
import '../../domain/models/professional_model.dart';
import '../../domain/models/user_role_model.dart';

class ProfessionalDto {
  static ProfessionalModel fromJson(Map<String, dynamic> json) {
    return ProfessionalModel(
      id: json['id'],
      username: json['username'] ?? '', // Garante que não quebre se vier null
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      email: json['email'] ?? '',
      isActive: json['is_active'] ?? true,
      // Tratamento especial: Se vier NULL, coloca string vazia
      phoneNumber: json['telepone_number'] ?? '',
      cpf: json['cpf'] ?? '',
      crefito: json['crefito'] ?? '',
      usersRoles: json['users_roles'] != null
          ? UserRoleModel.fromJson(json['users_roles'])
          : null,
      audit: AuditFields.fromJson(json),

      percentualRepasse: json['percentual_repasse'] != null
          ? double.tryParse(json['percentual_repasse'].toString())
          : null,
      valorRepasseFixo: json['valor_repasse_fixo'] != null
          ? double.tryParse(json['valor_repasse_fixo'].toString())
          : null,
      percentualTaxaReposicao: json['percentual_taxa_reposicao'] != null
          ? double.tryParse(json['percentual_taxa_reposicao'].toString())
          : null,
      valorTaxaReposicaoFixo: json['valor_taxa_reposicao_fixo'] != null
          ? double.tryParse(json['valor_taxa_reposicao_fixo'].toString())
          : null,
    );
  }

  // Dart -> JSON
  static Map<String, dynamic> toJson(ProfessionalModel model) {
    final Map<String, dynamic> data = {
      "username": model.username,
      "email": model.email,
      "first_name": model.firstName,
      "last_name": model.lastName,
      "users_roles_id": model.usersRoles?.id,
      "telepone_number": model.phoneNumber, // Mantendo o typo da API
      "cpf": model.cpf,
      "crefito": model.crefito,
      "percentual_repasse": model.percentualRepasse?.toStringAsFixed(2),
      "valor_repasse_fixo": model.valorRepasseFixo?.toStringAsFixed(2),
      "percentual_taxa_reposicao": model.percentualTaxaReposicao?.toStringAsFixed(2),
      "valor_taxa_reposicao_fixo": model.valorTaxaReposicaoFixo?.toStringAsFixed(2),
    };

    // Só envia senha se ela existir (Criação)
    if (model.password != null && model.password!.isNotEmpty) {
      data["password"] = model.password;
    }

    return data;
  }
}
