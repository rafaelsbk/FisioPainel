import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/storage_service.dart';
import '../../domain/models/patient_model.dart';
import '../dtos/patient_dto.dart';
import 'auth_repository.dart';

import '../../config/api_config.dart';

class PatientRepository {
  final String baseUrl = "${ApiConfig.baseUrl}/pacientes";
  final StorageService _storage = StorageService();

  // Helper para pegar headers com Token
  Future<Map<String, String>> _getHeaders() async {
    final token = await _storage.getAccessToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // LISTAR (GET) com Retry Automático
  Future<List<PatientModel>> getPatients() async {
    final headers = await _getHeaders();
    var response = await http.get(Uri.parse('$baseUrl/'), headers: headers);

    // --- LÓGICA DE REFRESH ---
    if (response.statusCode == 401) {
      final authRepo = AuthRepository();
      final refreshed = await authRepo.tryAutoLogin();

      if (refreshed) {
        // Pega os headers novos (com o token novo)
        final newHeaders = await _getHeaders();
        // Tenta a requisição de novo
        response = await http.get(Uri.parse('$baseUrl/'), headers: newHeaders);
      }
    }
    // -------------------------

    if (response.statusCode == 200) {
      final List<dynamic> body = jsonDecode(utf8.decode(response.bodyBytes));
      return body.map((json) => PatientDto.fromJson(json)).toList();
    } else if (response.statusCode == 401) {
      // Se ainda for 401, é porque o refresh falhou (logou em outro lugar ou passou muito tempo)
      throw Exception('Sessão expirada. Por favor, faça login novamente.');
    } else {
      throw Exception('Erro ao carregar pacientes: ${response.statusCode}');
    }
  }

  // CRIAR (POST)
  Future<void> createPatient(PatientModel patient) async {
    final headers = await _getHeaders();
    final body = jsonEncode(PatientDto.toJson(patient));

    final response = await http.post(
      Uri.parse('$baseUrl/'),
      headers: headers,
      body: body,
    );

    if (response.statusCode != 201) {
      throw Exception('Erro ao criar: ${response.body}');
    }
  }

  // EDITAR (PUT)
  Future<void> updatePatient(PatientModel patient) async {
    if (patient.id == null) throw Exception('ID necessário para edição');

    final headers = await _getHeaders();
    final body = jsonEncode(PatientDto.toJson(patient));
    final url = '$baseUrl/${patient.id}/'; // URL com ID

    final response = await http.put(
      Uri.parse(url),
      headers: headers,
      body: body,
    );

    if (response.statusCode != 200) {
      throw Exception('Erro ao editar: ${response.body}');
    }
  }
}
