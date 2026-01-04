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

      print(
        '--- DEBUG: Sucesso! Token recebido: ${tokenDto.access.substring(0, 10)}... ---',
      ); // <--- ADICIONE

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('access_token', tokenDto.access);
      await prefs.setString('refresh_token', tokenDto.refresh);

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
