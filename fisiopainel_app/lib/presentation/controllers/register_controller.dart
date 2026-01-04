// lib/presentation/controllers/register_controller.dart
import 'package:flutter/material.dart';
import '../../domain/models/professional_model.dart';
import '../../data/repositories/auth_repository.dart';

class RegisterController extends ChangeNotifier {
  final AuthRepository repository;

  RegisterController(this.repository);

  bool isLoading = false;
  String? errorMessage;

  Future<void> cadastrar(ProfessionalModel professional, String token) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      await repository.registerProfessional(professional, token);
      // Sucesso! A UI pode navegar para outra tela ou mostrar um SnackBar
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
