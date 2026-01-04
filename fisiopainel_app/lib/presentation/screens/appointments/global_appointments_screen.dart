import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../controllers/global_appointment_controller.dart';
import '../../../domain/models/appointment_model.dart';

class GlobalAppointmentsScreen extends StatefulWidget {
  const GlobalAppointmentsScreen({super.key});

  @override
  State<GlobalAppointmentsScreen> createState() => _GlobalAppointmentsScreenState();
}

class _GlobalAppointmentsScreenState extends State<GlobalAppointmentsScreen> {
  final GlobalAppointmentController _controller = GlobalAppointmentController();
  bool _showPast = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      if (mounted) setState(() {});
    });
    _controller.loadAppointments();
  }

  List<AppointmentModel> get _filteredList {
    final now = DateTime.now();
    if (_showPast) {
      return _controller.appointments
          .where((a) => a.dateTime != null && a.dateTime!.isBefore(now))
          .toList()
        ..sort((a, b) => b.dateTime!.compareTo(a.dateTime!)); // Descendente
    } else {
      return _controller.appointments
          .where((a) => a.dateTime != null && a.dateTime!.isAfter(now))
          .toList();
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'AGENDADO': return Colors.blue;
      case 'REALIZADO': return Colors.green;
      case 'CANCELADO': return Colors.red;
      case 'FALTA': return Colors.orange;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final list = _filteredList;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Agenda Geral",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  const Text("Exibir Passados"),
                  Switch(
                    value: _showPast,
                    onChanged: (val) => setState(() => _showPast = val),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: () => _controller.loadAppointments(),
                  )
                ],
              )
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: _controller.isLoading
                ? const Center(child: CircularProgressIndicator())
                : list.isEmpty
                    ? const Center(child: Text("Nenhum agendamento encontrado."))
                    : ListView.builder(
                        itemCount: list.length,
                        itemBuilder: (ctx, i) {
                          final appt = list[i];
                          return Card(
                            elevation: 2,
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: _getStatusColor(appt.status).withOpacity(0.2),
                                child: Icon(Icons.event, color: _getStatusColor(appt.status)),
                              ),
                              title: Text(
                                DateFormat('dd/MM/yyyy HH:mm - EEEE', 'pt_BR').format(appt.dateTime!),
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("Profissional: ${appt.professionalName ?? 'N/D'}"),
                                  Text("Pacote ID: ${appt.packageId}"),
                                ],
                              ),
                              trailing: Chip(
                                label: Text(appt.status),
                                backgroundColor: _getStatusColor(appt.status).withOpacity(0.1),
                                labelStyle: TextStyle(color: _getStatusColor(appt.status)),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
