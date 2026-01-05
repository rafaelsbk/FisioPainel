import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/repositories/auth_repository.dart';

class LoginController extends ChangeNotifier {
  final AuthRepository repository;

  LoginController(this.repository);

  // Controladores dos campos de texto
  final TextEditingController userController = TextEditingController();
  final TextEditingController passController = TextEditingController();

  bool isLoading = false;
  String error = '';

  Future<bool> login() async {
    isLoading = true;
    error = '';
    notifyListeners();

    print('--- DEBUG: Iniciando tentativa de login... ---'); // <--- ADICIONE

    try {
      print('--- DEBUG: Chamando repository... ---'); // <--- ADICIONE

      final tokenDto = await repository.login(
        userController.text,
        passController.text,
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('access_token', tokenDto.access);
      await prefs.setString('refresh_token', tokenDto.refresh);
      await prefs.setString('username', userController.text);
      
      // Decodifica o JWT para pegar o user_id
      try {
        final parts = tokenDto.access.split('.');
        if (parts.length == 3) {
          final payload = jsonDecode(
            utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
          );
          final userId = payload['user_id'];
          if (userId != null) {
            await prefs.setString('user_id', userId.toString());
          }
        }
      } catch (e) {
        print('Erro ao decodificar token: $e');
      }

      if (tokenDto.role != null) {
        await prefs.setString('user_role', tokenDto.role!);
      }
      
      return true;
    } catch (e) {
      print(
        '--- DEBUG: ERRO NO LOGIN: $e ---',
      ); // <--- IMPORTANTE: VERIFIQUE ISSO NO CONSOLE

      error = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
