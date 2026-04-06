import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../domain/models/package_model.dart';
import '../../controllers/package_controller.dart';

class PackageFormScreen extends StatefulWidget {
  final PackageController controller;
  final PackageModel? package;
  final bool isRenewal;

  const PackageFormScreen({
    super.key, 
    required this.controller, 
    this.package,
    this.isRenewal = false,
  });

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
    _isEditing = widget.package != null && !widget.isRenewal;

    if (widget.package != null) {
      final pkg = widget.package!;
      _selectedPatientId = pkg.patientId;
      _selectedProfessionalId = pkg.professionalId;
      _selectedTypeId = pkg.serviceTypeId;
      _qtdCtrl.text = pkg.quantity.toString();
      _totalCtrl.text = pkg.totalValue.toStringAsFixed(2);
      _sessionValueCtrl.text = pkg.sessionValue.toStringAsFixed(2);
      
      if (widget.isRenewal) {
        _status = "ATIVO";
        // Na renovação, não trazemos a data de pagamento anterior
      } else {
        _status = pkg.status;
        if (pkg.paymentDate != null) {
          _selectedDate = pkg.paymentDate;
          _dateCtrl.text = DateFormat('dd/MM/yyyy').format(pkg.paymentDate!);
        }
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
    // Verificar se o paciente está ativo antes de submeter
    final selectedPatient = widget.controller.patientsList.firstWhere((p) => p.id == _selectedPatientId);
    if (!selectedPatient.isActive) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não é possível criar pacotes para pacientes desabilitados.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
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
        renovatedFrom: widget.package?.id,
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

  Widget _buildAlert(String message, MaterialColor color) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color[200]!),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: color[800], size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: color[900], fontSize: 12, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 800, minWidth: 400),
        padding: const EdgeInsets.all(24),
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
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Divider(),
                const SizedBox(height: 20),

                // --- SEÇÃO: INFORMAÇÕES BÁSICAS ---
                const _SectionTitle(title: 'Informações do Pacote', icon: Icons.info_outline),
                const SizedBox(height: 15),
                
