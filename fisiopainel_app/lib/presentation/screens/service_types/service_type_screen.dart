import 'package:flutter/material.dart';
import '../../controllers/service_type_controller.dart';
import '../../../domain/models/service_type_model.dart';

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

  Future<void> _showForm({ServiceTypeModel? item}) async {
    _nameCtrl.text = item?.name ?? '';
    String hexColor = item?.color ?? '#406657';
    bool isActive = item?.isActive ?? true;

    final List<String> presetColors = [
      '#406657', '#2E7D32', '#1565C0', '#C62828', '#AD1457', 
      '#6A1B9A', '#4527A0', '#00838F', '#00695C', '#EF6C00',
      '#D84315', '#4E342E', '#37474F'
    ];

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(item == null ? "Novo Tipo de Atendimento" : "Editar Tipo"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(labelText: "Nome (Ex: RPG)"),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Color(int.parse(hexColor.replaceFirst('#', '0xFF'))),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        decoration: const InputDecoration(
                          labelText: "Cor (HEX)",
                          hintText: "#RRGGBB",
                        ),
                        onChanged: (val) {
                          if (val.length == 7 && val.startsWith('#')) {
                            setDialogState(() => hexColor = val);
                          }
                        },
                        controller: TextEditingController(text: hexColor)..selection = TextSelection.fromPosition(TextPosition(offset: hexColor.length)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text("Cores Sugeridas:", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: presetColors.map((color) => GestureDetector(
                    onTap: () => setDialogState(() => hexColor = color),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Color(int.parse(color.replaceFirst('#', '0xFF'))),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: hexColor == color ? Colors.black : Colors.transparent,
                          width: 2,
                        ),
                      ),
                    ),
                  )).toList(),
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text("Atendimento Ativo"),
                  value: isActive,
                  onChanged: (val) => setDialogState(() => isActive = val),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancelar")),
            TextButton(
              onPressed: () => Navigator.pop(ctx, {
                'name': _nameCtrl.text,
                'color': hexColor,
                'isActive': isActive,
              }),
              child: const Text("Salvar"),
            ),
          ],
        ),
      ),
    );

    if (result != null && result['name'].isNotEmpty) {
      bool success;
      if (item == null) {
        success = await _controller.create(result['name'], result['color']);
      } else {
        success = await _controller.update(item.id, result['name'], result['color'], result['isActive']);
      }

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(item == null ? "Criado com sucesso!" : "Atualizado com sucesso!"),
            backgroundColor: Colors.green,
          ),
        );
      }
      _nameCtrl.clear();
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
          onPressed: () => _showForm(),
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
                : RefreshIndicator(
                    onRefresh: _controller.loadData,
                    child: _controller.list.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              SizedBox(height: MediaQuery.of(context).size.height * 0.2),
                              const Center(child: Text("Nenhum tipo cadastrado.")),
                            ],
                          )
                        : ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            itemCount: _controller.list.length,
                            itemBuilder: (ctx, i) {
                          final item = _controller.list[i];
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              title: Row(
                                children: [
                                  Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  const SizedBox(width: 8),
                                  if (!item.isActive)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.red[100],
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text(
                                        "INATIVO",
                                        style: TextStyle(fontSize: 10, color: Colors.red, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                                    onPressed: () => _showForm(item: item),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                                    onPressed: () => _deleteType(item.id),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
          ),
        ],
      ),
    );
  }
}
