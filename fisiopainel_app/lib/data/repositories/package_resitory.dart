import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/models/package_model.dart';
import '../../domain/models/service_type_model.dart';
import '../dtos/package_dto.dart';
import 'auth_repository.dart';

class PackageRepository {
  // Base da API (sem o endpoint final)
  final String apiBase = "http://127.0.0.1:8000/api";

  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // 1. LISTAR PACOTES
  Future<List<PackageModel>> getPackages() async {
    var headers = await _getHeaders();
    var response = await http.get(
      Uri.parse('$apiBase/pacotes/'),
      headers: headers,
    );

    if (response.statusCode == 401) {
      await AuthRepository().tryAutoLogin();
      headers = await _getHeaders();
      response = await http.get(
        Uri.parse('$apiBase/pacotes/'),
        headers: headers,
      );
    }

    if (response.statusCode == 200) {
      final dynamic decoded = jsonDecode(utf8.decode(response.bodyBytes));
      // Tratamento genérico para paginação ou lista direta
      final List list = (decoded is Map && decoded.containsKey('results'))
          ? decoded['results']
          : decoded;
      return list.map((e) => PackageDto.fromJson(e)).toList();
    } else {
      throw Exception('Erro ao listar pacotes');
    }
  }

  // 2. LISTAR TIPOS DE ATENDIMENTO (Para o Dropdown)
  Future<List<ServiceTypeModel>> getServiceTypes() async {
    var headers = await _getHeaders();
    // Ajuste aqui se a URL for diferente de 'tipos-atendimento'
    var response = await http.get(
      Uri.parse('$apiBase/tipos-atendimento/'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final dynamic decoded = jsonDecode(utf8.decode(response.bodyBytes));
      final List list = (decoded is Map && decoded.containsKey('results'))
          ? decoded['results']
          : decoded;
      return list.map((e) => ServiceTypeModel.fromJson(e)).toList();
    }
    return [];
  }

  // 3. CRIAR PACOTE
  Future<void> createPackage(PackageModel package) async {
    var headers = await _getHeaders();
    final body = jsonEncode(PackageDto.toJson(package));

    print('--- Enviando Pacote: $body ---'); // Debug

    var response = await http.post(
      Uri.parse('$apiBase/pacotes/'),
      headers: headers,
      body: body,
    );

    if (response.statusCode == 401) {
      await AuthRepository().tryAutoLogin();
      headers = await _getHeaders();
      response = await http.post(
        Uri.parse('$apiBase/pacotes/'),
        headers: headers,
        body: body,
      );
    }

    if (response.statusCode != 201) {
      throw Exception('Erro ao criar: ${response.body}');
    }
  }
}
