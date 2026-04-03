import 'package:fisiopainel_app/domain/models/patient_model.dart';
import 'package:flutter/material.dart';
import '../../controllers/patient_controller.dart';
import '../patients/patients_form_screen.dart';

class PatientsScreen extends StatefulWidget {
  const PatientsScreen({super.key});

  @override
  State<PatientsScreen> createState() => _PatientsScreenState();
}

class _PatientsScreenState extends State<PatientsScreen> {
  final PatientController _controller = PatientController();
  final TextEditingController _searchController = TextEditingController();

  Future<void> _openFormModal({PatientModel? patient}) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return PatientFormScreen(
          controller: _controller,
          patientToEdit: patient,
        );
      },
    );

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(patient == null ? "Paciente criado com sucesso!" : "Paciente atualizado com sucesso!"),
          backgroundColor: Colors.teal,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      if (mounted) setState(() {});
    });
    _controller.fetchPatients();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openFormModal(),
        label: const Text("Novo Paciente"),
        icon: const Icon(Icons.add),
        elevation: 4,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          children: [
            const SizedBox(height: 16),
            // --- BARRA DE BUSCA ---
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar por nome, CPF ou email...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchController.text.isNotEmpty 
                  ? IconButton(icon: const Icon(Icons.clear, size: 18), onPressed: () {
                      _searchController.clear();
                      _controller.filter("");
                    })
                  : const Icon(Icons.filter_list, size: 20),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onChanged: (val) {
                _controller.filter(val);
                setState(() {});
              },
            ),

            const SizedBox(height: 24),

            // --- LISTA DE PACIENTES ---
            Expanded(
              child: _controller.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _controller.filteredPatients.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.person_search_outlined, size: 64, color: Colors.grey[300]),
                          const SizedBox(height: 16),
                          Text("Nenhum paciente encontrado.", style: TextStyle(color: Colors.grey[500])),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _controller.filteredPatients.length,
                      itemBuilder: (context, index) {
                        final patient = _controller.filteredPatients[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.withOpacity(0.1)),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            leading: CircleAvatar(
                              radius: 24,
                              backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.05),
                              child: Text(
                                patient.completeName.isNotEmpty ? patient.completeName[0].toUpperCase() : '?',
                                style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold),
                              ),
                            ),
                            title: Text(
                              patient.completeName,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.email_outlined, size: 14, color: Colors.grey),
                                      const SizedBox(width: 4),
                                      Expanded(child: Text(patient.email ?? 'Sem email', style: const TextStyle(fontSize: 12))),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(Icons.badge_outlined, size: 14, color: Colors.grey),
                                      const SizedBox(width: 4),
                                      Text("CPF: ${patient.cpf ?? 'N/D'}", style: const TextStyle(fontSize: 12)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.edit_note, color: Colors.blueAccent),
                              onPressed: () => _openFormModal(patient: patient),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
