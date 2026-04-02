import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../domain/models/package_model.dart';
import '../../controllers/package_controller.dart';

class PackageFormScreen extends StatefulWidget {
  final PackageController controller;
  final PackageModel? package;

  const PackageFormScreen({super.key, required this.controller, this.package});

  @override
  State<PackageFormScreen> createState() => _PackageFormScreenState();
}

class _PackageFormScreenState extends State<PackageFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late bool _isEditing;

  final _qtdCtrl = TextEditingController();
  final _totalCtrl = TextEditingController();
  final _sessionValueCtrl = TextEditingController();
  final _dateCtrl = TextEditingController();
  final _startDateCtrl = TextEditingController();

  int? _selectedPatientId;
  int? _selectedProfessionalId;
  int? _selectedTypeId;
  DateTime? _selectedDate;
  DateTime? _selectedStartDate;
  String _status = "ATIVO";
  
  // 0=Segunda, 6=Domingo (alinhado com o weekday do Dart/Python)
  final List<int> _selectedWeekDays = [];
  final List<String> _weekDayNames = ["Seg", "Ter", "Qua", "Qui", "Sex", "Sáb", "Dom"];

  @override
  void initState() {
    super.initState();
    _isEditing = widget.package != null;

    if (_isEditing) {
      final pkg = widget.package!;
      _selectedPatientId = pkg.patientId;
      _selectedProfessionalId = pkg.professionalId;
      _selectedTypeId = pkg.serviceTypeId;
      _qtdCtrl.text = pkg.quantity.toString();
      _totalCtrl.text = pkg.totalValue.toStringAsFixed(2);
      _sessionValueCtrl.text = pkg.sessionValue.toStringAsFixed(2);
      _status = pkg.status;
      if (pkg.paymentDate != null) {
        _selectedDate = pkg.paymentDate;
        _dateCtrl.text = DateFormat('dd/MM/yyyy').format(pkg.paymentDate!);
      }
      if (pkg.startDate != null) {
        _selectedStartDate = pkg.startDate;
        _startDateCtrl.text = DateFormat('dd/MM/yyyy').format(pkg.startDate!);
      }
      if (pkg.weekDays != null && pkg.weekDays!.isNotEmpty) {
        _selectedWeekDays.addAll(pkg.weekDays!.split(',').map((e) => int.parse(e)));
      }
    }
  }

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

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedStartDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        _selectedStartDate = picked;
        _startDateCtrl.text = DateFormat('dd/MM/yyyy').format(picked);
        
        // Se nenhum dia da semana estiver selecionado, seleciona o dia da data inicial
        if (_selectedWeekDays.isEmpty) {
          // No Dart weekday é 1 (Seg) a 7 (Dom). Subtraímos 1 para alinhar com 0-6.
          _selectedWeekDays.add(picked.weekday - 1);
        }
      });
    }
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate() &&
        _selectedPatientId != null &&
        _selectedTypeId != null &&
        _selectedProfessionalId != null) {
      
      final packageData = PackageModel(
        id: _isEditing ? widget.package!.id : null,
        patientId: _selectedPatientId!,
        professionalId: _selectedProfessionalId!,
        serviceTypeId: _selectedTypeId!,
        quantity: int.parse(_qtdCtrl.text),
        totalValue: double.parse(_totalCtrl.text),
        sessionValue: double.parse(_sessionValueCtrl.text),
        status: _status,
        paymentDate: _selectedDate,
        startDate: _selectedStartDate,
        weekDays: _selectedWeekDays.isEmpty ? null : _selectedWeekDays.join(','),
      );

      final success = _isEditing
          ? await widget.controller.updatePackage(packageData)
          : await widget.controller.createPackage(packageData);

      if (success && mounted) {
        Navigator.pop(context, true);
      } else if (mounted) {
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
                Text(
                  _isEditing ? 'Editar Pacote' : 'Novo Pacote',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
                            .map((p) => DropdownMenuItem(value: p.id, child: Text(p.completeName)))
                            .toList(),
                        onChanged: (val) => setState(() => _selectedPatientId = val),
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
                            .map((t) => DropdownMenuItem(value: t.id, child: Text(t.name)))
                            .toList(),
                        onChanged: (val) => setState(() => _selectedTypeId = val),
                        validator: (v) => v == null ? 'Obrigatório' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                DropdownButtonFormField<int>(
                  decoration: const InputDecoration(
                    labelText: 'Profissional Responsável (Dono do Pacote) *',
                    border: OutlineInputBorder(),
                  ),
                  value: _selectedProfessionalId,
                  items: widget.controller.professionalsList
                      .map((p) => DropdownMenuItem(value: p.id, child: Text(p.fullName)))
                      .toList(),
                  onChanged: (val) => setState(() => _selectedProfessionalId = val),
                  validator: (v) => v == null ? 'Obrigatório' : null,
                ),
                const SizedBox(height: 15),

                // --- VALORES E CÁLCULO ---
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _qtdCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Qtd Sessões', border: OutlineInputBorder()),
                        onChanged: (_) => _calculateSessionValue(),
                        validator: (v) => v!.isEmpty ? 'Req' : null,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _totalCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Valor Total (R\$)', border: OutlineInputBorder()),
                        onChanged: (_) => _calculateSessionValue(),
                        validator: (v) => v!.isEmpty ? 'Req' : null,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _sessionValueCtrl,
                        readOnly: true,
                        decoration: const InputDecoration(labelText: 'Valor/Sessão', border: OutlineInputBorder(), filled: true),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // --- AGENDAMENTO AUTOMÁTICO ---
                if (!_isEditing) ...[
                  const Text("Agendamento Automático", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _startDateCtrl,
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: 'Data Inicial (Início das Sessões) *',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.event_note),
                    ),
                    onTap: _pickStartDate,
                    validator: (v) => (!_isEditing && (v == null || v.isEmpty)) ? 'Obrigatório' : null,
                  ),
                  const SizedBox(height: 10),
                  const Text("Dias da Semana:", style: TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 5),
                  Wrap(
                    spacing: 8,
                    children: List.generate(7, (index) {
                      return FilterChip(
                        label: Text(_weekDayNames[index]),
                        selected: _selectedWeekDays.contains(index),
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedWeekDays.add(index);
                            } else {
                              _selectedWeekDays.remove(index);
                            }
                          });
                        },
                      );
                    }),
                  ),
                  const SizedBox(height: 20),
                ],

                // --- DATA PAGAMENTO E STATUS ---
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _dateCtrl,
                        readOnly: true,
                        decoration: const InputDecoration(labelText: 'Data Pagamento', border: OutlineInputBorder(), suffixIcon: Icon(Icons.calendar_today)),
                        onTap: _pickDate,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        decoration: const InputDecoration(labelText: 'Status', border: OutlineInputBorder()),
                        value: _status,
                        items: const [
                          DropdownMenuItem(value: "ATIVO", child: Text("Ativo")),
                          DropdownMenuItem(value: "FINALIZADO", child: Text("Finalizado")),
                          DropdownMenuItem(value: "CANCELADO", child: Text("Cancelado")),
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
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[800], foregroundColor: Colors.white),
                    child: widget.controller.isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(_isEditing ? 'SALVAR ALTERAÇÕES' : 'CRIAR PACOTE'),
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
