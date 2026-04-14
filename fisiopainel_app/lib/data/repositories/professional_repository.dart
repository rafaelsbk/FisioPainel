import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/storage_service.dart';
import '../../domain/models/professional_model.dart';
import '../dtos/professional_dto.dart';
import 'auth_repository.dart';

import '../../config/api_config.dart';

class ProfessionalRepository {
  final String baseUrl = "${ApiConfig.baseUrl}/users";
  final StorageService _storage = StorageService();

  Future<Map<String, String>> _getHeaders() async {
    final token = await _storage.getAccessToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // --- LISTAR (GET) COM DIAGNÓSTICO ---
  Future<List<ProfessionalModel>> getProfessionals() async {
    try {
      var headers = await _getHeaders();

      var response = await http.get(Uri.parse('$baseUrl/'), headers: headers);

      // Tenta renovar token se der 401
      if (response.statusCode == 401) {
        final renewed = await AuthRepository().tryAutoLogin();
        if (renewed) {
          headers = await _getHeaders();
          response = await http.get(Uri.parse('$baseUrl/'), headers: headers);
        }
      }

      if (response.statusCode == 200) {
        final dynamic decodedResponse = jsonDecode(
          utf8.decode(response.bodyBytes),
        );
        List<dynamic> listToMap;

        // TRATAMENTO DE PAGINAÇÃO DO DJANGO
        // Verifica se a resposta é um MAPA com a chave "results" (Padrão DRF)
        if (decodedResponse is Map && decodedResponse.containsKey('results')) {
          listToMap = decodedResponse['results'];
        }
        // Verifica se a resposta já é uma LISTA direta
        else if (decodedResponse is List) {
          listToMap = decodedResponse;
        } else {
          return [];
        }

        // FILTRAGEM
        // Removemos o .where() para mostrar TODOS (Admin e Profissionais)
        try {
          final professionals = listToMap
              .map((json) => ProfessionalDto.fromJson(json))
              .toList();

          return professionals;
        } catch (e) {
          rethrow;
        }
      } else {
        throw Exception('Erro ao carregar: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  // --- CRIAR (POST) ---
  Future<void> createProfessional(ProfessionalModel professional) async {
    var headers = await _getHeaders();
    final body = jsonEncode(ProfessionalDto.toJson(professional));

    var response = await http.post(
      Uri.parse('$baseUrl/'),
      headers: headers,
      body: body,
    );

    if (response.statusCode == 401) {
      final renewed = await AuthRepository().tryAutoLogin();
      if (renewed) {
        headers = await _getHeaders();
        response = await http.post(
          Uri.parse('$baseUrl/'),
          headers: headers,
          body: body,
        );
      }
    }

    if (response.statusCode != 201) {
      throw Exception('Falha ao criar: ${response.body}');
    }
  }

  // EDITAR (PUT)
  Future<void> updateProfessional(ProfessionalModel professional) async {
    if (professional.id == null) throw Exception('ID necessário para edição');

    var headers = await _getHeaders();
    final body = jsonEncode(ProfessionalDto.toJson(professional));
    final url = Uri.parse('$baseUrl/${professional.id}/'); // URL com ID

    var response = await http.put(url, headers: headers, body: body);

    // Lógica de Refresh Token
    if (response.statusCode == 401) {
      final renewed = await AuthRepository().tryAutoLogin();
      if (renewed) {
        headers = await _getHeaders();
        response = await http.put(url, headers: headers, body: body);
      }
    }

    if (response.statusCode != 200) {
      throw Exception('Erro ao editar: ${response.body}');
    }
  }

  // ALTERAR STATUS (Soft Delete)
  Future<void> toggleStatus(int id, bool newStatus) async {
    var headers = await _getHeaders();

    // Envia apenas o campo que mudou
    final body = jsonEncode({"is_active": newStatus});
    final url = Uri.parse('$baseUrl/$id/');

    var response = await http.patch(url, headers: headers, body: body);

    // Lógica de Refresh Token
    if (response.statusCode == 401) {
      final renewed = await AuthRepository().tryAutoLogin();
      if (renewed) {
        headers = await _getHeaders();
        response = await http.patch(url, headers: headers, body: body);
      }
    }

    if (response.statusCode != 200) {
      throw Exception('Erro ao alterar status: ${response.body}');
    }
  }
}
