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

  final Map<int, List<AppointmentModel>> _appointmentsMap = {};
  final Map<int, bool> _isLoadingAppointments = {};
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
      // 1. Recarrega a lista de pacotes no controlador
      await _controller.loadData();
      
      if (package != null && package.id != null) {
        // 2. Limpa o cache local e busca agendamentos atualizados do banco
        setState(() {
          _appointmentsMap.remove(package.id);
        });
        await _fetchAppointmentsForPackage(package.id!);
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(package == null ? "Pacote criado com sucesso!" : "Pacote atualizado com sucesso!"),
          backgroundColor: Colors.teal,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _deletePackage(int packageId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Confirmar Exclusão"),
        content: const Text("Tem certeza que deseja excluir este pacote e todos os seus agendamentos?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("CANCELAR")),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("EXCLUIR", style: TextStyle(color: Colors.redAccent))),
        ],
      ),
    );

    if (confirm == true) {
      final success = await _controller.deletePackage(packageId);
      if (mounted && success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Pacote excluído com sucesso"), backgroundColor: Colors.redAccent, behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  Future<void> _fetchAppointmentsForPackage(int packageId) async {
    if (!mounted) return;
    setState(() => _isLoadingAppointments[packageId] = true);
    try {
      final appointments = await _appointmentRepo.getAppointmentsForPackage(packageId);
      if (mounted) setState(() => _appointmentsMap[packageId] = appointments);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoadingAppointments[packageId] = false);
    }
  }

  void _openBulkSchedule(int packageId, int maxSessions) async {
    if (_appointmentsMap[packageId] == null) await _fetchAppointmentsForPackage(packageId);
    final currentAppointments = _appointmentsMap[packageId]?.length ?? 0;
    
    if (currentAppointments >= maxSessions) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Todas as sessões já foram utilizadas."), backgroundColor: Colors.orange));
      return;
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (_) => BulkScheduleDialog(packageId: packageId, totalSessions: maxSessions, existingSessionsCount: currentAppointments),
    );

    if (result == true) _fetchAppointmentsForPackage(packageId);
  }

  void _editAppointment(AppointmentModel appointment) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => EditAppointmentDialog(appointment: appointment),
    );
    if (result == true) _fetchAppointmentsForPackage(appointment.packageId);
  }

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status.toUpperCase()) {
      case 'REALIZADO': color = Colors.teal; break;
      case 'AGENDADO': color = Colors.blue; break;
      case 'FALTA': color = Colors.orange; break;
      case 'CANCELADO': color = Colors.redAccent; break;
      default: color = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
      child: Text(status, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  Expanded(
                    child: _controller.isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _controller.packages.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey[300]),
                                    const SizedBox(height: 16),
                                    Text("Nenhum pacote registrado.", style: TextStyle(color: Colors.grey[500])),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.only(bottom: 20),
                                itemCount: _controller.packages.length,
                                itemBuilder: (context, index) {
                                  final pkg = _controller.packages[index];
                                  final isExpanded = _isExpandedMap[pkg.id] ?? false;
                                  
                                  final patientName = _controller.patientsList
                                      .firstWhere((p) => p.id == pkg.patientId, orElse: () => PatientModel(id: 0, completeName: 'Desconhecido'))
                                      .completeName;
                                  final serviceName = _controller.serviceTypesList
                                      .firstWhere((s) => s.id == pkg.serviceTypeId, orElse: () => ServiceTypeModel(id: 0, name: 'Desconhecido'))
                                      .name;

                                  final appointmentsCount = _appointmentsMap[pkg.id]?.length ?? 0;
                                  final progress = pkg.quantity > 0 ? appointmentsCount / pkg.quantity : 0.0;

                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: Colors.grey.withOpacity(0.1)),
                                    ),
                                    child: Column(
                                      children: [
                                        ListTile(
                                          contentPadding: const EdgeInsets.all(16),
                                          onTap: () {
                                            setState(() => _isExpandedMap[pkg.id!] = !isExpanded);
                                            if (!isExpanded && _appointmentsMap[pkg.id] == null) _fetchAppointmentsForPackage(pkg.id!);
                                          },
                                          title: Text('$patientName', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                          subtitle: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(serviceName, style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w600, fontSize: 13)),
                                              const SizedBox(height: 4),
                                              Text('R\$ ${pkg.totalValue.toStringAsFixed(2)} | ${pkg.quantity} sessões', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                                              const SizedBox(height: 12),
                                              ClipRRect(
                                                borderRadius: BorderRadius.circular(2),
                                                child: LinearProgressIndicator(
                                                  value: progress,
                                                  backgroundColor: Colors.grey[100],
                                                  color: appointmentsCount >= pkg.quantity ? Colors.teal : Colors.blue,
                                                  minHeight: 4,
                                                ),
                                              ),
                                            ],
                                          ),
                                          trailing: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(isExpanded ? Icons.expand_less : Icons.expand_more, color: Colors.grey),
                                              const SizedBox(width: 8),
                                              PopupMenuButton<String>(
                                                onSelected: (value) {
                                                  if (value == 'edit') _openForm(package: pkg);
                                                  if (value == 'delete') _deletePackage(pkg.id!);
                                                  if (value == 'bulk') _openBulkSchedule(pkg.id!, pkg.quantity);
                                                },
                                                itemBuilder: (context) => [
                                                  const PopupMenuItem(
                                                    value: 'bulk',
                                                    child: ListTile(
                                                      leading: Icon(Icons.playlist_add, color: Colors.blue),
                                                      title: Text('Agendar Lote'),
                                                      contentPadding: EdgeInsets.zero,
                                                      dense: true,
                                                    ),
                                                  ),
                                                  const PopupMenuItem(
                                                    value: 'edit',
                                                    child: ListTile(
                                                      leading: Icon(Icons.edit_outlined, color: Colors.orange),
                                                      title: Text('Editar Pacote'),
                                                      contentPadding: EdgeInsets.zero,
                                                      dense: true,
                                                    ),
                                                  ),
                                                  const PopupMenuItem(
                                                    value: 'delete',
                                                    child: ListTile(
                                                      leading: Icon(Icons.delete_outline, color: Colors.redAccent),
                                                      title: Text('Excluir Pacote'),
                                                      contentPadding: EdgeInsets.zero,
                                                      dense: true,
                                                    ),
                                                  ),
                                                ],
                                                icon: const Icon(Icons.more_vert, color: Colors.grey),
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (isExpanded) ...[
                                          const Divider(height: 1),
                                          if (_isLoadingAppointments[pkg.id] ?? false)
                                            const Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator())
                                          else if (_appointmentsMap[pkg.id] == null || _appointmentsMap[pkg.id]!.isEmpty)
                                            const Padding(padding: EdgeInsets.all(16), child: Text('Nenhum agendamento realizado.', style: TextStyle(fontSize: 12, color: Colors.grey)))
                                          else
                                            ListView.builder(
                                              shrinkWrap: true,
                                              physics: const NeverScrollableScrollPhysics(),
                                              itemCount: _appointmentsMap[pkg.id]!.length,
                                              itemBuilder: (context, i) {
                                                final appt = _appointmentsMap[pkg.id]![i];
                                                return ListTile(
                                                  dense: true,
                                                  onTap: () => _editAppointment(appt),
                                                  leading: const Icon(Icons.calendar_today_outlined, size: 16),
                                                  title: Text(appt.dateTime != null ? DateFormat('dd/MM/yyyy HH:mm').format(appt.dateTime!) : 'Data inválida', style: const TextStyle(fontSize: 13)),
                                                  trailing: _buildStatusChip(appt.status),
                                                );
                                              },
                                            ),
                                          const SizedBox(height: 16),
                                        ]
                                      ],
                                    ),
                                  );
                                },
                              ),
                  ),
                ],
              ),
            ),
          ),
          // Botão Fixo na Parte Inferior
          Container(
            padding: const EdgeInsets.all(16.0),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: ElevatedButton.icon(
              onPressed: () => _openForm(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              icon: const Icon(Icons.inventory_2_outlined),
              label: const Text(
                "NOVO PACOTE",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
