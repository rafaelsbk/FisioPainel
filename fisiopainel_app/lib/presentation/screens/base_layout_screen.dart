import 'dart:async';
import 'package:fisiopainel_app/presentation/screens/packages/package_screen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../controllers/notification_controller.dart';
import 'patients/patients_screen.dart';
import 'professionals/professional_screen.dart';
import 'service_types/service_type_screen.dart';
import 'appointments/global_appointments_screen.dart';
import 'notifications_screen.dart';
import 'dashboard_screen.dart';

class BaseLayoutScreen extends StatefulWidget {
  const BaseLayoutScreen({super.key});

  @override
  State<BaseLayoutScreen> createState() => _BaseLayoutScreenState();
}

class _BaseLayoutScreenState extends State<BaseLayoutScreen> {
  // Índice para controlar qual tela está sendo exibida na área de conteúdo
  int _selectedIndex = 0;
  String? _userRole;
  String? _username;

  // Título da página atual
  String _pageTitle = "Início";
  final NotificationController _notifController = NotificationController();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _notifController.fetchCount();
    // Poll every 30 seconds
    _timer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _notifController.fetchCount();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userRole = prefs.getString('user_role');
      _username = prefs.getString('username');
    });
  }

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
      appBar: AppBar(
        title: Text(_pageTitle),
        backgroundColor: Colors.white,
        elevation: 1,
        actions: [
          if (_username != null)
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Center(
                child: Text(
                  "Você está logado como: ${_username!}",
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          TextButton.icon(
            icon: const Icon(Icons.exit_to_app, color: Colors.red),
            label: const Text(
              'SAIR',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
            onPressed: _logout,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Row(
        children: [
          // --- SIDEBAR (Barra Lateral) ---
          Container(
            width: 250,
            color: Colors.blueGrey[900],
            child: Column(
              children: [
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

                AnimatedBuilder(
                  animation: _notifController,
                  builder: (context, child) {
                    return ListTile(
                      leading: Badge(
                        isLabelVisible: _notifController.unreadCount > 0,
                        label: Text('${_notifController.unreadCount}'),
                        child: const Icon(Icons.notifications, color: Colors.white70),
                      ),
                      title: Row(
                        children: [
                          const Text(
                            'Notificações',
                            style: TextStyle(color: Colors.white),
                          ),
                          if (_notifController.unreadCount > 0) ...[
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${_notifController.unreadCount}',
                                style: const TextStyle(color: Colors.white, fontSize: 10),
                              ),
                            )
                          ]
                        ],
                      ),
                      selected: _selectedIndex == 6,
                      selectedTileColor: Colors.blueGrey[700],
                      onTap: () {
                         _selectPage(6, "Notificações");
                         // Mark as read when opening the screen
                         _notifController.markAsRead();
                      },
                    );
                  },
                ),

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
                  data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
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
                    childrenPadding: const EdgeInsets.only(left: 20),
                    children: [
                      _buildMenuItem(1, "Pacientes", Icons.person),
                      if (_userRole == 'ADMIN')
                        _buildMenuItem(
                          2,
                          "Profissionais",
                          Icons.medical_services,
                        ),
                      _buildMenuItem(3, "Pacotes", Icons.inventory_2),
                      if (_userRole == 'ADMIN')
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
              color: Colors.grey[100],
              padding: const EdgeInsets.all(20),
              child: _getContentWidget(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(int index, String title, IconData icon) {
    return ListTile(
      leading: Icon(icon, size: 20, color: Colors.white70),
      title: Text(title, style: const TextStyle(color: Colors.white70)),
      selected: _selectedIndex == index,
      selectedTileColor: Colors.blueGrey[700],
      onTap: () => _selectPage(index, title),
    );
  }

  Widget _getContentWidget() {
    switch (_selectedIndex) {
      case 0:
        return const DashboardScreen();
      case 1:
        return const PatientsScreen();
      case 2:
        return const ProfessionalsScreen();
      case 3:
        return const PackagesScreen();
            case 4:
              return const ServiceTypeScreen();
            case 5:
              return const GlobalAppointmentsScreen();
            case 6:
              return const NotificationsScreen();
            default:
              return const Center(child: Text("Página não encontrada"));
          }
        }
      }
      