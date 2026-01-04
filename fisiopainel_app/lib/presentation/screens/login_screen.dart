import 'package:flutter/material.dart';
import '../../data/repositories/auth_repository.dart';
import '../controllers/login_controller.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Instanciando o Controller (em apps reais, usaria Provider/GetIt para injeção)
  late final LoginController _controller;

  @override
  void initState() {
    super.initState();
    _controller = LoginController(AuthRepository());
    // Escuta mudanças no controller para redesenhar a tela (loading/erros)
    _controller.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(
            maxWidth: 400,
          ), // Limita largura na Web
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_person, size: 80, color: Colors.blue),
              const SizedBox(height: 30),

              // Campo Usuário
              TextField(
                controller: _controller.userController,
                decoration: const InputDecoration(
                  labelText: 'Usuário',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 20),

              // Campo Senha
              TextField(
                controller: _controller.passController,
                obscureText: true, // Esconde a senha
                decoration: const InputDecoration(
                  labelText: 'Senha',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
              ),
              const SizedBox(height: 20),

              // Exibe erro se houver
              if (_controller.error.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Text(
                    _controller.error,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),

              // Botão de Login
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _controller.isLoading
                      ? null
                      : () async {
                          print(
                            '--- DEBUG: Botão clicado ---',
                          ); // <--- ADICIONE

                          final success = await _controller.login();

                          print(
                            '--- DEBUG: Resultado do login foi: $success ---',
                          ); // <--- ADICIONE

                          if (success) {
                            if (context.mounted) {
                              print(
                                '--- DEBUG: Tentando navegar para /dashboard ---',
                              ); // <--- ADICIONE
                              Navigator.pushReplacementNamed(
                                context,
                                '/dashboard',
                              );
                            } else {
                              print(
                                '--- DEBUG: Contexto perdido (tela fechou antes) ---',
                              );
                            }
                          } else {
                            print(
                              '--- DEBUG: Login retornou false, não navegou. ---',
                            );
                          }
                        },
                  child: _controller.isLoading
                      ? const CircularProgressIndicator()
                      : const Text('ENTRAR'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
