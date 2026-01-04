// lib/domain/models/service_type_model.dart

class ServiceTypeModel {
  final int id;
  final String name; // Padronizado como 'name'

  ServiceTypeModel({required this.id, required this.name});

  // Se você tiver o factory aqui dentro, remova-o e use o DTO,
  // ou garanta que ele usa 'name':
  factory ServiceTypeModel.fromJson(Map<String, dynamic> json) {
    return ServiceTypeModel(
      id: json['id'],
      name:
          json['nome'] ?? 'Sem Nome', // Mapeia 'nome' (JSON) para 'name' (Dart)
    );
  }
}
