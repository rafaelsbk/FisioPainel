import 'package:fisiopainel_app/presentation/screens/packages/package_screen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'patients/patients_screen.dart';
import 'professionals/professional_screen.dart';
import 'service_types/service_type_screen.dart';
import 'appointments/global_appointments_screen.dart';

class BaseLayoutScreen extends StatefulWidget {
  const BaseLayoutScreen({super.key});

  @override
  State<BaseLayoutScreen> createState() => _BaseLayoutScreenState();
}

class _BaseLayoutScreenState extends State<BaseLayoutScreen> {
  // Índice para controlar qual tela está sendo exibida na área de conteúdo
  // 0: Home, 1: Pacientes, 2: Profissionais, 3: Pacotes, 4: Atendimentos
  int _selectedIndex = 0;

  // Título da página atual
  String _pageTitle = "Início";

  // Função de Logout
  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    }
  }

  // Método para trocar o conteúdo
  void _selectPage(int index, String title) {
    setState(() {
      _selectedIndex = index;
      _pageTitle = title;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Barra superior simples com Título e Logout
      appBar: AppBar(
        title: Text(_pageTitle),
        backgroundColor: Colors.white,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app, color: Colors.red),
            onPressed: _logout,
            tooltip: 'Sair',
          ),
        ],
      ),
      body: Row(
        children: [
          // --- SIDEBAR (Barra Lateral) ---
          Container(
            width: 250, // Largura fixa da sidebar
            color: Colors.blueGrey[900], // Cor escura profissional
            child: Column(
              children: [
                // Cabeçalho da Sidebar
                Container(
                  height: 60,
                  alignment: Alignment.center,
                  color: Colors.blueGrey[800],
                  child: const Text(
                    "SISTEMA",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                // Opção Home
                ListTile(
                  leading: const Icon(Icons.dashboard, color: Colors.white70),
                  title: const Text(
                    'Início',
                    style: TextStyle(color: Colors.white),
                  ),
                  selected: _selectedIndex == 0,
                  selectedTileColor: Colors.blueGrey[700],
                  onTap: () => _selectPage(0, "Visão Geral"),
                ),

                // Opção Agenda
                ListTile(
                  leading: const Icon(Icons.calendar_today, color: Colors.white70),
                  title: const Text(
                    'Agenda',
                    style: TextStyle(color: Colors.white),
                  ),
                  selected: _selectedIndex == 5,
                  selectedTileColor: Colors.blueGrey[700],
                  onTap: () => _selectPage(5, "Agenda de Atendimentos"),
                ),

                // --- SUBMENU DE CADASTROS ---
                Theme(
                  // Remove as bordas divisórias padrão do ExpansionTile
                  data: Theme.of(
                    context,
                  ).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    leading: const Icon(
                      Icons.folder_shared,
                      color: Colors.white70,
                    ),
                    title: const Text(
                      'Cadastros',
                      style: TextStyle(color: Colors.white),
                    ),
                    iconColor: Colors.white,
                    collapsedIconColor: Colors.white70,
                    childrenPadding: const EdgeInsets.only(
                      left: 20,
                    ), // Indentação
                    children: [
                      _buildMenuItem(1, "Pacientes", Icons.person),
                      _buildMenuItem(
                        2,
                        "Profissionais",
                        Icons.medical_services,
                      ),
                      _buildMenuItem(3, "Pacotes", Icons.inventory_2),
                      _buildMenuItem(4, "Tipos de Atendimento", Icons.calendar_month),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // --- ÁREA DE CONTEÚDO (Dinâmica) ---
          Expanded(
            child: Container(
              color: Colors.grey[100], // Fundo claro para o conteúdo
              padding: const EdgeInsets.all(20),
              child: _getContentWidget(), // Aqui a mágica acontece
            ),
          ),
        ],
      ),
    );
  }

  // Widget auxiliar para itens do submenu
  Widget _buildMenuItem(int index, String title, IconData icon) {
    return ListTile(
      leading: Icon(icon, size: 20, color: Colors.white70),
      title: Text(title, style: const TextStyle(color: Colors.white70)),
      selected: _selectedIndex == index,
      selectedTileColor: Colors.blueGrey[700],
      onTap: () => _selectPage(index, title),
    );
  }

  // Função que retorna a TELA correspondente ao menu clicado
  Widget _getContentWidget() {
    switch (_selectedIndex) {
      case 0:
        return const Center(child: Text("Bem-vindo ao Dashboard Inicial"));

      case 1:
        // AQUI ESTÁ A MUDANÇA: Retorna a tela de pacientes
        return const PatientsScreen();
      case 2:
        return const ProfessionalsScreen(); // Agora exibe a tela real
      case 3:
        return const PackagesScreen();
      case 4:
        return const ServiceTypeScreen();
      case 5:
        return const GlobalAppointmentsScreen();
      default:
        return const Center(child: Text("Página não encontrada"));
    }
  }
}
