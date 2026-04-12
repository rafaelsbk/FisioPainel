import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/storage_service.dart';
import '../../domain/models/appointment_model.dart';
import '../dtos/appointment_dto.dart';
import 'auth_repository.dart';

import '../../config/api_config.dart';

class AppointmentRepository {
  final String apiBase = ApiConfig.baseUrl;
  final StorageService _storage = StorageService();

  Future<Map<String, String>> _getHeaders() async {
    final token = await _storage.getAccessToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<List<AppointmentModel>> getAppointmentsForPackage(int packageId) async {
    var headers = await _getHeaders();
    var response = await http.get(
      Uri.parse('$apiBase/pacotes/$packageId/agendamentos/'),
      headers: headers,
    );

    if (response.statusCode == 401) {
      await AuthRepository().tryAutoLogin();
      headers = await _getHeaders();
      response = await http.get(
        Uri.parse('$apiBase/pacotes/$packageId/agendamentos/'),
        headers: headers,
      );
    }

    if (response.statusCode == 200) {
      final dynamic decoded = jsonDecode(utf8.decode(response.bodyBytes));
      final List list = (decoded is Map && decoded.containsKey('results')) 
          ? decoded['results'] 
          : decoded;
      return list.map((e) => AppointmentDto.fromJson(e)).toList();
    } else {
      throw Exception('Erro ao listar agendamentos para o pacote $packageId: ${response.statusCode} - ${response.body}');
    }
  }

  Future<List<AppointmentModel>> getAllAppointments() async {
    var headers = await _getHeaders();
    final url = Uri.parse('$apiBase/agendamentos/');
    
    var response = await http.get(url, headers: headers);

    if (response.statusCode == 401) {
      await AuthRepository().tryAutoLogin();
      headers = await _getHeaders();
      response = await http.get(url, headers: headers);
    }

    if (response.statusCode == 200) {
      final dynamic decoded = jsonDecode(utf8.decode(response.bodyBytes));
      final List list = (decoded is Map && decoded.containsKey('results')) 
          ? decoded['results'] 
          : decoded;
      return list.map((e) => AppointmentDto.fromJson(e)).toList();
    } else {
      throw Exception('Erro ao listar agendamentos: ${response.statusCode}');
    }
  }

  Future<AppointmentModel> createAppointment(AppointmentModel appointment) async {
    var headers = await _getHeaders();
    final body = jsonEncode(AppointmentDto.toJson(appointment));
    final url = Uri.parse('$apiBase/agendamentos/');

    var response = await http.post(url, headers: headers, body: body);

    if (response.statusCode == 401) {
      await AuthRepository().tryAutoLogin();
      headers = await _getHeaders();
      response = await http.post(url, headers: headers, body: body);
    }

    if (response.statusCode == 201) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      return AppointmentDto.fromJson(data);
    } else {
      throw Exception('Erro ao criar agendamento: ${response.body}');
    }
  }

  Future<AppointmentModel> updateAppointment(AppointmentModel appointment) async {
    var headers = await _getHeaders();
    final body = jsonEncode(AppointmentDto.toJson(appointment));
    final url = Uri.parse('$apiBase/agendamentos/${appointment.id}/');

    var response = await http.patch(url, headers: headers, body: body);

    if (response.statusCode == 401) {
      await AuthRepository().tryAutoLogin();
      headers = await _getHeaders();
      response = await http.patch(url, headers: headers, body: body);
    }

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      return AppointmentDto.fromJson(data);
    } else {
      throw Exception('Erro ao atualizar agendamento: ${response.body}');
    }
  }

  Future<void> createAppointmentsForPackage(int packageId) async {
    var headers = await _getHeaders();
    final url = Uri.parse('$apiBase/pacotes/$packageId/criar-agendamentos/');

    var response = await http.post(url, headers: headers);

    if (response.statusCode == 401) {
      await AuthRepository().tryAutoLogin();
      headers = await _getHeaders();
      response = await http.post(url, headers: headers);
    }

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Erro ao criar agendamentos para o pacote $packageId: ${response.body}');
    }
  }
}

