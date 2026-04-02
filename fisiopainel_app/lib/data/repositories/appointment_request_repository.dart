import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/models/appointment_request_model.dart';
import '../dtos/appointment_request_dto.dart';
import 'auth_repository.dart';

import '../../config/api_config.dart';

class AppointmentRequestRepository {
  final String apiBase = ApiConfig.baseUrl;

  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<List<AppointmentRequestModel>> getRequests() async {
    var headers = await _getHeaders();
    var response = await http.get(
      Uri.parse('$apiBase/solicitacoes-agendamento/'),
      headers: headers,
    );

    if (response.statusCode == 401) {
      await AuthRepository().tryAutoLogin();
      headers = await _getHeaders();
      response = await http.get(
        Uri.parse('$apiBase/solicitacoes-agendamento/'),
        headers: headers,
      );
    }

    if (response.statusCode == 200) {
      final dynamic decoded = jsonDecode(utf8.decode(response.bodyBytes));
      final List list = (decoded is Map && decoded.containsKey('results')) 
          ? decoded['results'] 
          : decoded;
      return list.map((e) => AppointmentRequestDto.fromJson(e)).toList();
    } else {
      throw Exception('Erro ao listar solicitações: ${response.statusCode}');
    }
  }

  Future<void> createRequest(AppointmentRequestModel request) async {
    var headers = await _getHeaders();
    final body = jsonEncode(AppointmentRequestDto.toJson(request));
    final url = Uri.parse('$apiBase/solicitacoes-agendamento/');

    var response = await http.post(url, headers: headers, body: body);

    if (response.statusCode == 401) {
      await AuthRepository().tryAutoLogin();
      headers = await _getHeaders();
      response = await http.post(url, headers: headers, body: body);
    }

    if (response.statusCode != 201) {
      throw Exception('Erro ao criar solicitação: ${response.body}');
    }
  }

  Future<void> respondRequest(int id, String action) async {
    // action: 'ACEITAR' or 'RECUSAR'
    var headers = await _getHeaders();
    final body = jsonEncode({'acao': action});
    final url = Uri.parse('$apiBase/solicitacoes-agendamento/$id/responder/');

    var response = await http.post(url, headers: headers, body: body);

    if (response.statusCode == 401) {
      await AuthRepository().tryAutoLogin();
      headers = await _getHeaders();
      response = await http.post(url, headers: headers, body: body);
    }

    if (response.statusCode != 200) {
      throw Exception('Erro ao responder solicitação: ${response.body}');
    }
  }

  Future<int> getUnreadCount() async {
    var headers = await _getHeaders();
    final url = Uri.parse('$apiBase/solicitacoes-agendamento/count_unread/');

    var response = await http.get(url, headers: headers);

    if (response.statusCode == 401) {
      await AuthRepository().tryAutoLogin();
      headers = await _getHeaders();
      response = await http.get(url, headers: headers);
    }

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      return data['count'];
    } else {
      // Falha silenciosa ou retorno 0 para nao quebrar a UI de badge
      print('Erro ao buscar contagem: ${response.body}');
      return 0;
    }
  }

  Future<void> markAsRead() async {
    var headers = await _getHeaders();
    final url = Uri.parse('$apiBase/solicitacoes-agendamento/mark_as_read/');

    var response = await http.post(url, headers: headers);

    if (response.statusCode == 401) {
      await AuthRepository().tryAutoLogin();
      headers = await _getHeaders();
      response = await http.post(url, headers: headers);
    }
    
    // Nao precisamos lançar erro se falhar, apenas logar
    if (response.statusCode != 200) {
       print('Erro ao marcar como lido: ${response.body}');
    }
  }

  Future<void> clearAttended() async {
    var headers = await _getHeaders();
    final url = Uri.parse('$apiBase/solicitacoes-agendamento/limpar_atendidas/');

    var response = await http.post(url, headers: headers);

    if (response.statusCode == 401) {
      await AuthRepository().tryAutoLogin();
      headers = await _getHeaders();
      response = await http.post(url, headers: headers);
    }

    if (response.statusCode != 200) {
      throw Exception('Erro ao limpar notificações: ${response.body}');
    }
  }
}
