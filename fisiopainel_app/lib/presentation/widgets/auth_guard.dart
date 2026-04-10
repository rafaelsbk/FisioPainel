import 'package:flutter/material.dart';
import '../../data/repositories/auth_repository.dart';

class AuthGuard extends StatefulWidget {
  final Widget child; // A tela que queremos proteger

  const AuthGuard({super.key, required this.child});

  @override
  State<AuthGuard> createState() => _AuthGuardState();
}

class _AuthGuardState extends State<AuthGuard> {
  bool _isLoading = true;
  bool _isAuthenticated = false;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final AuthRepository authRepo = AuthRepository();
    final bool isValid = await authRepo.tryAutoLogin();

    if (isValid) {
      if (mounted) {
        setState(() {
          _isAuthenticated = true;
          _isLoading = false;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isAuthenticated = false;
        });
        Navigator.pushReplacementNamed(context, '/');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      // Enquanto verifica o token, mostra um loading (tela branca limpa)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_isAuthenticated) {
      // Se autenticado, mostra a tela desejada (Dashboard)
      return widget.child;
    }

    // Se não autenticado, retorna um container vazio enquanto redireciona
    return const Scaffold();
  }
}
