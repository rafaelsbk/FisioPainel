import 'package:flutter/material.dart';
import '../../controllers/service_type_controller.dart';

class ServiceTypeScreen extends StatefulWidget {
  const ServiceTypeScreen({super.key});

  @override
  State<ServiceTypeScreen> createState() => _ServiceTypeScreenState();
}

class _ServiceTypeScreenState extends State<ServiceTypeScreen> {
  final ServiceTypeController _controller = ServiceTypeController();
  final TextEditingController _nameCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      if (mounted) setState(() {});
    });
    _controller.loadData();
  }

  void _addType() async {
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Novo Tipo de Atendimento"),
        content: TextField(
          controller: _nameCtrl,
          decoration: const InputDecoration(labelText: "Nome (Ex: RPG)"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancelar")),
          TextButton(
            onPressed: () => Navigator.pop(ctx, _nameCtrl.text),
            child: const Text("Salvar"),
          ),
        ],
      ),
    );

    if (name != null && name.isNotEmpty) {
      _nameCtrl.clear();
      final success = await _controller.create(name);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Criado com sucesso!"), backgroundColor: Colors.green),
        );
      }
    }
  }

  void _deleteType(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Excluir Tipo"),
        content: const Text("Tem certeza?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancelar")),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Excluir", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await _controller.delete(id);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Excluído com sucesso!"), backgroundColor: Colors.green),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
        child: ElevatedButton.icon(
          onPressed: _addType,
          icon: const Icon(Icons.add),
          label: const Text("ADICIONAR NOVO TIPO"),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _controller.isLoading
                ? const Center(child: CircularProgressIndicator())
                : _controller.list.isEmpty
                    ? const Center(child: Text("Nenhum tipo cadastrado."))
                    : ListView.builder(
                        itemCount: _controller.list.length,
                        itemBuilder: (ctx, i) {
                          final item = _controller.list[i];
                          return Card(
                            child: ListTile(
                              title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _deleteType(item.id),
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
