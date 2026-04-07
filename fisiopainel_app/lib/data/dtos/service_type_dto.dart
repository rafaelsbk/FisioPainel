// lib/data/dtos/service_type_dto.dart
import '../../domain/models/service_type_model.dart';

class ServiceTypeDto {
  static ServiceTypeModel fromJson(Map<String, dynamic> json) {
    return ServiceTypeModel(
      id: json['id'],
      name: json['nome_atendimento'] ?? json['nome'] ?? json['description'] ?? 'Sem Nome',
      isActive: json['ativo'] ?? true,
    );
  }

  static Map<String, dynamic> toJson(String name, bool isActive) {
    return {
      'nome_atendimento': name,
      'ativo': isActive,
    };
  }
}
