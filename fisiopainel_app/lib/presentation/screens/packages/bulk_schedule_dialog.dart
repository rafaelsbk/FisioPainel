import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../controllers/appointment_controller.dart';
import '../../controllers/notification_controller.dart';
import '../../../domain/models/appointment_model.dart';
import '../../../data/repositories/appointment_request_repository.dart';
import '../../../domain/models/appointment_request_model.dart';

class BulkScheduleDialog extends StatefulWidget {
  final int packageId;
  final int totalSessions;
  final int existingSessionsCount;

  const BulkScheduleDialog({
    super.key,
    required this.packageId,
    required this.totalSessions,
    required this.existingSessionsCount,
  });

  @override
  State<BulkScheduleDialog> createState() => _BulkScheduleDialogState();
}

class _AppointmentDraft {
  DateTime? date;
  TimeOfDay? time;
  int? professionalId;
  TextEditingController dateCtrl = TextEditingController();

  bool get isValid => date != null && time != null;
}

class _BulkScheduleDialogState extends State<BulkScheduleDialog> {
  final AppointmentController _controller = AppointmentController();
  List<_AppointmentDraft> _drafts = [];
  bool _isSubmitting = false;
  int? _globalProfessionalId;
  int? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadUserAndData();
  }

  Future<void> _loadUserAndData() async {
    final prefs = await SharedPreferences.getInstance();
    // Decodificar o JWT para pegar o ID do usuario logado (user_id)
    // Para facilitar, vamos assumir que salvamos o user_id no login_controller
    // mas se nao salvamos, vamos buscar do token ou SharedPreferences se disponivel
    final userIdStr = prefs.getString('user_id');
    if (userIdStr != null) {
      _currentUserId = int.tryParse(userIdStr);
    }

    await _controller.loadDependencies();
    
    // Se o usuario logado estiver na lista de profissionais, define como padrao
    if (_currentUserId != null) {
      setState(() {
        _globalProfessionalId = _currentUserId;
        _initializeDrafts();
      });
    } else {
      if (mounted) setState(() => _initializeDrafts());
    }
  }

  void _initializeDrafts() {
    int remaining = widget.totalSessions - widget.existingSessionsCount;
    if (remaining < 0) remaining = 0;
    
    _drafts = List.generate(remaining, (index) {
      final d = _AppointmentDraft();
      d.professionalId = _globalProfessionalId; // Define o padrao inicial
      return d;
    });
  }

  // Atualiza todos os rascunhos com o profissional selecionado
  void _applyGlobalProfessional(int? id) {
    setState(() {
      _globalProfessionalId = id;
      for (var draft in _drafts) {
        draft.professionalId = id;
      }
    });
  }

  Future<void> _pickDateTime(int index) async {
    final draft = _drafts[index];
    final date = await showDatePicker(
      context: context,
      initialDate: draft.date ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    
    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: draft.time ?? const TimeOfDay(hour: 8, minute: 0),
      );
      
      if (time != null) {
        setState(() {
          draft.date = date;
          draft.time = time;
          final dt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
          draft.dateCtrl.text = DateFormat('dd/MM/yyyy HH:mm').format(dt);
        });
      }
    }
  }

  Future<void> _submit() async {
    setState(() => _isSubmitting = true);

    // Filter valid drafts
    final validDrafts = _drafts.where((d) => d.isValid).toList();

    if (validDrafts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Preencha pelo menos um agendamento com Data/Hora.")),
      );
      setState(() => _isSubmitting = false);
      return;
    }

    int successCount = 0;
    int requestCount = 0;
    final requestRepo = AppointmentRequestRepository();

    for (var draft in validDrafts) {
      final dt = DateTime(
        draft.date!.year,
        draft.date!.month,
        draft.date!.day,
        draft.time!.hour,
        draft.time!.minute,
      );

      // Check if it's a request (different professional)
      // Se _currentUserId for nulo (não logado?), assume que é request se professionalId não for nulo
      // Mas assumimos _currentUserId carregado.
      final isRequest = draft.professionalId != null && _currentUserId != null && draft.professionalId != _currentUserId;

      final appointment = AppointmentModel(
        id: 0,
        packageId: widget.packageId,
        dateTime: dt,
        status: 'AGENDADO',
        professionalId: isRequest ? null : draft.professionalId,
      );

      final created = await _controller.createAppointment(appointment);
      if (created != null) {
        if (isRequest) {
           try {
             final request = AppointmentRequestModel(
               id: 0,
               solicitanteId: _currentUserId ?? 0,
               solicitanteName: '',
               profissionalSolicitadoId: draft.professionalId!,
               profissionalSolicitadoName: '',
               agendamentoId: created.id,
               status: 'PENDENTE',
               dataCriacao: DateTime.now(),
               message: 'Solicitação de agendamento via pacote',
             );
             
             await requestRepo.createRequest(request);
             requestCount++;
           } catch (e) {
             print("Erro ao criar solicitação: $e");
           }
        } else {
           successCount++;
        }
      }
    }

    // Refresh notification count just in case (though these are outgoing requests, 
    // maybe we want to see them? The current count logic includes outgoing responses, not outgoing requests pending)
    // But it's good practice.
    NotificationController().fetchCount();

    if (mounted) {
      setState(() => _isSubmitting = false);
      Navigator.pop(context, true); // Retorna true para recarregar
      
      String msg = "";
      if (successCount > 0) msg += "$successCount agendamentos criados. ";
      if (requestCount > 0) msg += "$requestCount solicitações enviadas.";
      
      if (msg.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 800, maxHeight: 800),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Planejar Agendamentos', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close))
              ],
            ),
            const SizedBox(height: 10),
            
            // --- HEADER DE SELEÇÃO EM MASSA ---
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!)
              ),
              child: Row(
                children: [
                  const Icon(Icons.person_search, color: Colors.blue),
                  const SizedBox(width: 10),
                  const Text("Profissional Padrão:", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      decoration: const InputDecoration(
                        isDense: true,
                        border: InputBorder.none,
                      ),
                      hint: const Text("Selecione para aplicar a todos..."),
                      value: _globalProfessionalId,
                      items: _controller.professionalsList.map((p) {
                        return DropdownMenuItem(
                          value: p.id,
                          child: Text(p.fullName),
                        );
                      }).toList(),
                      onChanged: _applyGlobalProfessional,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            
            Text('Restam ${_drafts.length} sessões para agendar.'),
            const Divider(),
            
            Expanded(
              child: _controller.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _drafts.isEmpty
                      ? const Center(child: Text("Todas as sessões já foram agendadas!"))
                      : ListView.builder(
                          itemCount: _drafts.length,
                          itemBuilder: (ctx, i) {
                            final draft = _drafts[i];
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    CircleAvatar(child: Text('${i + 1}')),
                                    const SizedBox(width: 15),
                                    Expanded(
                                      flex: 2,
                                      child: TextFormField(
                                        controller: draft.dateCtrl,
                                        readOnly: true,
                                        decoration: const InputDecoration(
                                          labelText: 'Data e Hora',
                                          prefixIcon: Icon(Icons.calendar_today),
                                          isDense: true,
                                          border: OutlineInputBorder(),
                                        ),
                                        onTap: () => _pickDateTime(i),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      flex: 2,
                                      child: DropdownButtonFormField<int>(
                                        decoration: const InputDecoration(
                                          labelText: 'Profissional',
                                          isDense: true,
                                          border: OutlineInputBorder(),
                                        ),
                                        value: draft.professionalId,
                                        items: _controller.professionalsList.map((p) {
                                          return DropdownMenuItem(
                                            value: p.id,
                                            child: Text(p.fullName, overflow: TextOverflow.ellipsis),
                                          );
                                        }).toList(),
                                        onChanged: (val) => setState(() => draft.professionalId = val),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSubmitting || _drafts.isEmpty ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[800],
                  foregroundColor: Colors.white,
                ),
                child: _isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('SALVAR AGENDAMENTOS'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}