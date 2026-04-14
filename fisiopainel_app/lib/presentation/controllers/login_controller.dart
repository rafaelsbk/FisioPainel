import 'dart:convert';
import 'package:flutter/material.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/services/storage_service.dart';

class LoginController extends ChangeNotifier {
  final AuthRepository repository;
  final StorageService _storage = StorageService();

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

    try {
      final tokenDto = await repository.login(
        userController.text,
        passController.text,
      );

      await _storage.saveAccessToken(tokenDto.access);
      await _storage.saveRefreshToken(tokenDto.refresh);
      await _storage.saveUsername(userController.text);
      await _storage.savePassword(passController.text);
      
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
      error = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