                DropdownButtonFormField<int>(
                  decoration: const InputDecoration(
                    labelText: 'Paciente *',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  value: _selectedPatientId,
                  items: widget.controller.patientsList
                      .map((p) => DropdownMenuItem(value: p.id, child: Text(p.completeName)))
                      .toList(),
                  onChanged: (val) => setState(() => _selectedPatientId = val),
                  validator: (v) => v == null ? 'Selecione um paciente' : null,
                ),
                if (_selectedPatientId != null)
                  Builder(builder: (context) {
                    final p = widget.controller.patientsList.firstWhere((p) => p.id == _selectedPatientId);
                    if (!p.isActive) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 12.0),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red[200]!),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.warning_amber_rounded, color: Colors.red[800]),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text(
                                  'Paciente desabilitado, consulte a Administração.',
                                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  }),
                const SizedBox(height: 15),
                
                DropdownButtonFormField<int>(
                  decoration: const InputDecoration(
                    labelText: 'Tipo de Atendimento *',
                    prefixIcon: Icon(Icons.category_outlined),
                  ),
                  value: _selectedTypeId,
                  items: widget.controller.serviceTypesList
                      .map((t) => DropdownMenuItem(value: t.id, child: Text(t.name)))
                      .toList(),
                  onChanged: (val) => setState(() => _selectedTypeId = val),
                  validator: (v) => v == null ? 'Selecione o tipo' : null,
                ),
                const SizedBox(height: 15),
                
                DropdownButtonFormField<int>(
                  decoration: const InputDecoration(
                    labelText: 'Profissional Responsável *',
                    prefixIcon: Icon(Icons.medical_services_outlined),
                    helperText: 'Dono do pacote que receberá o repasse',
                  ),
                  value: _selectedProfessionalId,
                  items: widget.controller.professionalsList
                      .map((p) => DropdownMenuItem(value: p.id, child: Text(p.fullName)))
                      .toList(),
                  onChanged: (val) => setState(() => _selectedProfessionalId = val),
                  validator: (v) => v == null ? 'Selecione o profissional' : null,
                ),
                const SizedBox(height: 25),

                // --- SEÇÃO: VALORES ---
                const _SectionTitle(title: 'Valores e Sessões', icon: Icons.payments_outlined),
                const SizedBox(height: 15),
                
                TextFormField(
                  controller: _qtdCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Quantidade de Sessões *',
                    prefixIcon: Icon(Icons.numbers),
                  ),
                  onChanged: (_) {
                    _calculateSessionValue();
                    setState(() {}); // Atualiza para mostrar/esconder o aviso de pagamento
                  },
                  validator: (v) => (v == null || v.isEmpty) ? 'Informe a quantidade' : null,
                ),
                TextFormField(
                  controller: _totalCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Valor Total do Pacote (R\$) *',
                    prefixIcon: Icon(Icons.monetization_on_outlined),
                  ),
                  onChanged: (_) {
                    _calculateSessionValue();
                    setState(() {}); // Atualiza avisos de valor
                  },
                  validator: (v) => (v == null || v.isEmpty) ? 'Informe o valor total' : null,
                ),
                if (_isEditing && widget.package?.paymentDate != null)
                  Builder(builder: (context) {
                    final novoTotal = double.tryParse(_totalCtrl.text.replaceAll(',', '.')) ?? 0;
                    final originalTotal = widget.package?.totalValue ?? 0;

                    if (novoTotal > originalTotal) {
                      return _buildAlert(
                        'Este pacote já possui um valor pago. O valor adicional aparecerá como pendente no financeiro.',
                        Colors.amber,
                      );
                    } else if (novoTotal < originalTotal && novoTotal > 0) {
                      return _buildAlert(
                        'O novo valor é menor que o valor já pago. Isso gerará sobras financeiras para este paciente.',
                        Colors.blue,
                      );
                    }
                    return const SizedBox.shrink();
                  }),
                const SizedBox(height: 15),
                
                TextFormField(
                  controller: _sessionValueCtrl,
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'Valor por Sessão (Calculado)',
                    prefixIcon: const Icon(Icons.calculate_outlined),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                ),
                const SizedBox(height: 25),

                // --- SEÇÃO: AGENDAMENTO AUTOMÁTICO ---
                if (!_isEditing) ...[
                  const _SectionTitle(title: 'Agendamento Automático', icon: Icons.auto_awesome),
                  const SizedBox(height: 15),
                  TextFormField(
                    controller: _startDateCtrl,
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: 'Data de Início das Sessões *',
                      prefixIcon: Icon(Icons.calendar_month_outlined),
                      suffixIcon: Icon(Icons.edit_calendar),
                    ),
                    onTap: _pickStartDate,
                    validator: (v) => (!_isEditing && (v == null || v.isEmpty)) ? 'Informe a data de início' : null,
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    "Dias da Semana para Atendimento:",
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.blueGrey),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: List.generate(7, (index) {
                        final isSelected = _selectedWeekDays.contains(index);
                        return FilterChip(
                          label: Text(_weekDayNames[index]),
                          selected: isSelected,
                          selectedColor: Colors.blue[100],
                          checkmarkColor: Colors.blue[700],
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
                  ),
                  const SizedBox(height: 25),
                ],

                // --- SEÇÃO: STATUS E PAGAMENTO ---
                const _SectionTitle(title: 'Status e Pagamento', icon: Icons.check_circle_outline),
                const SizedBox(height: 15),
                
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Status do Pacote',
                    prefixIcon: Icon(Icons.info_outline),
                  ),
                  value: _status,
                  items: const [
                    DropdownMenuItem(value: "ATIVO", child: Text("Ativo")),
                    DropdownMenuItem(value: "FINALIZADO", child: Text("Finalizado")),
                    DropdownMenuItem(value: "CANCELADO", child: Text("Cancelado")),
                  ],
                  onChanged: (val) => setState(() => _status = val!),
                ),
                const SizedBox(height: 15),
                
                TextFormField(
                  controller: _dateCtrl,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: 'Data do Pagamento (se já pago)',
                    prefixIcon: Icon(Icons.calendar_today_outlined),
                    suffixIcon: Icon(Icons.event),
                  ),
                  onTap: _pickDate,
                ),

                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: Builder(
                    builder: (context) {
                      bool isPatientInactive = false;
                      if (_selectedPatientId != null) {
                        final p = widget.controller.patientsList.firstWhere((p) => p.id == _selectedPatientId);
                        isPatientInactive = !p.isActive;
                      }

                      return ElevatedButton(
                        onPressed: (widget.controller.isLoading || isPatientInactive) ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3B82F6),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: widget.controller.isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : Text(
                                _isEditing ? 'SALVAR ALTERAÇÕES' : 'CRIAR PACOTE',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                      );
                    }
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionTitle({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.blue[700]),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.blue[700],
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}
