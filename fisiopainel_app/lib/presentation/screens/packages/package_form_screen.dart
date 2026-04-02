import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Adicione intl no pubspec.yaml se não tiver
import '../../../domain/models/package_model.dart';
import '../../controllers/package_controller.dart';

class PackageFormScreen extends StatefulWidget {
  final PackageController controller;
  final PackageModel? package; // Pacote opcional para edição

  const PackageFormScreen({super.key, required this.controller, this.package});

  @override
  State<PackageFormScreen> createState() => _PackageFormScreenState();
}

class _PackageFormScreenState extends State<PackageFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late bool _isEditing;

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

  @override
  void initState() {
    super.initState();
    _isEditing = widget.package != null;

    if (_isEditing) {
      final pkg = widget.package!;
      _selectedPatientId = pkg.patientId;
      _selectedTypeId = pkg.serviceTypeId;
      _qtdCtrl.text = pkg.quantity.toString();
      _totalCtrl.text = pkg.totalValue.toStringAsFixed(2);
      _sessionValueCtrl.text = pkg.sessionValue.toStringAsFixed(2);
      _status = pkg.status;
      if (pkg.paymentDate != null) {
        _selectedDate = pkg.paymentDate;
        _dateCtrl.text = DateFormat('dd/MM/yyyy').format(pkg.paymentDate!);
      }
    }
  }
  
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
      initialDate: _selectedDate ?? DateTime.now(),
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
      final packageData = PackageModel(
        id: _isEditing ? widget.package!.id : null,
        patientId: _selectedPatientId!,
        serviceTypeId: _selectedTypeId!,
        quantity: int.parse(_qtdCtrl.text),
        totalValue: double.parse(_totalCtrl.text),
        sessionValue: double.parse(_sessionValueCtrl.text),
        status: _status,
        paymentDate: _selectedDate,
      );

      final success = _isEditing
          ? await widget.controller.updatePackage(packageData)
          : await widget.controller.createPackage(packageData);

      if (success && mounted) {
        Navigator.pop(context, true);
      } else if (mounted) {
        // Exibe o erro no rodapé do próprio modal
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.controller.error.isNotEmpty
                ? widget.controller.error
                : 'Ocorreu um erro desconhecido.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600),
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _isEditing ? 'Editar Pacote' : 'Novo Pacote',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Divider(),
                const SizedBox(height: 15),

                // --- DROPDOWNS RESPONSIVOS ---
                LayoutBuilder(builder: (context, constraints) {
                  final bool useColumn = constraints.maxWidth < 450;
                  final content = [
                    Expanded(
                      flex: useColumn ? 0 : 1,
                      child: DropdownButtonFormField<int>(
                        decoration: const InputDecoration(
                          labelText: 'Paciente *',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        isExpanded: true,
                        value: _selectedPatientId,
                        items: widget.controller.patientsList
                            .map((p) => DropdownMenuItem(
                                  value: p.id,
                                  child: Text(p.completeName, overflow: TextOverflow.ellipsis),
                                ))
                            .toList(),
                        onChanged: (val) => setState(() => _selectedPatientId = val),
                        validator: (v) => v == null ? 'Obrigatório' : null,
                      ),
                    ),
                    SizedBox(width: useColumn ? 0 : 10, height: useColumn ? 15 : 0),
                    Expanded(
                      flex: useColumn ? 0 : 1,
                      child: DropdownButtonFormField<int>(
                        decoration: const InputDecoration(
                          labelText: 'Tipo Atendimento *',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        isExpanded: true,
                        value: _selectedTypeId,
                        items: widget.controller.serviceTypesList
                            .map((t) => DropdownMenuItem(
                                  value: t.id,
                                  child: Text(t.name, overflow: TextOverflow.ellipsis),
                                ))
                            .toList(),
                        onChanged: (val) => setState(() => _selectedTypeId = val),
                        validator: (v) => v == null ? 'Obrigatório' : null,
                      ),
                    ),
                  ];

                  return useColumn 
                    ? Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: content) 
                    : Row(children: content);
                }),
                const SizedBox(height: 15),

                // --- VALORES E CÁLCULO ---
                LayoutBuilder(builder: (context, constraints) {
                  final bool useColumn = constraints.maxWidth < 450;
                  final content = [
                    Expanded(
                      flex: useColumn ? 0 : 1,
                      child: TextFormField(
                        controller: _qtdCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Qtd Sessões',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        onChanged: (_) => _calculateSessionValue(),
                        validator: (v) => v!.isEmpty ? 'Req' : null,
                      ),
                    ),
                    SizedBox(width: useColumn ? 0 : 10, height: useColumn ? 15 : 0),
                    Expanded(
                      flex: useColumn ? 0 : 1,
                      child: TextFormField(
                        controller: _totalCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Valor Total (R\$)',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        onChanged: (_) => _calculateSessionValue(),
                        validator: (v) => v!.isEmpty ? 'Req' : null,
                      ),
                    ),
                    SizedBox(width: useColumn ? 0 : 10, height: useColumn ? 15 : 0),
                    Expanded(
                      flex: useColumn ? 0 : 1,
                      child: TextFormField(
                        controller: _sessionValueCtrl,
                        readOnly: true,
                        decoration: const InputDecoration(
                          labelText: 'Valor/Sessão',
                          border: OutlineInputBorder(),
                          filled: true,
                          isDense: true,
                        ),
                      ),
                    ),
                  ];

                  return useColumn 
                    ? Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: content) 
                    : Row(children: content);
                }),
                const SizedBox(height: 15),

                // --- DATA E STATUS ---
                LayoutBuilder(builder: (context, constraints) {
                  final bool useColumn = constraints.maxWidth < 450;
                  final content = [
                    Expanded(
                      flex: useColumn ? 0 : 1,
                      child: TextFormField(
                        controller: _dateCtrl,
                        readOnly: true,
                        decoration: const InputDecoration(
                          labelText: 'Data Pagamento',
                          border: OutlineInputBorder(),
                          suffixIcon: Icon(Icons.calendar_today),
                          isDense: true,
                        ),
                        onTap: _pickDate,
                      ),
                    ),
                    SizedBox(width: useColumn ? 0 : 10, height: useColumn ? 15 : 0),
                    Expanded(
                      flex: useColumn ? 0 : 1,
                      child: DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Status',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        value: _status,
                        items: const [
                          DropdownMenuItem(value: "ATIVO", child: Text("Ativo")),
                          DropdownMenuItem(value: "FINALIZADO", child: Text("Finalizado")),
                          DropdownMenuItem(value: "CANCELADO", child: Text("Cancelado")),
                        ],
                        onChanged: (val) => setState(() => _status = val!),
                      ),
                    ),
                  ];

                  return useColumn 
                    ? Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: content) 
                    : Row(children: content);
                }),

                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal[800],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: widget.controller.isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            _isEditing ? 'SALVAR ALTERAÇÕES' : 'CRIAR PACOTE',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
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
