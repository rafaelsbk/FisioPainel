import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/models/patient_model.dart';
import '../dtos/patient_dto.dart';
import 'auth_repository.dart';

class PatientRepository {
  // Ajuste o IP conforme seu ambiente (10.0.2.2 Android, 127.0.0.1 Web)
  final String baseUrl = "http://127.0.0.1:8000/api/pacientes";

  // Helper para pegar headers com Token
  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
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
      print('Token expirado (401). Tentando renovar...');

      final authRepo = AuthRepository();
      final refreshed = await authRepo.tryAutoLogin();

      if (refreshed) {
        print('Token renovado! Tentando a requisição novamente...');
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
