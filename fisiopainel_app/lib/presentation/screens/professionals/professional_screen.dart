import 'package:flutter/material.dart';
import '../../controllers/professional_controller.dart';
import '../../../domain/models/professional_model.dart';
import 'professional_form_screen.dart';

class ProfessionalsScreen extends StatefulWidget {
  const ProfessionalsScreen({super.key});

  @override
  State<ProfessionalsScreen> createState() => _ProfessionalsScreenState();
}

class _ProfessionalsScreenState extends State<ProfessionalsScreen> {
  final ProfessionalController _controller = ProfessionalController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      if (mounted) setState(() {});
    });
    _controller.fetchProfessionals();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openForm({ProfessionalModel? professional}) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ProfessionalFormScreen(
        controller: _controller,
        professionalToEdit: professional,
      ),
    );

    if (result == true && mounted) {
      _searchController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(professional == null ? "Cadastrado com sucesso!" : "Atualizado com sucesso!"),
          backgroundColor: Colors.teal,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
        child: ElevatedButton.icon(
          onPressed: () => _openForm(),
          icon: const Icon(Icons.person_add_alt_1),
          label: const Text("ADICIONAR NOVO PROFISSIONAL"),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            // --- BARRA DE PESQUISA ---
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar por nome, CPF, CREFITO ou usuário...',
                prefixIcon: const Icon(Icons.search, size: 20),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onChanged: _controller.filter,
            ),
            const SizedBox(height: 24),

            // --- LISTA FILTRADA ---
            Expanded(
              child: _controller.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _controller.error.isNotEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, size: 64, color: Colors.redAccent),
                          const SizedBox(height: 16),
                          Text("Erro ao carregar profissionais:", style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.bold)),
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text(_controller.error, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[600])),
                          ),
                          ElevatedButton(onPressed: _controller.fetchProfessionals, child: const Text("TENTAR NOVAMENTE")),
                        ],
                      ),
                    )
                  : _controller.filteredProfessionals.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.person_off_outlined, size: 64, color: Colors.grey[300]),
                          const SizedBox(height: 16),
                          Text("Nenhum profissional encontrado.", style: TextStyle(color: Colors.grey[500])),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _controller.filteredProfessionals.length,
                      itemBuilder: (context, index) {
                        final prof = _controller.filteredProfessionals[index];
                        final isInactive = !prof.isActive;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: isInactive ? Colors.grey[50] : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.withOpacity(0.1)),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            leading: CircleAvatar(
                              radius: 24,
                              backgroundColor: isInactive ? Colors.grey[200] : Theme.of(context).colorScheme.primary.withOpacity(0.05),
                              child: Text(
                                prof.firstName.isNotEmpty ? prof.firstName[0].toUpperCase() : '?',
                                style: TextStyle(
                                  color: isInactive ? Colors.grey : Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.bold
                                ),
                              ),
                            ),
                            title: Text(
                              prof.fullName,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                decoration: isInactive ? TextDecoration.lineThrough : null,
                                color: isInactive ? Colors.grey : Colors.black87,
                              ),
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Text(
                                isInactive ? "ACESSO BLOQUEADO" : "Usuário: ${prof.username} | CREFITO: ${prof.crefito ?? 'N/D'}",
                                style: TextStyle(color: isInactive ? Colors.red[300] : Colors.grey[600], fontSize: 12),
                              ),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (!isInactive)
                                  IconButton(
                                    icon: const Icon(Icons.edit_note, color: Colors.blueAccent),
                                    onPressed: () => _openForm(professional: prof),
                                  ),
                                IconButton(
                                  icon: Icon(
                                    isInactive ? Icons.lock_open : Icons.lock_outline,
                                    color: isInactive ? Colors.green : Colors.redAccent,
                                    size: 20,
                                  ),
                                  onPressed: () => _showToggleStatusDialog(prof, isInactive),
                                ),
                              ],
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

  void _showToggleStatusDialog(ProfessionalModel prof, bool isInactive) {
    final messenger = ScaffoldMessenger.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isInactive ? 'Reativar Profissional?' : 'Bloquear Profissional?'),
        content: Text(isInactive 
          ? 'O profissional poderá acessar o sistema novamente.' 
          : 'O profissional perderá o acesso ao sistema imediatamente.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCELAR')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await _controller.toggleProfessionalStatus(prof);
              if (success) {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(isInactive ? "Acesso restaurado!" : "Profissional bloqueado!"),
                    backgroundColor: isInactive ? Colors.green : Colors.redAccent,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: Text(isInactive ? 'REATIVAR' : 'BLOQUEAR', style: TextStyle(color: isInactive ? Colors.green : Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}
