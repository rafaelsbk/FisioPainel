import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/repositories/appointment_repository.dart';
import '../../domain/models/appointment_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'appointments/appointment_detail_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final AppointmentRepository _repository = AppointmentRepository();
  List<AppointmentModel> _todayAppointments = [];
  bool _isLoading = true;
  String? _userName;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('username');
    });
    await _fetchTodayAppointments();
  }

  Future<void> _fetchTodayAppointments() async {
    setState(() => _isLoading = true);
    try {
      final allAppointments = await _repository.getAllAppointments();
      final now = DateTime.now();
      
      final todayList = allAppointments.where((appt) {
        if (appt.dateTime == null) return false;
        final d = appt.dateTime!;
        return d.year == now.year && d.month == now.month && d.day == now.day;
      }).toList();

      todayList.sort((a, b) => a.dateTime!.compareTo(b.dateTime!));

      if (mounted) {
        setState(() {
          _todayAppointments = todayList;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro ao carregar agenda: $e")),
        );
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'AGENDADO': return Colors.blue;
      case 'REALIZADO': return Colors.teal;
      case 'CANCELADO': return Colors.redAccent;
      case 'FALTA': return Colors.orange;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('EEEE, d MMMM', 'pt_BR').format(DateTime.now());
    
    final int completed = _todayAppointments.where((a) => a.status == 'REALIZADO').length;
    final int pending = _todayAppointments.where((a) => a.status == 'AGENDADO').length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Header
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Bom dia, ${_userName ?? 'Profissional'}!",
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: -0.5),
                  ),
                  Text(
                    dateStr,
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ],
              ),
              const Spacer(),
              CircleAvatar(
                radius: 24,
                backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                child: Icon(Icons.person_outline, color: Theme.of(context).colorScheme.primary),
              ),
            ],
          ),
          
          const SizedBox(height: 32),
          
          // KPI Row
          SizedBox(
            height: 120,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildKPICard("Total Hoje", "${_todayAppointments.length}", Icons.event_note, Colors.blue),
                _buildKPICard("Concluídos", "$completed", Icons.check_circle_outline, Colors.teal),
                _buildKPICard("Pendentes", "$pending", Icons.pending_actions, Colors.orange),
              ],
            ),
          ),
          
          const SizedBox(height: 40),
          
          // Appointments List Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Agenda do Dia",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              TextButton.icon(
                onPressed: _fetchTodayAppointments,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text("Atualizar"),
              )
            ],
          ),
          
          const SizedBox(height: 16),

          // List
          if (_isLoading)
            const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()))
          else if (_todayAppointments.isEmpty)
            _buildEmptyState()
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _todayAppointments.length,
              itemBuilder: (context, index) {
                final appt = _todayAppointments[index];
                final timeStr = DateFormat('HH:mm').format(appt.dateTime!);
                final statusColor = _getStatusColor(appt.status);
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.withOpacity(0.1)),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          timeStr,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Container(
                          width: 4,
                          height: 20,
                          margin: const EdgeInsets.only(top: 4),
                          decoration: BoxDecoration(
                            color: statusColor,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        )
                      ],
                    ),
                    title: Text(
                      appt.patientName ?? "S/ Paciente",
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        children: [
                          Icon(Icons.medical_services_outlined, size: 12, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(appt.professionalName ?? "N/D", style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                        ],
                      ),
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        appt.status,
                        style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => AppointmentDetailScreen(appointment: appt)),
                      );
                      if (result == true) _fetchTodayAppointments();
                    },
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildKPICard(String label, String value, IconData icon, Color color) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
        boxShadow: [BoxShadow(color: color.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 24),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 40),
          Icon(Icons.calendar_today_outlined, size: 60, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text("Sem compromissos para hoje", style: TextStyle(color: Colors.grey[500], fontSize: 14)),
        ],
      ),
    );
  }
}
