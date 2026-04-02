import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../controllers/appointment_controller.dart';
import '../../../domain/models/appointment_model.dart';

class AppointmentDetailScreen extends StatefulWidget {
  final AppointmentModel appointment;

  const AppointmentDetailScreen({super.key, required this.appointment});

  @override
  State<AppointmentDetailScreen> createState() => _AppointmentDetailScreenState();
}

class _AppointmentDetailScreenState extends State<AppointmentDetailScreen> {
  final AppointmentController _controller = AppointmentController();
  late AppointmentModel _currentAppointment;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _currentAppointment = widget.appointment;
    // We don't necessarily need to load dependencies (professionals) unless we want to change professional
    // But for now, we just want to update status.
  }

  Future<void> _updateStatus(String newStatus) async {
    setState(() => _isLoading = true);

    int? professionalId = _currentAppointment.professionalId;

    // Se estiver marcando como REALIZADO, tentamos atribuir ao profissional logado
    // caso seja um atendimento sem profissional ou reposição.
    if (newStatus == 'REALIZADO') {
      final prefs = await SharedPreferences.getInstance();
      final userIdStr = prefs.getString('user_id');
      final userRole = prefs.getString('user_role');

      if (userIdStr != null && (userRole == 'PROFISSIONAL' || userRole == 'ADMIN')) {
        professionalId = int.parse(userIdStr);
      }
    }

    final updated = AppointmentModel(
      id: _currentAppointment.id,
      packageId: _currentAppointment.packageId,
      dateTime: _currentAppointment.dateTime,
      status: newStatus,
      professionalId: professionalId,
    );

    final success = await _controller.updateAppointment(updated);

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        setState(() {
          _currentAppointment = AppointmentModel(
             id: _currentAppointment.id,
             packageId: _currentAppointment.packageId,
             dateTime: _currentAppointment.dateTime,
             status: newStatus,
             professionalId: professionalId, // Usamos o ID atualizado
             professionalName: _currentAppointment.professionalName, // O nome virá atualizado na próxima carga
             patientName: _currentAppointment.patientName,
          );
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Status atualizado para $newStatus")),
        );
        Navigator.pop(context, true); // Return true to refresh dashboard
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text("Erro: ${_controller.error}")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = _currentAppointment.dateTime != null 
        ? DateFormat('dd/MM/yyyy').format(_currentAppointment.dateTime!) 
        : "Data não definida";
    final timeStr = _currentAppointment.dateTime != null
        ? DateFormat('HH:mm').format(_currentAppointment.dateTime!)
        : "--:--";

    return Scaffold(
      appBar: AppBar(
        title: const Text("Detalhes do Atendimento"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))
                ],
                border: Border.all(color: Colors.grey.shade200)
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.blue[100],
                    child: Text(
                      _currentAppointment.patientName?.substring(0, 1).toUpperCase() ?? "P",
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue[800]),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _currentAppointment.patientName ?? "Paciente Desconhecido",
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 5),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(_currentAppointment.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _currentAppointment.status,
                      style: TextStyle(
                        color: _getStatusColor(_currentAppointment.status),
                        fontWeight: FontWeight.bold,
                        fontSize: 14
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Details
            _buildDetailRow(Icons.calendar_today, "Data", dateStr),
            const Divider(),
            _buildDetailRow(Icons.access_time, "Horário", timeStr),
            const Divider(),
            _buildDetailRow(Icons.medical_services, "Profissional", _currentAppointment.professionalName ?? "Não atribuído"),
            const Divider(),
            
            const Spacer(),

            // Actions
            if (_currentAppointment.status != 'REALIZADO' && _currentAppointment.status != 'CANCELADO') ...[
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : () => _updateStatus('REALIZADO'),
                  icon: const Icon(Icons.check_circle),
                  label: _isLoading 
                      ? const CircularProgressIndicator(color: Colors.white) 
                      : const Text("MARCAR COMO REALIZADO", style: TextStyle(fontSize: 16)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[600],
                    foregroundColor: Colors.white,
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isLoading ? null : () => _updateStatus('FALTA'),
                      icon: const Icon(Icons.close),
                      label: const Text("FALTA"),
                      style: OutlinedButton.styleFrom(
                         foregroundColor: Colors.red,
                         side: const BorderSide(color: Colors.red),
                         padding: const EdgeInsets.symmetric(vertical: 16),
                         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isLoading ? null : () => _updateStatus('CANCELADO'),
                      icon: const Icon(Icons.block),
                      label: const Text("CANCELAR"),
                      style: OutlinedButton.styleFrom(
                         foregroundColor: Colors.grey[700],
                         side: BorderSide(color: Colors.grey.shade400),
                         padding: const EdgeInsets.symmetric(vertical: 16),
                         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              )
            ] else 
              Center(
                 child: Text(
                   "Este agendamento está ${_currentAppointment.status.toLowerCase()}.",
                   style: const TextStyle(color: Colors.grey, fontSize: 16, fontStyle: FontStyle.italic),
                 ),
              )
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[600], size: 28),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            ],
          )
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'AGENDADO': return Colors.blue[800]!;
      case 'REALIZADO': return Colors.green[800]!;
      case 'CANCELADO': return Colors.grey[700]!;
      case 'FALTA': return Colors.red[800]!;
      default: return Colors.orange[800]!;
    }
  }
}
