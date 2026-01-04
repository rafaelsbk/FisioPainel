import 'package:flutter/material.dart';
import 'presentation/screens/home_screen.dart';
import 'presentation/screens/login_screen.dart';
import 'presentation/screens/base_layout_screen.dart'; // Importe a nova tela
import 'presentation/widgets/auth_guard.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Projeto Flutter Django',
      debugShowCheckedModeBanner: false, // Remove a faixa "DEBUG" no canto
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      // Rota inicial (A primeira tela a abrir)
      initialRoute: '/',

      // Mapa de Rotas
      routes: {
        '/': (context) => const HomeScreen(),
        '/login': (context) => const LoginScreen(),
        '/dashboard': (context) => const AuthGuard(child: BaseLayoutScreen()),
      },
    );
  }
}
