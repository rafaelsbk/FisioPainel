import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../dtos/appointment_dto.dart';
import '../../domain/models/appointment_model.dart';
import 'auth_repository.dart';

class ReportRepository {
  final String apiBase = "http://127.0.0.1:8000/api";

  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<Map<String, dynamic>> getProfessionalReport(int professionalId, DateTime start, DateTime end) async {
    var headers = await _getHeaders();
    
    final startStr = "${start.year}-${start.month.toString().padLeft(2,'0')}-${start.day.toString().padLeft(2,'0')}";
    final endStr = "${end.year}-${end.month.toString().padLeft(2,'0')}-${end.day.toString().padLeft(2,'0')}";

    final url = Uri.parse('$apiBase/relatorios/profissional/?profissional_id=$professionalId&start_date=$startStr&end_date=$endStr');

    var response = await http.get(url, headers: headers);

    if (response.statusCode == 401) {
      await AuthRepository().tryAutoLogin();
      headers = await _getHeaders();
      response = await http.get(url, headers: headers);
    }

    if (response.statusCode == 200) {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      
      final List apptListRaw = decoded['agendamentos'];
      final List<AppointmentModel> appointments = apptListRaw.map((e) => AppointmentDto.fromJson(e)).toList();
      
      return {
        'appointments': appointments,
        'summary': decoded['resumo']
      };
    } else {
      throw Exception('Erro ao gerar relatório: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> getFinancialReport(int professionalId, DateTime start, DateTime end) async {
    var headers = await _getHeaders();
    
    final startStr = "${start.year}-${start.month.toString().padLeft(2,'0')}-${start.day.toString().padLeft(2,'0')}";
    final endStr = "${end.year}-${end.month.toString().padLeft(2,'0')}-${end.day.toString().padLeft(2,'0')}";

    final url = Uri.parse('$apiBase/relatorios/financeiro/?profissional_id=$professionalId&start_date=$startStr&end_date=$endStr');

    var response = await http.get(url, headers: headers);

    if (response.statusCode == 401) {
      await AuthRepository().tryAutoLogin();
      headers = await _getHeaders();
      response = await http.get(url, headers: headers);
    }

    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } else {
      throw Exception('Erro ao gerar relatório financeiro: ${response.body}');
    }
  }
}
