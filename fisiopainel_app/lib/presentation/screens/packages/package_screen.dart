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

  Widget _buildStatusChip(String status) {
    Color bgColor;
    Color textColor;

    switch (status.toUpperCase()) {
      case 'REALIZADO':
        bgColor = Colors.green[100]!;
        textColor = Colors.green[900]!;
        break;
      case 'AGENDADO':
        bgColor = Colors.blue[100]!;
        textColor = Colors.blue[900]!;
        break;
      case 'FALTA':
        bgColor = Colors.red[100]!;
        textColor = Colors.red[900]!;
        break;
      case 'CANCELADO':
        bgColor = Colors.grey[300]!;
        textColor = Colors.grey[800]!;
        break;
      case 'ABERTO':
        bgColor = Colors.orange[100]!;
        textColor = Colors.orange[900]!;
        break;
      default:
        bgColor = Colors.grey[200]!;
        textColor = Colors.black87;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openForm,
        label: const Text("Novo Pacote"),
        icon: const Icon(Icons.inventory),
        backgroundColor: Colors.teal[800],
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
                            if (packageId == null) return;

                            setState(() {
                              final currentlyExpanded = _isExpandedMap[packageId] ?? false;
                              _isExpandedMap[packageId] = !currentlyExpanded;
                            });

                            if ((_isExpandedMap[packageId] == true) && _appointmentsMap[packageId] == null) {
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
                                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        '$patientName - $serviceName',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                      const SizedBox(height: 8),
                                      Wrap(
                                        spacing: 12,
                                        runSpacing: 8,
                                        crossAxisAlignment: WrapCrossAlignment.center,
                                        children: [
                                          Text(
                                            'R\$ ${pkg.totalValue.toStringAsFixed(2)} - ${pkg.quantity} sessões',
                                            style: TextStyle(color: Colors.grey[700], fontSize: 13),
                                          ),
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
                                        const SizedBox(height: 12),
                                        Text(
                                          'Utilizado: $appointmentsCount / ${pkg.quantity} sessões',
                                          style: TextStyle(
                                            color: appointmentsCount >= pkg.quantity ? Colors.red : Colors.teal[700],
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        LinearProgressIndicator(
                                          value: progress,
                                          backgroundColor: Colors.grey[200],
                                          color: appointmentsCount >= pkg.quantity ? Colors.red : Colors.teal,
                                          minHeight: 6,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                      ]
                                    ],
                                  ),
                                );
                              },
                              body: Column(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                      children: [
                                        _buildActionButton(
                                          icon: Icons.edit_outlined,
                                          label: 'Editar',
                                          color: Colors.blue[700]!,
                                          onPressed: () => _editPackage(pkg),
                                        ),
                                        _buildActionButton(
                                          icon: Icons.delete_outline,
                                          label: 'Excluir',
                                          color: Colors.red[700]!,
                                          onPressed: () => _deletePackage(pkg.id!),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Divider(),
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
                                              _buildStatusChip(appt.status),
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
                                    padding: const EdgeInsets.all(16.0),
                                    child: ElevatedButton.icon(
                                      onPressed: () => _openBulkSchedule(pkg.id!, pkg.quantity),
                                      icon: const Icon(Icons.playlist_add),
                                      label: const Text('Planejar Sessões (Em Lote)'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.teal[800],
                                        foregroundColor: Colors.white,
                                        minimumSize: const Size(double.infinity, 45),
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

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
