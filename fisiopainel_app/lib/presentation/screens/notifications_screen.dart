import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/repositories/appointment_request_repository.dart';
import '../../domain/models/appointment_request_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _repository = AppointmentRequestRepository();
  List<AppointmentRequestModel> _requests = [];
  bool _isLoading = false;
  String? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadUserAndData();
  }

  Future<void> _loadUserAndData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentUser = prefs.getString('username');
    });
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    setState(() => _isLoading = true);
    try {
      final requests = await _repository.getRequests();
      setState(() {
        _requests = requests;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar notificações: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _respond(int id, String action) async {
    try {
      await _repository.respondRequest(id, action);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(action == 'ACEITAR' ? 'Solicitação aceita!' : 'Solicitação recusada!')),
        );
      }
      _loadRequests();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao responder: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_requests.isEmpty) {
      return const Center(child: Text("Nenhuma notificação encontrada."));
    }

    return ListView.builder(
      itemCount: _requests.length,
      itemBuilder: (context, index) {
        final request = _requests[index];
        final isIncoming = request.profissionalSolicitadoName == _currentUser;
        
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isIncoming ? "Solicitação Recebida" : "Solicitação Enviada",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    _buildStatusChip(request.status),
                  ],
                ),
                const SizedBox(height: 8),
                Text("De: ${request.solicitanteName}"),
                Text("Para: ${request.profissionalSolicitadoName}"),
                if (request.agendamentoDetalhes != null) ...[
                   const SizedBox(height: 4),
                   Text("Paciente: ${request.agendamentoDetalhes!.patientName ?? 'N/A'}", style: const TextStyle(fontWeight: FontWeight.bold)),
                   Text("Data: ${request.agendamentoDetalhes!.dateTime != null ? DateFormat('dd/MM/yyyy HH:mm').format(request.agendamentoDetalhes!.dateTime!) : 'Data não definida'}"),
                ],
                if (request.message != null && request.message!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text("Mensagem: ${request.message}", style: const TextStyle(fontStyle: FontStyle.italic)),
                  ),
                const SizedBox(height: 16),
                if (isIncoming && request.status == 'PENDENTE')
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: () => _respond(request.id, 'RECUSAR'),
                        style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                        child: const Text("Recusar"),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () => _respond(request.id, 'ACEITAR'),
                         style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                        child: const Text("Aceitar"),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status) {
      case 'ACEITO':
        color = Colors.green;
        break;
      case 'RECUSADO':
        color = Colors.red;
        break;
      default:
        color = Colors.orange;
    }
    return Chip(
      label: Text(status, style: const TextStyle(color: Colors.white, fontSize: 12)),
      backgroundColor: color,
      padding: EdgeInsets.zero,
    );
  }
}
