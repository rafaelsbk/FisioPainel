import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/storage_service.dart';
import '../../domain/models/package_model.dart';
import '../../domain/models/service_type_model.dart';
import '../dtos/package_dto.dart';
import '../dtos/service_type_dto.dart';
import 'auth_repository.dart';

import '../../config/api_config.dart';

class PackageRepository {
  // Base da API (sem o endpoint final)
  final String apiBase = ApiConfig.baseUrl;
  final StorageService _storage = StorageService();

  Future<Map<String, String>> _getHeaders() async {
    final token = await _storage.getAccessToken();
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
    var response = await http.get(
      Uri.parse('$apiBase/tipos-atendimento/'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final dynamic decoded = jsonDecode(utf8.decode(response.bodyBytes));
      final List list = (decoded is Map && decoded.containsKey('results'))
          ? decoded['results']
          : decoded;
      return list.map((e) => ServiceTypeDto.fromJson(e)).toList();
    }
    return [];
  }

  // 3. CRIAR PACOTE
  Future<PackageModel> createPackage(PackageModel package) async {
    var headers = await _getHeaders();
    final body = jsonEncode(PackageDto.toJson(package));

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

    if (response.statusCode == 201) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      return PackageDto.fromJson(data);
    } else {
      throw Exception('Erro ao criar: ${response.body}');
    }
  }

  // 4. ATUALIZAR PACOTE
  Future<void> updatePackage(PackageModel package) async {
    var headers = await _getHeaders();
    final body = jsonEncode(PackageDto.toJson(package));
    final url = Uri.parse('$apiBase/pacotes/${package.id}/');

    var response = await http.patch( // Usar PATCH para atualizações parciais
      url,
      headers: headers,
      body: body,
    );

    if (response.statusCode == 401) {
      await AuthRepository().tryAutoLogin();
      headers = await _getHeaders();
      response = await http.patch(
        url,
        headers: headers,
        body: body,
      );
    }
    
    if (response.statusCode != 200) {
      final errorData = jsonDecode(utf8.decode(response.bodyBytes));
      if (errorData is Map && errorData.containsKey('quantidade_total')) {
        throw Exception(errorData['quantidade_total'][0]);
      }
      throw Exception('Erro ao atualizar o pacote');
    }
  }

  // 5. DELETAR PACOTE
  Future<void> deletePackage(int id) async {
    var headers = await _getHeaders();
    final url = Uri.parse('$apiBase/pacotes/$id/');

    var response = await http.delete(url, headers: headers);

    if (response.statusCode == 401) {
      await AuthRepository().tryAutoLogin();
      headers = await _getHeaders();
      response = await http.delete(url, headers: headers);
    }

    if (response.statusCode != 204) {
      throw Exception('Erro ao deletar o pacote');
    }
  }
}
