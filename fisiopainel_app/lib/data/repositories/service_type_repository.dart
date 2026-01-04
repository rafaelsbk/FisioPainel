import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/models/service_type_model.dart';
import '../dtos/service_type_dto.dart';
import 'auth_repository.dart';

class ServiceTypeRepository {
  final String apiBase = "http://127.0.0.1:8000/api/tipos-atendimento";

  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
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

  Future<void> createServiceType(String name) async {
    var headers = await _getHeaders();
    // Using 'nome_atendimento' as per Django model
    final body = jsonEncode({"nome_atendimento": name});

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
