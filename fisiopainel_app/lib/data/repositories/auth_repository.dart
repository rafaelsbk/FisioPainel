import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/storage_service.dart';

import '../../config/api_config.dart';

// Importa os DTOs (Data Transfer Objects)
import '../dtos/token_dto.dart';
import '../dtos/professional_dto.dart';

// Importa o Modelo de Domínio
import '../../domain/models/professional_model.dart';

class AuthRepository {
  // CONFIGURAÇÃO DA URL BASE
  final String baseUrl = ApiConfig.baseUrl;
  final StorageService _storage = StorageService();

  /// ---------------------------------------------------
  /// 1. MÉTODO DE LOGIN (Obter o Token)
  /// ---------------------------------------------------
  Future<TokenDto> login(String username, String password) async {
    final url = Uri.parse('$baseUrl/token/');
    final body = jsonEncode({"username": username, "password": password});

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
    final accessToken = await _storage.getAccessToken();
    final refreshToken = await _storage.getRefreshToken();
    final username = await _storage.getUsername();
    final password = await _storage.getPassword();

    if (accessToken != null) {
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
        // Em caso de erro, segue
      }
    }

    // 2. Se expirou ou está perto de expirar, tenta o refresh
    if (refreshToken != null) {
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
          await _storage.saveAccessToken(newAccessToken);
          return true;
        }
      } catch (e) {
        // Em caso de erro, segue
      }
    }

    // 3. Se refresh falhou ou não existe, tenta o login completo com as credenciais salvas
    if (username != null && password != null) {
      try {
        final tokenDto = await login(username, password);
        
        await _storage.saveAccessToken(tokenDto.access);
        await _storage.saveRefreshToken(tokenDto.refresh);
        
        // Decodifica o JWT para pegar o user_id
        try {
          final parts = tokenDto.access.split('.');
          if (parts.length == 3) {
            final payload = jsonDecode(
              utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
            );
            final userId = payload['user_id'];
            if (userId != null) {
              await _storage.saveUserId(userId.toString());
            }
          }
        } catch (e) {
          // segue
        }

        if (tokenDto.role != null) {
          await _storage.saveUserRole(tokenDto.role!);
        }

        if (tokenDto.permissions != null) {
          for (var entry in tokenDto.permissions!.entries) {
            if (entry.value is bool) {
              await _storage.savePermission(entry.key, entry.value);
            }
          }
        }
        return true;
      } catch (e) {
        // Se falhou o login com as credenciais salvas, limpa tudo para forçar login manual
        await _storage.clearAll();
        return false;
      }
    }

    return false;
  }
}
