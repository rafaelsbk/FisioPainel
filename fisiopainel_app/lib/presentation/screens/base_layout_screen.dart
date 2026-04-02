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
import 'reports/reports_screen.dart';
import 'roles/user_role_screen.dart';

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

  @override
  void initState() {
    super.initState();
    _loadUserData();
    // Fetch count only once on init (login/startup)
    _notifController.fetchCount();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userRole = prefs.getString('user_role')?.toUpperCase();
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
    final bool isMobile = MediaQuery.of(context).size.width < 900;
    // Cores Sugeridas: Verde Sálvia / Azul Água / Cinza Suave
    final Color primaryColor = Colors.teal[700]!; 
    final Color sidebarColor = Colors.white;
    final Color sidebarHeaderColor = Colors.teal[800]!;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _pageTitle,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: primaryColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        leading: isMobile
            ? Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              )
            : null,
        actions: [
          if (_username != null && !isMobile)
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Center(
                child: Text(
                  "Logado: ${_username!}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.exit_to_app, color: Colors.white),
            tooltip: 'SAIR',
            onPressed: _logout,
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: isMobile
          ? Drawer(
              backgroundColor: sidebarColor,
              child: _buildSidebar(sidebarHeaderColor, primaryColor),
            )
          : null,
      body: Row(
        children: [
          // --- SIDEBAR (Barra Lateral) fixa apenas em telas grandes ---
          if (!isMobile)
            Container(
              width: 250,
              decoration: BoxDecoration(
                color: sidebarColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    spreadRadius: 1,
                    blurRadius: 5,
                  )
                ],
              ),
              child: _buildSidebar(sidebarHeaderColor, primaryColor),
            ),

          // --- ÁREA DE CONTEÚDO (Dinâmica) ---
          Expanded(
            child: Container(
              color: Colors.grey[50],
              padding: EdgeInsets.all(isMobile ? 8 : 24),
              child: _getContentWidget(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(Color headerColor, Color activeColor) {
    final bool isDark = activeColor.computeLuminance() < 0.5;

    return Column(
      children: [
        Container(
          height: 100,
          width: double.infinity,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: headerColor,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [headerColor, headerColor.withOpacity(0.8)],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.health_and_safety, color: Colors.white, size: 30),
              const SizedBox(height: 8),
              const Text(
                "FISIOPAINEL",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              _buildSidebarTile(0, "Visão Geral", Icons.dashboard_outlined, activeColor),
              _buildSidebarTile(6, "Notificações", Icons.notifications_none, activeColor, isNotification: true),
              _buildSidebarTile(5, "Agenda", Icons.calendar_today_outlined, activeColor),
              _buildSidebarTile(7, "Relatórios", Icons.analytics_outlined, activeColor),

              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Divider(),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Text(
                  "GERENCIAMENTO",
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey),
                ),
              ),
              
              _buildSidebarTile(1, "Pacientes", Icons.people_outline, activeColor),
              if (_userRole == 'ADMIN')
                _buildSidebarTile(2, "Profissionais", Icons.medical_services_outlined, activeColor),
              _buildSidebarTile(3, "Pacotes", Icons.inventory_2_outlined, activeColor),
              if (_userRole == 'ADMIN')
                _buildSidebarTile(4, "Tipos de Atendimento", Icons.category_outlined, activeColor),
              if (_userRole == 'ADMIN')
                _buildSidebarTile(8, "Cargos e Permissões", Icons.admin_panel_settings_outlined, activeColor),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSidebarTile(int index, String title, IconData icon, Color activeColor, {bool isNotification = false}) {
    final bool isSelected = _selectedIndex == index;
    
    return ListTile(
      leading: isNotification 
        ? Badge(
            isLabelVisible: _notifController.unreadCount > 0,
            label: Text('${_notifController.unreadCount}'),
            child: Icon(icon, color: isSelected ? activeColor : Colors.blueGrey[600]),
          )
        : Icon(icon, color: isSelected ? activeColor : Colors.blueGrey[600]),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? activeColor : Colors.blueGrey[800],
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      selectedTileColor: activeColor.withOpacity(0.1),
      onTap: () {
        if (isNotification) _notifController.markAsRead();
        _handleMenuClick(index, title);
      },
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
    );
  }

  void _handleMenuClick(int index, String title) {
    _selectPage(index, title);
    if (MediaQuery.of(context).size.width < 900) {
      Navigator.pop(context); // Fecha o drawer no mobile
    }
  }

  Widget _buildMenuItem(int index, String title, IconData icon) {
    return ListTile(
      leading: Icon(icon, size: 20, color: Colors.white70),
      title: Text(title, style: const TextStyle(color: Colors.white70)),
      selected: _selectedIndex == index,
      selectedTileColor: Colors.blueGrey[700],
      onTap: () => _handleMenuClick(index, title),
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
            case 7:
              return const ReportsScreen();
            case 8:
              return const UserRoleScreen();
            default:
              return const Center(child: Text("Página não encontrada"));
          }
        }
      }
      