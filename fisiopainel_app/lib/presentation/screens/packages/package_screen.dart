import 'package:fisiopainel_app/data/repositories/appointment_repository.dart';
import 'package:fisiopainel_app/domain/models/appointment_model.dart';
import 'package:fisiopainel_app/domain/models/patient_model.dart';
import 'package:fisiopainel_app/domain/models/service_type_model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../controllers/package_controller.dart';
import 'package_form_screen.dart';
import 'bulk_schedule_dialog.dart';
import 'edit_appointment_dialog.dart';
import '../../../domain/models/package_model.dart';

class PackagesScreen extends StatefulWidget {
  const PackagesScreen({super.key});

  @override
  State<PackagesScreen> createState() => _PackagesScreenState();
}

class _PackagesScreenState extends State<PackagesScreen> {
  final PackageController _controller = PackageController();
  final AppointmentRepository _appointmentRepo = AppointmentRepository();

  // Mapa para guardar a lista de agendamentos de cada pacote (cache)
  final Map<int, List<AppointmentModel>> _appointmentsMap = {};
  // Mapa para controlar o estado de carregamento de cada pacote
  final Map<int, bool> _isLoadingAppointments = {};
   // Estado para controlar qual painel está expandido
  final Map<int, bool> _isExpandedMap = {};


  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      if (mounted) setState(() {});
    });
    _controller.loadData();
  }

  void _openForm({PackageModel? package}) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => PackageFormScreen(
        controller: _controller,
        package: package,
      ),
    );

    if (result == true && mounted) {
      final message = package == null
          ? "Pacote criado com sucesso!"
          : "Pacote atualizado com sucesso!";
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _editPackage(PackageModel package) {
    _openForm(package: package);
  }

  void _deletePackage(int packageId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Confirmar Exclusão"),
        content: const Text("Tem certeza que deseja excluir este pacote e todos os seus agendamentos?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancelar"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Excluir", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await _controller.deletePackage(packageId);
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Pacote excluído com sucesso"),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_controller.error.isNotEmpty
                  ? _controller.error
                  : "Erro ao excluir pacote"),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  // Busca os agendamentos de um pacote específico
  Future<void> _fetchAppointmentsForPackage(int packageId) async {
    if (!mounted) return;
    setState(() {
      _isLoadingAppointments[packageId] = true;
    });

    try {
      final appointments =
          await _appointmentRepo.getAppointmentsForPackage(packageId);
      if (mounted) {
        setState(() {
          _appointmentsMap[packageId] = appointments;
        });
      }
    } catch (e) {
      print('Erro ao buscar agendamentos: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao buscar agendamentos: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingAppointments[packageId] = false;
        });
      }
    }
  }

  void _openBulkSchedule(int packageId, int maxSessions) async {
    // Garante que temos a contagem atualizada
    if (_appointmentsMap[packageId] == null) {
      await _fetchAppointmentsForPackage(packageId);
    }
    
    final currentAppointments = _appointmentsMap[packageId]?.length ?? 0;
    
    if (currentAppointments >= maxSessions) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Todas as sessões deste pacote já foram utilizadas."),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    if (!mounted) return;

    final result = await showDialog<bool>(
      context: context,
      builder: (_) => BulkScheduleDialog(
        packageId: packageId,
        totalSessions: maxSessions,
        existingSessionsCount: currentAppointments,
      ),
    );

    if (result == true) {
      // Recarrega os agendamentos do pacote
      _fetchAppointmentsForPackage(packageId);
    }
  }

  void _editAppointment(AppointmentModel appointment) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => EditAppointmentDialog(appointment: appointment),
    );

    if (result == true) {
      _fetchAppointmentsForPackage(appointment.packageId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Agendamento atualizado com sucesso!"),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openForm,
        label: const Text("Novo Pacote"),
        icon: const Icon(Icons.inventory),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Gestão de Pacotes",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: _controller.isLoading
                ? const Center(child: CircularProgressIndicator())
                : _controller.packages.isEmpty
                    ? const Center(child: Text("Nenhum pacote registrado."))
                    : SingleChildScrollView(
                        child: ExpansionPanelList(
                          expansionCallback: (int index, bool isExpanded) {
                            final packageId = _controller.packages[index].id;
                            if (packageId == null) {
                              print('Erro: Pacote sem ID no índice $index');
                              return;
                            }
                            
                            // Log para depuração
                            print('Clicou no pacote $packageId. Estado atual (map): ${_isExpandedMap[packageId]}');

                            setState(() {
                              // Inverte o estado atual baseado no mapa
                              final currentlyExpanded = _isExpandedMap[packageId] ?? false;
                              _isExpandedMap[packageId] = !currentlyExpanded;
                            });

                            // Se agora está expandido (valor novo no mapa é true) e não tem dados, busca.
                            if ((_isExpandedMap[packageId] == true) && _appointmentsMap[packageId] == null) {
                               print('Buscando agendamentos para o pacote $packageId...');
                              _fetchAppointmentsForPackage(packageId);
                            }
                          },
                          children: _controller.packages.map<ExpansionPanel>((PackageModel pkg) {
                             final patientName = _controller.patientsList
                                .firstWhere((p) => p.id == pkg.patientId, orElse: () => PatientModel(id: 0, completeName: 'Desconhecido'))
                                .completeName;
                             final serviceName = _controller.serviceTypesList
                                .firstWhere((s) => s.id == pkg.serviceTypeId, orElse: () => ServiceTypeModel(id: 0, name: 'Desconhecido'))
                                .name;

                             final appointmentsCount = _appointmentsMap[pkg.id]?.length ?? 0;
                             final progress = pkg.quantity > 0 ? appointmentsCount / pkg.quantity : 0.0;

                            return ExpansionPanel(
                              canTapOnHeader: true,
                              isExpanded: _isExpandedMap[pkg.id] ?? false,
                              headerBuilder: (BuildContext context, bool isExpanded) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                                  child: Row(
                                    children: [
                                      // Coluna de Texto (Nome e Status)
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              '$patientName - $serviceName',
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                Text(
                                                  'R\$ ${pkg.totalValue.toStringAsFixed(2)} - ${pkg.quantity} sessões',
                                                  style: TextStyle(color: Colors.grey[700], fontSize: 13),
                                                ),
                                                const SizedBox(width: 10),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: pkg.status == "ATIVO" ? Colors.green[100] : Colors.grey[200],
                                                    borderRadius: BorderRadius.circular(12),
                                                  ),
                                                  child: Text(
                                                    pkg.status,
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.bold,
                                                      color: pkg.status == "ATIVO" ? Colors.green[800] : Colors.black54,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            if (_isExpandedMap[pkg.id] ?? false) ...[
                                              const SizedBox(height: 8),
                                              Text(
                                                'Utilizado: $appointmentsCount / ${pkg.quantity} sessões',
                                                style: TextStyle(
                                                  color: appointmentsCount >= pkg.quantity ? Colors.red : Colors.green[700],
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              SizedBox(
                                                width: 200, // Limita largura da barra
                                                child: LinearProgressIndicator(
                                                  value: progress,
                                                  backgroundColor: Colors.grey[200],
                                                  color: appointmentsCount >= pkg.quantity ? Colors.red : Colors.green,
                                                  minHeight: 4,
                                                ),
                                              ),
                                            ]
                                          ],
                                        ),
                                      ),
                                      // Coluna de Botões
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: Icon(Icons.playlist_add, color: Colors.indigo[700]),
                                            tooltip: 'Planejar Sessões',
                                            onPressed: () => _openBulkSchedule(pkg.id!, pkg.quantity),
                                          ),
                                          IconButton(
                                            icon: Icon(Icons.edit, color: Colors.blue[800]),
                                            onPressed: () => _editPackage(pkg),
                                          ),
                                          IconButton(
                                            icon: Icon(Icons.delete, color: Colors.red[800]),
                                            onPressed: () => _deletePackage(pkg.id!),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              },
                              body: Column(
                                children: [
                                  if (_isLoadingAppointments[pkg.id] ?? false)
                                    const Padding(
                                      padding: EdgeInsets.all(16.0),
                                      child: CircularProgressIndicator(),
                                    )
                                  else if (_appointmentsMap[pkg.id] == null || _appointmentsMap[pkg.id]!.isEmpty)
                                    const ListTile(title: Text('Nenhum agendamento realizado.'))
                                  else
                                    Column(
                                      children: _appointmentsMap[pkg.id]!.map((appt) {
                                        return ListTile(
                                          leading: const Icon(Icons.calendar_today),
                                          title: Text(appt.dateTime != null ? DateFormat('dd/MM/yyyy HH:mm').format(appt.dateTime!) : 'Data inválida'),
                                          subtitle: Text('Profissional: ${appt.professionalName ?? 'Não definido'}'),
                                          trailing: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Chip(label: Text(appt.status)),
                                              const SizedBox(width: 8),
                                              IconButton(
                                                icon: const Icon(Icons.edit, color: Colors.blue),
                                                onPressed: () => _editAppointment(appt),
                                              ),
                                            ],
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  const Divider(),
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 16.0),
                                    child: ElevatedButton.icon(
                                      onPressed: () => _openBulkSchedule(pkg.id!, pkg.quantity),
                                      icon: const Icon(Icons.playlist_add),
                                      label: const Text('Planejar Sessões (Em Lote)'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.indigo[700],
                                        foregroundColor: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
