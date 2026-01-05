import 'audit_fields.dart';

class ServiceTypeModel {
  final int id;
  final String name; // Padronizado como 'name'
  final AuditFields? audit;

  ServiceTypeModel({required this.id, required this.name, this.audit});

  // Se você tiver o factory aqui dentro, remova-o e use o DTO,
  // ou garanta que ele usa 'name':
  factory ServiceTypeModel.fromJson(Map<String, dynamic> json) {
    return ServiceTypeModel(
      id: json['id'],
      name:
          json['nome_atendimento'] ?? json['nome'] ?? 'Sem Nome', // Mapeia 'nome_atendimento' ou 'nome'
      audit: AuditFields.fromJson(json),
    );
  }
}
