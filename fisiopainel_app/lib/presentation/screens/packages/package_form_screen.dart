import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Adicione intl no pubspec.yaml se não tiver
import '../../../domain/models/package_model.dart';
import '../../controllers/package_controller.dart';

class PackageFormScreen extends StatefulWidget {
  final PackageController controller;

  const PackageFormScreen({super.key, required this.controller});

  @override
  State<PackageFormScreen> createState() => _PackageFormScreenState();
}

class _PackageFormScreenState extends State<PackageFormScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers de Texto
  final _qtdCtrl = TextEditingController();
  final _totalCtrl = TextEditingController();
  final _sessionValueCtrl = TextEditingController();
  final _dateCtrl = TextEditingController(); // Apenas visual

  // Variáveis de Estado
  int? _selectedPatientId;
  int? _selectedTypeId;
  DateTime? _selectedDate;
  String _status = "ATIVO";

  // Lógica de Cálculo Automático
  void _calculateSessionValue() {
    final qtd = double.tryParse(_qtdCtrl.text) ?? 0;
    final total = double.tryParse(_totalCtrl.text) ?? 0;

    if (qtd > 0 && total > 0) {
      final sessionVal = total / qtd;
      _sessionValueCtrl.text = sessionVal.toStringAsFixed(2);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dateCtrl.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate() &&
        _selectedPatientId != null &&
        _selectedTypeId != null) {
      final newPackage = PackageModel(
        patientId: _selectedPatientId!,
        serviceTypeId: _selectedTypeId!,
        quantity: int.parse(_qtdCtrl.text),
        totalValue: double.parse(_totalCtrl.text),
        sessionValue: double.parse(_sessionValueCtrl.text),
        status: _status,
        paymentDate: _selectedDate,
      );

      final success = await widget.controller.createPackage(newPackage);
      if (success && mounted) Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600),
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Novo Pacote',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),

                // --- DROPDOWNS ---
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        decoration: const InputDecoration(
                          labelText: 'Paciente *',
                          border: OutlineInputBorder(),
                        ),
                        value: _selectedPatientId,
                        items: widget.controller.patientsList
                            .map(
                              (p) => DropdownMenuItem(
                                value: p.id,
                                child: Text(p.completeName),
                              ),
                            )
                            .toList(),
                        onChanged: (val) =>
                            setState(() => _selectedPatientId = val),
                        validator: (v) => v == null ? 'Obrigatório' : null,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        decoration: const InputDecoration(
                          labelText: 'Tipo Atendimento *',
                          border: OutlineInputBorder(),
                        ),
                        value: _selectedTypeId,
                        items: widget.controller.serviceTypesList
                            .map(
                              (t) => DropdownMenuItem(
                                value: t.id,
                                child: Text(t.name),
                              ),
                            )
                            .toList(),
                        onChanged: (val) =>
                            setState(() => _selectedTypeId = val),
                        validator: (v) => v == null ? 'Obrigatório' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),

                // --- VALORES E CÁLCULO ---
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _qtdCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Qtd Sessões',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (_) => _calculateSessionValue(),
                        validator: (v) => v!.isEmpty ? 'Req' : null,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _totalCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Valor Total (R\$)',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (_) => _calculateSessionValue(),
                        validator: (v) => v!.isEmpty ? 'Req' : null,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _sessionValueCtrl,
                        readOnly: true, // Campo calculado
                        decoration: const InputDecoration(
                          labelText: 'Valor/Sessão',
                          border: OutlineInputBorder(),
                          filled: true,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),

                // --- DATA E STATUS ---
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _dateCtrl,
                        readOnly: true,
                        decoration: const InputDecoration(
                          labelText: 'Data Pagamento',
                          border: OutlineInputBorder(),
                          suffixIcon: Icon(Icons.calendar_today),
                        ),
                        onTap: _pickDate,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Status',
                          border: OutlineInputBorder(),
                        ),
                        value: _status,
                        items: const [
                          DropdownMenuItem(
                            value: "ATIVO",
                            child: Text("Ativo"),
                          ),
                          DropdownMenuItem(
                            value: "FINALIZADO",
                            child: Text("Finalizado"),
                          ),
                          DropdownMenuItem(
                            value: "CANCELADO",
                            child: Text("Cancelado"),
                          ),
                        ],
                        onChanged: (val) => setState(() => _status = val!),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[800],
                      foregroundColor: Colors.white,
                    ),
                    child: widget.controller.isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('CRIAR PACOTE'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
