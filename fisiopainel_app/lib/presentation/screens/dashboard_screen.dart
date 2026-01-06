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
    try {
      final allAppointments = await _repository.getAllAppointments();
      final now = DateTime.now();
      
      // Filter for today
      final todayList = allAppointments.where((appt) {
        if (appt.dateTime == null) return false;
        final d = appt.dateTime!;
        return d.year == now.year && d.month == now.month && d.day == now.day;
      }).toList();

      // Sort by time
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
      case 'REALIZADO': return Colors.green;
      case 'CANCELADO': return Colors.grey;
      case 'FALTA': return Colors.red;
      default: return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('dd/MM/yyyy').format(DateTime.now());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Welcome Header
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.blue[800],
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 5),
              )
            ],
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.white,
                child: Icon(Icons.person, size: 35, color: Colors.blue[800]),
              ),
              const SizedBox(width: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Olá, ${_userName ?? 'Profissional'}",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    "Hoje é $dateStr",
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              )
            ],
          ),
        ),
        
        const SizedBox(height: 30),
        
        // Appointments List Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
             const Text(
              "Atendimentos de Hoje",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _fetchTodayAppointments,
              tooltip: "Atualizar",
            )
          ],
        ),
        
        const SizedBox(height: 10),

        // List
        Expanded(
          child: _isLoading 
            ? const Center(child: CircularProgressIndicator())
            : _todayAppointments.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  itemCount: _todayAppointments.length,
                  itemBuilder: (context, index) {
                    final appt = _todayAppointments[index];
                    final timeStr = DateFormat('HH:mm').format(appt.dateTime!);
                    
                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            timeStr,
                            style: TextStyle(
                              color: Colors.blue[900],
                              fontWeight: FontWeight.bold,
                              fontSize: 16
                            ),
                          ),
                        ),
                        title: Text(
                          appt.patientName ?? "Paciente não identificado",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          appt.status,
                          style: TextStyle(
                            color: _getStatusColor(appt.status),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                        onTap: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AppointmentDetailScreen(appointment: appt),
                            ),
                          );
                          // Refresh if changes were made
                          if (result == true) {
                            _fetchTodayAppointments();
                          }
                        },
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_available, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            "Nenhum atendimento para hoje!",
            style: TextStyle(color: Colors.grey[600], fontSize: 16),
          ),
        ],
      ),
    );
  }
}
