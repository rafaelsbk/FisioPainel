import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../config/api_config.dart';

// Importa os DTOs (Data Transfer Objects)
import '../dtos/token_dto.dart';
import '../dtos/professional_dto.dart';

// Importa o Modelo de Domínio
import '../../domain/models/professional_model.dart';

class AuthRepository {
  // CONFIGURAÇÃO DA URL BASE
  final String baseUrl = ApiConfig.baseUrl;

  /// ---------------------------------------------------
  /// 1. MÉTODO DE LOGIN (Obter o Token)
  /// ---------------------------------------------------
  Future<TokenDto> login(String username, String password) async {
    final url = Uri.parse('$baseUrl/token/');
    final body = jsonEncode({"username": username, "password": password});
    print('--- DEBUG: Enviando login para $url: $body ---');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
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
  /// 3. RENOVAÇÃO DE TOKEN (Refresh)
  /// Tenta validar o token atual ou pegar um novo access token usando o refresh token salvo
  /// ---------------------------------------------------
  Future<bool> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('access_token');
    final refreshToken = prefs.getString('refresh_token');

    if (accessToken == null) return false;

    // 1. Verifica se o access token atual ainda é válido
    try {
      final parts = accessToken.split('.');
      if (parts.length == 3) {
        final String payloadPart = base64Url.normalize(parts[1]);
        final String decodedPayload = utf8.decode(base64Url.decode(payloadPart));
        final Map<String, dynamic> payload = jsonDecode(decodedPayload);
        
        final exp = payload['exp'];
        if (exp != null) {
          final expiryDate = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
          // Se faltar mais de 1 minuto para expirar, considera válido
          if (expiryDate.isAfter(DateTime.now().add(const Duration(minutes: 1)))) {
            return true;
          }
        }
      }
    } catch (e) {
      print('Erro ao validar expiração do token: $e');
      // Em caso de erro na decodificação, segue para tentar o refresh
    }

    // 2. Se expirou ou está perto de expirar, tenta o refresh
    if (refreshToken == null) return false;

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
        // Limpa apenas os tokens para não perder preferências se houver, 
        // mas aqui costuma-se limpar tudo relacionado à sessão
        await prefs.remove('access_token');
        await prefs.remove('refresh_token');
        return false;
      }
    } catch (e) {
      return false;
    }
  }
}
