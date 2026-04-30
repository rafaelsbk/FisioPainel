import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/storage_service.dart';
import '../../domain/models/service_type_model.dart';
import '../dtos/service_type_dto.dart';
import 'auth_repository.dart';

import '../../config/api_config.dart';

class ServiceTypeRepository {
  final String apiBase = "${ApiConfig.baseUrl}/tipos-atendimento";
  final StorageService _storage = StorageService();

  Future<Map<String, String>> _getHeaders() async {
    final token = await _storage.getAccessToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<List<ServiceTypeModel>> getServiceTypes() async {
    var headers = await _getHeaders();
    var response = await http.get(Uri.parse('$apiBase/'), headers: headers);

    if (response.statusCode == 401) {
      await AuthRepository().tryAutoLogin();
      headers = await _getHeaders();
      response = await http.get(Uri.parse('$apiBase/'), headers: headers);
    }

    if (response.statusCode == 200) {
      final dynamic decoded = jsonDecode(utf8.decode(response.bodyBytes));
      final List list = (decoded is Map && decoded.containsKey('results'))
          ? decoded['results']
          : decoded;
      return list.map((e) => ServiceTypeDto.fromJson(e)).toList();
    }
    return [];
  }

  Future<void> createServiceType(String name, String color) async {
    var headers = await _getHeaders();
    final body = jsonEncode(ServiceTypeDto.toJson(name, color, true));

    var response = await http.post(Uri.parse('$apiBase/'), headers: headers, body: body);

    if (response.statusCode == 401) {
      await AuthRepository().tryAutoLogin();
      headers = await _getHeaders();
      response = await http.post(Uri.parse('$apiBase/'), headers: headers, body: body);
    }

    if (response.statusCode != 201) {
      throw Exception('Erro ao criar tipo: ${response.body}');
    }
  }

  Future<void> updateServiceType(int id, String name, String color, bool isActive) async {
    var headers = await _getHeaders();
    final body = jsonEncode(ServiceTypeDto.toJson(name, color, isActive));

    var response = await http.put(Uri.parse('$apiBase/$id/'), headers: headers, body: body);

    if (response.statusCode == 401) {
      await AuthRepository().tryAutoLogin();
      headers = await _getHeaders();
      response = await http.put(Uri.parse('$apiBase/$id/'), headers: headers, body: body);
    }

    if (response.statusCode != 200) {
      throw Exception('Erro ao atualizar tipo: ${response.body}');
    }
  }

  Future<void> deleteServiceType(int id) async {
    var headers = await _getHeaders();
    var response = await http.delete(Uri.parse('$apiBase/$id/'), headers: headers);

    if (response.statusCode == 401) {
      await AuthRepository().tryAutoLogin();
      headers = await _getHeaders();
      response = await http.delete(Uri.parse('$apiBase/$id/'), headers: headers);
    }

    if (response.statusCode != 204) {
      throw Exception('Erro ao deletar tipo');
    }
  }
}
