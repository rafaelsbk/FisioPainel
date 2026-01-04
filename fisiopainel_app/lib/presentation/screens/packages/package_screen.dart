import 'package:flutter/material.dart';
import '../../controllers/package_controller.dart';
import 'package_form_screen.dart';

class PackagesScreen extends StatefulWidget {
  const PackagesScreen({super.key});

  @override
  State<PackagesScreen> createState() => _PackagesScreenState();
}

class _PackagesScreenState extends State<PackagesScreen> {
  final PackageController _controller = PackageController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      setState(() {});
    });
    // Carrega tudo ao iniciar
    _controller.loadData();
  }

  void _openForm() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => PackageFormScreen(controller: _controller),
    );

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Pacote criado com sucesso!"),
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
                : ListView.separated(
                    itemCount: _controller.packages.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, index) {
                      final pkg = _controller.packages[index];
                      // Tentativa de achar o nome do paciente na lista carregada (se a API não retornou no DTO)
                      final patientName =
                          _controller.patientsList
                              .where((p) => p.id == pkg.patientId)
                              .firstOrNull
                              ?.completeName ??
                          "Paciente #${pkg.patientId}";

                      return Card(
                        elevation: 2,
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.purple[100],
                            child: const Icon(
                              Icons.inventory_2,
                              color: Colors.purple,
                            ),
                          ),
                          title: Text(
                            patientName,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            "R\$ ${pkg.totalValue} (${pkg.quantity} Sessões)",
                          ),
                          trailing: Chip(
                            label: Text(pkg.status),
                            backgroundColor: pkg.status == "ATIVO"
                                ? Colors.green[100]
                                : Colors.grey[200],
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
