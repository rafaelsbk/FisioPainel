import 'package:fisiopainel_app/domain/models/patient_model.dart';
import 'package:flutter/material.dart';
import '../../controllers/patient_controller.dart';
import '../patients/patients_form_screen.dart';

class PatientsScreen extends StatefulWidget {
  const PatientsScreen({super.key});

  @override
  State<PatientsScreen> createState() => _PatientsScreenState();
}

class _PackagesScreenState {} // Ignorar, erro de copia anterior

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
    _controller.addListener(_onControllerChange);
    _controller.fetchPatients();
  }

  void _onControllerChange() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChange);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
        child: ElevatedButton.icon(
          onPressed: () => _openFormModal(),
          icon: const Icon(Icons.person_add_outlined),
          label: const Text("ADICIONAR NOVO PACIENTE"),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          children: [
            const SizedBox(height: 16),
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
              },
            ),

            const SizedBox(height: 24),

            Expanded(
              child: _controller.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: _controller.fetchPatients,
                      child: _controller.error.isNotEmpty
                          ? ListView(
                              children: [
                                SizedBox(height: MediaQuery.of(context).size.height * 0.2),
                                Center(
                                  child: Column(
                                    children: [
                                      const Icon(Icons.error_outline, size: 64, color: Colors.redAccent),
                                      const SizedBox(height: 16),
                                      Text("Erro: ${_controller.error}", 
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(color: Colors.redAccent)),
                                      TextButton(onPressed: _controller.fetchPatients, child: const Text("TENTAR NOVAMENTE"))
                                    ],
                                  ),
                                )
                              ],
                            )
                          : _controller.filteredPatients.isEmpty
                          ? ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              children: [
                                SizedBox(height: MediaQuery.of(context).size.height * 0.2),
                                Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.person_search_outlined, size: 64, color: Colors.grey[300]),
                                      const SizedBox(height: 16),
                                      Text("Nenhum paciente encontrado.", style: TextStyle(color: Colors.grey[500])),
                                    ],
                                  ),
                                ),
                              ],
                            )
                          : ListView.builder(
                              physics: const AlwaysScrollableScrollPhysics(),
                              itemCount: _controller.filteredPatients.length,
                              itemBuilder: (context, index) {
                                final patient = _controller.filteredPatients[index];
                                return Opacity(
                                  opacity: patient.isActive ? 1.0 : 0.5,
                                  child: Container(
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
                                        backgroundColor: patient.isActive 
                                          ? Theme.of(context).colorScheme.primary.withOpacity(0.05)
                                          : Colors.grey.withOpacity(0.2),
                                        child: Text(
                                          patient.completeName.isNotEmpty ? patient.completeName[0].toUpperCase() : '?',
                                          style: TextStyle(
                                            color: patient.isActive ? Theme.of(context).colorScheme.primary : Colors.grey, 
                                            fontWeight: FontWeight.bold
                                          ),
                                        ),
                                      ),
                                      title: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              patient.completeName,
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          if (!patient.isActive)
                                            Padding(
                                              padding: const EdgeInsets.only(left: 8.0),
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: Colors.grey[200],
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: const Text('INATIVO', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                                              ),
                                            ),
                                        ],
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
                                  ),
                                );
                              },
                            ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
