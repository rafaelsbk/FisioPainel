import '../../domain/models/audit_fields.dart';
import '../../domain/models/patient_model.dart';

class PatientDto {
  // Converte JSON da API -> Modelo Dart
  static PatientModel fromJson(Map<String, dynamic> json) {
    return PatientModel(
      id: json['id'],
      completeName: json['complete_name'],
      address: json['address'],
      cep: json['cep'],
      estado: json['estado'],
      cidade: json['cidade'],
      bairro: json['bairro'],
      numero: json['numero'],
      complemento: json['complemento'],
      email: json['email'],
      phoneNumber: json['numero_telefone'], // Mapeamento importante
      phones: (json['telefones'] as List?)
          ?.map((e) => PhoneModel(id: e['id'], number: e['numero']))
          .toList(),
      cpf: json['cpf'],
      rg: json['rg'],
      isActive: json['is_active'] ?? true,
      profissionalResponsavelId: json['profissional_responsavel'],
      audit: AuditFields.fromJson(json),
    );
  }

  // Converte Modelo Dart -> JSON para API (Create/Update)
  static Map<String, dynamic> toJson(PatientModel model) {
    final Map<String, dynamic> data = {
      "complete_name": model.completeName,
      "address": model.address,
      "cep": model.cep,
      "estado": model.estado,
      "cidade": model.cidade,
      "bairro": model.bairro,
      "numero": model.numero,
      "complemento": model.complemento,
      "email": model.email,
      "numero_telefone": model.phoneNumber,
      "cpf": model.cpf,
      "rg": model.rg,
      "is_active": model.isActive,
      "telefones": model.phones?.map((p) => {"numero": p.number}).toList(),
    };
    if (model.profissionalResponsavelId != null) {
      data["profissional_responsavel"] = model.profissionalResponsavelId;
    }
    return data;
  }
}
