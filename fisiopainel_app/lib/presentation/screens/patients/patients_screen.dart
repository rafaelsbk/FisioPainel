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

  // Função para abrir o Modal
  Future<void> _openFormModal({PatientModel? patient}) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false, // Obriga a clicar no X ou Salvar para fechar
      builder: (context) {
        return PatientFormScreen(
          controller: _controller,
          patientToEdit: patient,
        );
      },
    );

    // Verifica se retornou true (sucesso)
    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            patient == null
                ? "Paciente criado com sucesso!"
                : "Paciente atualizado com sucesso!",
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating, // Fica mais bonito flutuando
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      setState(() {});
    });
    _controller.fetchPatients(); // Carrega os dados ao abrir
  }

  @override
  void dispose() {
    _controller.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Usamos Scaffold aqui apenas para ter o FloatingActionButton facilmente
    // O backgroundColor transparente permite ver o fundo cinza do BaseLayout
    return Scaffold(
      backgroundColor: Colors.transparent,

      // BOTÃO FIXO DE CRIAR NOVO PACIENTE
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openFormModal(), // Chama sem parâmetros (criação)
        label: const Text("Novo Paciente"),
        icon: const Icon(Icons.add),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // --- BARRA DE BUSCA ---
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Buscar por nome, CPF ou email...',
                border: InputBorder.none,
                prefixIcon: Icon(Icons.search),
                suffixIcon: Icon(Icons.filter_list), // Ícone visual de filtro
              ),
              onChanged: _controller.filter,
            ),
          ),

          const SizedBox(height: 20),

          // --- LISTA DE PACIENTES ---
          Expanded(
            child: _controller.isLoading
                ? const Center(child: CircularProgressIndicator())
                : _controller.filteredPatients.isEmpty
                ? const Center(child: Text("Nenhum paciente encontrado."))
                : ListView.separated(
                    itemCount: _controller.filteredPatients.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final patient = _controller.filteredPatients[index];
                      return Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.blue[100],
                            // CORREÇÃO 1: Usar completeName
                            child: Text(
                              patient.completeName.isNotEmpty
                                  ? patient.completeName[0].toUpperCase()
                                  : '?',
                              style: TextStyle(color: Colors.blue[800]),
                            ),
                          ),
                          // CORREÇÃO 2: Usar completeName
                          title: Text(
                            patient.completeName,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                          // CORREÇÃO 3: Adicionar tratamento para campos nulos (email/cpf)
                          subtitle: Text(
                            "${patient.email ?? 'Sem email'}\nCPF: ${patient.cpf ?? 'Sem CPF'}",
                            overflow: TextOverflow.ellipsis,
                          ),
                          isThreeLine: true,
                          trailing: IconButton(
                            icon: const Icon(Icons.edit, color: Colors.orange),
                            tooltip: 'Editar',
                            onPressed: () => _openFormModal(
                              patient: patient,
                            ), // Passa o paciente
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
