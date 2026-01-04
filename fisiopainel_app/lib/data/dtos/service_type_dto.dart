// lib/data/dtos/service_type_dto.dart
import '../../domain/models/service_type_model.dart';

class ServiceTypeDto {
  static ServiceTypeModel fromJson(Map<String, dynamic> json) {
    return ServiceTypeModel(
      id: json['id'],
      // CORREÇÃO AQUI:
      // O parâmetro do Model é 'name'
      // O valor que vem da API é json['nome']
      name: json['nome'] ?? json['description'] ?? 'Sem Nome',
    );
  }
}
