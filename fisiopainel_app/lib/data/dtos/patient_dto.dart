import '../../domain/models/patient_model.dart';

class PatientDto {
  // Converte JSON da API -> Modelo Dart
  static PatientModel fromJson(Map<String, dynamic> json) {
    return PatientModel(
      id: json['id'],
      completeName: json['complete_name'],
      address: json['address'],
      email: json['email'],
      phoneNumber: json['numero_telefone'], // Mapeamento importante
      cpf: json['cpf'],
      rg: json['rg'],
    );
  }

  // Converte Modelo Dart -> JSON para API (Create/Update)
  static Map<String, dynamic> toJson(PatientModel model) {
    return {
      "complete_name": model.completeName,
      "address": model.address,
      "email": model.email,
      "numero_telefone": model.phoneNumber,
      "cpf": model.cpf,
      "rg": model.rg,
    };
  }
}
