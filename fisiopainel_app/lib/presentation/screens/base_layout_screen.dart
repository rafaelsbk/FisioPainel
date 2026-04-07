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
import 'financeiro/financeiro_screen.dart';

class BaseLayoutScreen extends StatefulWidget {
  const BaseLayoutScreen({super.key});

  static _BaseLayoutScreenState? of(BuildContext context) {
    return context.findAncestorStateOfType<_BaseLayoutScreenState>();
  }

  @override
  State<BaseLayoutScreen> createState() => _BaseLayoutScreenState();
}

class _BaseLayoutScreenState extends State<BaseLayoutScreen> {
  int _selectedIndex = 0;
  String? _userRole;
  String? _username;
  bool _canAccessFinance = false;
  final NotificationController _notifController = NotificationController();

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _notifController.fetchCount();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userRole = prefs.getString('user_role')?.toUpperCase();
      _username = prefs.getString('username');
      _canAccessFinance = prefs.getBool('perm_pode_gerenciar_financeiro') ?? false;
    });
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
    }
  }

  void selectPage(int index, {BuildContext? ctx}) {
    setState(() {
      _selectedIndex = index;
    });
    // Somente fecha o drawer se um contexto de drawer for passado (Mobile)
    if (ctx != null && Navigator.canPop(ctx)) {
      Navigator.pop(ctx);
    }
  }

  String _getPageTitle() {
    switch (_selectedIndex) {
      case 0: return "Dashboard";
      case 1: return "Pacientes";
      case 2: return "Profissionais";
      case 3: return "Pacotes";
      case 4: return "Tipos de Atendimento";
      case 5: return "Agenda Geral";
      case 6: return "Notificações";
      case 7: return "Relatórios";
      case 8: return "Cargos e Permissões";
      case 9: return "Financeiro";
      default: return "FisioPainel";
    }
  }

  Widget _getContentWidget() {
    switch (_selectedIndex) {
      case 0: return const DashboardScreen();
      case 1: return const PatientsScreen();
      case 2: return const ProfessionalsScreen();
      case 3: return const PackagesScreen();
      case 4: return const ServiceTypeScreen();
      case 5: return const GlobalAppointmentsScreen();
      case 6: return const NotificationsScreen();
      case 7: return const ReportsScreen();
      case 8: return const UserRoleScreen();
      case 9: return const FinanceiroScreen();
      default: return const Center(child: Text("Página não encontrada"));
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isMobile = constraints.maxWidth < 900;

        return Scaffold(
          resizeToAvoidBottomInset: false,
          appBar: AppBar(
            title: Text(_getPageTitle()),
            actions: [
              if (!isMobile && _username != null)
                Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: Center(
                    child: Text(
                      "Olá, $_username",
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                  ),
                ),
              IconButton(
                icon: const Icon(Icons.logout, color: Colors.redAccent),
                onPressed: _logout,
                tooltip: "Sair",
              ),
              const SizedBox(width: 8),
            ],
          ),
          drawer: isMobile ? _buildDrawer() : null,
          bottomNavigationBar: isMobile ? _buildBottomNav() : null,
          body: Row(
            children: [
              if (!isMobile) _buildSidebar(),
              Expanded(
                child: Container(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  child: _getContentWidget(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: _selectedIndex == 0 ? 0 : (_selectedIndex == 5 ? 1 : (_selectedIndex == 6 ? 2 : (_selectedIndex == 7 ? 3 : 0))),
      type: BottomNavigationBarType.fixed,
      selectedItemColor: Theme.of(context).colorScheme.primary,
      unselectedItemColor: Colors.grey,
      onTap: (index) {
        int targetIndex = 0;
        if (index == 0) targetIndex = 0;
        if (index == 1) targetIndex = 5;
        if (index == 2) targetIndex = 6;
        if (index == 3) targetIndex = 7;
        selectPage(targetIndex);
      },
      items: [
        const BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), activeIcon: Icon(Icons.dashboard), label: "Início"),
        const BottomNavigationBarItem(icon: Icon(Icons.calendar_today_outlined), activeIcon: Icon(Icons.calendar_today), label: "Agenda"),
        BottomNavigationBarItem(
          icon: AnimatedBuilder(
            animation: _notifController,
            builder: (context, _) => Badge(
              isLabelVisible: _notifController.unreadCount > 0,
              label: Text('${_notifController.unreadCount}'),
              child: const Icon(Icons.notifications_outlined),
            ),
          ),
          activeIcon: const Icon(Icons.notifications),
          label: "Avisos",
        ),
        const BottomNavigationBarItem(icon: Icon(Icons.analytics_outlined), activeIcon: Icon(Icons.analytics), label: "Relatórios"),
      ],
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 48, 16, 16),
            decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person, size: 24, color: Color(0xFF0F172A)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _username ?? "Usuário",
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        _userRole ?? "",
                        style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildDrawerItem(0, "Início", Icons.dashboard),
                _buildDrawerItem(5, "Agenda Geral", Icons.calendar_today),
                _buildDrawerItem(6, "Notificações", Icons.notifications),
                _buildDrawerItem(7, "Relatórios", Icons.analytics),
                if (_userRole == 'ADMIN' || _canAccessFinance) _buildDrawerItem(9, "Financeiro", Icons.attach_money),
                const Divider(),
                const Padding(
                  padding: EdgeInsets.only(left: 16, top: 8, bottom: 8),
                  child: Text("CADASTROS", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                ),
                _buildDrawerItem(1, "Pacientes", Icons.people),
                if (_userRole == 'ADMIN') _buildDrawerItem(2, "Profissionais", Icons.medical_services),
                _buildDrawerItem(3, "Pacotes", Icons.inventory_2),
                if (_userRole == 'ADMIN') _buildDrawerItem(4, "Tipos de Atendimento", Icons.category),
                if (_userRole == 'ADMIN') _buildDrawerItem(8, "Cargos e Permissões", Icons.admin_panel_settings),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(int index, String title, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: _selectedIndex == index ? Theme.of(context).colorScheme.primary : Colors.grey[700]),
      title: Text(title, style: TextStyle(fontWeight: _selectedIndex == index ? FontWeight.bold : FontWeight.normal)),
      selected: _selectedIndex == index,
      onTap: () => selectPage(index, ctx: context),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 260,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: const Row(
              children: [
                Icon(Icons.flash_on, color: Colors.tealAccent, size: 20),
                SizedBox(width: 12),
                Text("FISIOPAINEL", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildSidebarItem(0, "Dashboard", Icons.dashboard),
                _buildSidebarItem(5, "Agenda Geral", Icons.calendar_month),
                _buildSidebarItem(6, "Notificações", Icons.notifications),
                _buildSidebarItem(7, "Relatórios", Icons.analytics),
                if (_userRole == 'ADMIN' || _canAccessFinance) _buildSidebarItem(9, "Financeiro", Icons.attach_money),
                const SizedBox(height: 20),
                const Text("ADMINISTRAÇÃO", style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
                const SizedBox(height: 10),
                _buildSidebarItem(1, "Pacientes", Icons.people),
                if (_userRole == 'ADMIN') _buildSidebarItem(2, "Profissionais", Icons.medical_services),
                _buildSidebarItem(3, "Pacotes", Icons.inventory_2),
                if (_userRole == 'ADMIN') _buildSidebarItem(4, "Tipos de Atendimento", Icons.category),
                if (_userRole == 'ADMIN') _buildSidebarItem(8, "Cargos e Permissões", Icons.admin_panel_settings),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            child: Text("v0.1.0-tech", style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 10)),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(int index, String title, IconData icon) {
    final bool isSelected = _selectedIndex == index;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        onTap: () => selectPage(index),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        selected: isSelected,
        selectedTileColor: Colors.white.withOpacity(0.1),
        leading: Icon(icon, color: isSelected ? Colors.tealAccent : Colors.white70, size: 22),
        title: Text(title, style: TextStyle(color: isSelected ? Colors.white : Colors.white70, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, fontSize: 14)),
      ),
    );
  }
}
