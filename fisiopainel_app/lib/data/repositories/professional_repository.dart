import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/models/professional_model.dart';
import '../dtos/professional_dto.dart';
import 'auth_repository.dart';

import '../../config/api_config.dart';

class ProfessionalRepository {
  final String baseUrl = "${ApiConfig.baseUrl}/users";

  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // --- LISTAR (GET) COM DIAGNÓSTICO ---
  Future<List<ProfessionalModel>> getProfessionals() async {
    try {
      var headers = await _getHeaders();
      print('--- DEBUG GET: Iniciando requisição para $baseUrl/ ---');

      var response = await http.get(Uri.parse('$baseUrl/'), headers: headers);

      // Tenta renovar token se der 401
      if (response.statusCode == 401) {
        print('--- DEBUG GET: Recebeu 401. Tentando refresh token... ---');
        final renewed = await AuthRepository().tryAutoLogin();
        if (renewed) {
          headers = await _getHeaders();
          response = await http.get(Uri.parse('$baseUrl/'), headers: headers);
        } else {
          print('--- DEBUG GET: Falha na renovação do token. ---');
        }
      }

      print('--- DEBUG GET: Status Code: ${response.statusCode} ---');
      print('--- DEBUG GET: Body Bruto: ${response.body} ---');

      if (response.statusCode == 200) {
        final dynamic decodedResponse = jsonDecode(
          utf8.decode(response.bodyBytes),
        );
        List<dynamic> listToMap;

        // TRATAMENTO DE PAGINAÇÃO DO DJANGO
        // Verifica se a resposta é um MAPA com a chave "results" (Padrão DRF)
        if (decodedResponse is Map && decodedResponse.containsKey('results')) {
          print('--- DEBUG GET: Detectada Paginação do Django ---');
          listToMap = decodedResponse['results'];
        }
        // Verifica se a resposta já é uma LISTA direta
        else if (decodedResponse is List) {
          print('--- DEBUG GET: Detectada Lista Direta ---');
          listToMap = decodedResponse;
        } else {
          print(
            '--- DEBUG GET: Formato desconhecido recebido: $decodedResponse ---',
          );
          return [];
        }

        // FILTRAGEM
        // Removemos o .where() para mostrar TODOS (Admin e Profissionais)
        try {
          final professionals = listToMap
              .map((json) => ProfessionalDto.fromJson(json))
              .toList();

          print('--- DEBUG GET: Total recuperado: ${professionals.length} ---');
          return professionals;
        } catch (e) {
          print('--- DEBUG GET: ERRO AO MAPEAR DTO: $e ---');
          rethrow;
        }
      } else {
        throw Exception('Erro ao carregar: ${response.statusCode}');
      }
    } catch (e) {
      print('--- DEBUG GET: ERRO CRÍTICO NO DART: $e ---');
      rethrow;
    }
  }

  // --- CRIAR (POST) ---
  Future<void> createProfessional(ProfessionalModel professional) async {
    var headers = await _getHeaders();
    final body = jsonEncode(ProfessionalDto.toJson(professional));

    print('--- DEBUG POST: Enviando dados: $body ---');

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

    if (response.statusCode == 201) {
      print('--- DEBUG POST: Sucesso! ---');
    } else {
      print(
        '--- DEBUG POST: Erro ${response.statusCode} | Msg: ${response.body} ---',
      );
      throw Exception('Falha ao criar: ${response.body}');
    }
  }

  // EDITAR (PUT)
  Future<void> updateProfessional(ProfessionalModel professional) async {
    if (professional.id == null) throw Exception('ID necessário para edição');

    var headers = await _getHeaders();
    final body = jsonEncode(ProfessionalDto.toJson(professional));
    final url = Uri.parse('$baseUrl/${professional.id}/'); // URL com ID

    print('--- DEBUG PUT: Atualizando ID ${professional.id} ---');

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

    print('--- DEBUG PATCH: Alterando ID $id para is_active: $newStatus ---');

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
