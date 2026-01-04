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
  final TextEditingController _searchController =
      TextEditingController(); // Controlador da busca

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      setState(() {});
    });
    _controller.fetchProfessionals();
  }

  @override
  void dispose() {
    _searchController.dispose(); // Limpeza de memória
    _controller.dispose(); // Opcional, dependendo de como você gerencia injeção
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
      // Limpa a busca ao salvar com sucesso para mostrar o novo item
      _searchController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            professional == null
                ? "Cadastrado com sucesso!"
                : "Atualizado com sucesso!",
          ),
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
        onPressed: () => _openForm(),
        label: const Text("Novo Profissional"),
        icon: const Icon(Icons.person_add),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Gestão de Profissionais",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),

          // --- BARRA DE PESQUISA (Igual à de Pacientes) ---
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
                hintText: 'Buscar por nome, CPF, CREFITO ou usuário...',
                border: InputBorder.none,
                prefixIcon: Icon(Icons.search),
                suffixIcon: Icon(Icons.filter_list),
              ),
              onChanged:
                  _controller.filter, // Chama o filtro a cada letra digitada
            ),
          ),
          const SizedBox(height: 20),

          // --- LISTA FILTRADA ---
          Expanded(
            child: _controller.isLoading
                ? const Center(child: CircularProgressIndicator())
                : _controller.filteredProfessionals.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.person_off,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _searchController.text.isEmpty
                              ? "Nenhum profissional cadastrado."
                              : "Nenhum resultado para '${_searchController.text}'",
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    itemCount: _controller.filteredProfessionals.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    // ... dentro do itemBuilder ...
                    itemBuilder: (context, index) {
                      final prof = _controller.filteredProfessionals[index];

                      // Define se o item parece "apagado"
                      final isInactive = !prof.isActive;

                      return Card(
                        elevation: 2,
                        // Se inativo, fundo cinza claro. Se ativo, branco.
                        color: isInactive ? Colors.grey[200] : Colors.white,
                        child: ListTile(
                          leading: CircleAvatar(
                            // Se inativo, avatar cinza
                            backgroundColor: isInactive
                                ? Colors.grey
                                : Colors.green[100],
                            child: Text(
                              prof.firstName.isNotEmpty
                                  ? prof.firstName[0].toUpperCase()
                                  : '?',
                              style: TextStyle(
                                color: isInactive
                                    ? Colors.white
                                    : Colors.green[800],
                              ),
                            ),
                          ),
                          title: Text(
                            prof.fullName,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              // Se inativo, risca o nome
                              decoration: isInactive
                                  ? TextDecoration.lineThrough
                                  : null,
                              color: isInactive ? Colors.grey : Colors.black,
                            ),
                          ),
                          subtitle: Text(
                            isInactive
                                ? "ACESSO BLOQUEADO"
                                : "Usuário: ${prof.username}",
                          ),

                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Botão de Editar (Só mostra se estiver ativo, opcional)
                              if (!isInactive)
                                IconButton(
                                  icon: const Icon(
                                    Icons.edit,
                                    color: Colors.orange,
                                  ),
                                  onPressed: () =>
                                      _openForm(professional: prof),
                                ),

                              const SizedBox(width: 8),

                              // --- BOTÃO DE SOFT DELETE / RESTAURAR CORRIGIDO ---
                              IconButton(
                                tooltip: isInactive
                                    ? "Reativar Acesso"
                                    : "Bloquear Acesso",
                                icon: Icon(
                                  isInactive
                                      ? Icons.restore_from_trash
                                      : Icons.delete_forever,
                                  color: isInactive ? Colors.green : Colors.red,
                                ),
                                onPressed: () {
                                  // 1. CAPTURA O MESSENGER AQUI FORA (Do contexto da Lista, que é seguro)
                                  final messenger = ScaffoldMessenger.of(
                                    context,
                                  );

                                  showDialog(
                                    context: context,
                                    builder: (dialogContext) => AlertDialog(
                                      title: Text(
                                        isInactive
                                            ? 'Reativar Profissional?'
                                            : 'Bloquear Profissional?',
                                      ),
                                      content: Text(
                                        isInactive
                                            ? 'O profissional poderá acessar o sistema novamente.'
                                            : 'Tem certeza? O profissional perderá o acesso ao sistema imediatamente.',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(
                                            dialogContext,
                                          ), // Fecha usando o contexto do diálogo
                                          child: const Text('Cancelar'),
                                        ),

                                        TextButton(
                                          onPressed: () async {
                                            // 2. Fecha o alerta imediatamente
                                            Navigator.pop(dialogContext);

                                            // 3. Executa a operação que vai reconstruir a tela
                                            final success = await _controller
                                                .toggleProfessionalStatus(prof);

                                            // 4. Usa o 'messenger' capturado lá no passo 1
                                            // Não usamos 'context' aqui, pois ele já "morreu"
                                            if (success) {
                                              messenger.showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    isInactive
                                                        ? "Acesso restaurado!"
                                                        : "Profissional bloqueado!",
                                                  ),
                                                  backgroundColor: isInactive
                                                      ? Colors.green
                                                      : Colors.red,
                                                ),
                                              );
                                            }
                                          },
                                          child: Text(
                                            isInactive
                                                ? 'REATIVAR'
                                                : 'BLOQUEAR',
                                            style: TextStyle(
                                              color: isInactive
                                                  ? Colors.green
                                                  : Colors.red,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
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
    );
  }
}
