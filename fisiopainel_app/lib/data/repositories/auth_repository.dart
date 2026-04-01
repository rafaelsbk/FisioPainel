import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Importa os DTOs (Data Transfer Objects)
import '../dtos/token_dto.dart';
import '../dtos/professional_dto.dart';

// Importa o Modelo de Domínio
import '../../domain/models/professional_model.dart';

class AuthRepository {
  // CONFIGURAÇÃO DA URL BASE
  // Use 'http://127.0.0.1:8000/api' para Web
  // Use 'http://10.0.2.2:8000/api' se estiver no Emulador Android
  final String baseUrl = kIsWeb ? "http://127.0.0.1:8000/api" : "http://10.0.2.2:8000/api";

  /// ---------------------------------------------------
  /// 1. MÉTODO DE LOGIN (Obter o Token)
  /// ---------------------------------------------------
  Future<TokenDto> login(String username, String password) async {
    final url = Uri.parse('$baseUrl/token/');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"username": username, "password": password}),
      );

      if (response.statusCode == 200) {
        // Sucesso: Decodifica o JSON e transforma em Objeto Dart (TokenDto)
        final Map<String, dynamic> body = jsonDecode(response.body);
        return TokenDto.fromJson(body);
      } else {
        // Erro (ex: 401 Unauthorized)
        throw Exception('Usuário ou senha incorretos.');
      }
    } catch (e) {
      // Repassa o erro para quem chamou (o Controller) tratar
      rethrow;
    }
  }

  /// ---------------------------------------------------
  /// 2. MÉTODO DE CADASTRO (Criar Profissional)
  /// Requer o TOKEN JWT recebido no login
  /// ---------------------------------------------------
  Future<bool> registerProfessional(
    ProfessionalModel professional,
    String token,
  ) async {
    final url = Uri.parse('$baseUrl/users/');

    // Converte o Modelo de Negócio -> DTO -> JSON
    final bodyJson = jsonEncode(ProfessionalDto.toJson(professional));

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          // AQUI ESTÁ A AUTENTICAÇÃO
          'Authorization': 'Bearer $token',
        },
        body: bodyJson,
      );

      if (response.statusCode == 201) {
        return true; // 201 = Created (Criado com sucesso)
      } else {
        // Log para debug (útil para ver o erro detalhado do Django no terminal)
        print(
          'Erro no cadastro (Status ${response.statusCode}): ${response.body}',
        );

        // Tenta pegar a mensagem de erro do Django, se houver
        final errorMsg = response.body;
        throw Exception('Falha ao registrar: $errorMsg');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// ---------------------------------------------------
  /// 3. RENOVÇÃO DE TOKEN (Refresh)
  /// Tenta pegar um novo access token usando o refresh token salvo
  /// ---------------------------------------------------
  Future<bool> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final refreshToken = prefs.getString('refresh_token');

    if (refreshToken == null) return false; // Nem tem token salvo

    final url = Uri.parse('$baseUrl/token/refresh/');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"refresh": refreshToken}),
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final newAccessToken = body['access'];

        // Salva o novo token
        await prefs.setString('access_token', newAccessToken);
        return true; // Renovado com sucesso!
      } else {
        // Refresh token também expirou ou é inválido
        await prefs.clear(); // Limpa tudo para forçar login
        return false;
      }
    } catch (e) {
      return false;
    }
  }
}
