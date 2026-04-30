import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../domain/models/package_model.dart';
import '../../../domain/models/patient_model.dart';
import '../../controllers/package_controller.dart';
import '../../widgets/currency_formatter.dart';
import '../../widgets/string_utils.dart';

class PackageFormScreen extends StatefulWidget {
  final PackageController controller;
  final PackageModel? package;
  final bool isRenewal;
  final DateTime? initialStartDate;
  final TimeOfDay? initialTime;

  const PackageFormScreen({
    super.key,
    required this.controller,
    this.package,
    this.isRenewal = false,
    this.initialStartDate,
    this.initialTime,
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
  final _timeCtrl = TextEditingController();

  int? _selectedPatientId;
  int? _selectedProfessionalId;
  int? _selectedTypeId;
  DateTime? _selectedDate;
  DateTime? _selectedStartDate;
  TimeOfDay? _selectedTime;
  String? _selectedPaymentMethod;
  String _status = "ATIVO";

  // 0=Segunda, 6=Domingo (alinhado com o weekday do Dart/Python)
  final List<int> _selectedWeekDays = [];
  final List<String> _weekDayNames = ["Seg", "Ter", "Qua", "Qui", "Sex", "SÃ¡b", "Dom"];

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
      _selectedPaymentMethod = pkg.paymentMethod;

      final nf = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$ ');
      _totalCtrl.text = nf.format(pkg.totalValue).trim();
      _sessionValueCtrl.text = nf.format(pkg.sessionValue).trim();

      if (widget.isRenewal) {
        _status = "ATIVO";
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
      if (pkg.horarioAtendimento != null && pkg.horarioAtendimento!.isNotEmpty) {
        _timeCtrl.text = pkg.horarioAtendimento!.substring(0, 5); // Take only HH:mm
        final parts = pkg.horarioAtendimento!.split(':');
        if (parts.length >= 2) {
          _selectedTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
        }
      }
      if (pkg.weekDays != null && pkg.weekDays!.isNotEmpty) {
        _selectedWeekDays.addAll(pkg.weekDays!.split(',').map((e) => int.parse(e)));
      }
    } else {
      // Se for um novo pacote e houver valores iniciais
      if (widget.initialStartDate != null) {
        _selectedStartDate = widget.initialStartDate;
        _startDateCtrl.text = DateFormat('dd/MM/yyyy').format(widget.initialStartDate!);
        // Pré-selecionar o dia da semana
        _selectedWeekDays.add(widget.initialStartDate!.weekday - 1);
      }
      if (widget.initialTime != null) {
        _selectedTime = widget.initialTime;
        final hour = widget.initialTime!.hour.toString().padLeft(2, '0');
        final minute = widget.initialTime!.minute.toString().padLeft(2, '0');
        _timeCtrl.text = "$hour:$minute";
      }
    }
  }

  void _calculateSessionValue() {
    final qtdText = _qtdCtrl.text;
    final qtd = double.tryParse(qtdText) ?? 0;

    final total = StringUtils.parseCurrency(_totalCtrl.text) ?? 0;

    if (qtd > 0 && total > 0) {
      final sessionVal = total / qtd;
      _sessionValueCtrl.text = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$ ').format(sessionVal).trim();    
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

        if (_selectedWeekDays.isEmpty) {
          _selectedWeekDays.add(picked.weekday - 1);
        }
      });
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? const TimeOfDay(hour: 8, minute: 0),
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
        _timeCtrl.text = picked.format(context);
      });
    }
  }

  Future<bool> _showReorderConfirmation() async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirmar Alteração"),
        content: const Text("As datas de atendimento serão reagendadas, deseja confirmar?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("CANCELAR"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("CONFIRMAR"),
          ),
        ],
      ),
    ) ?? false;
  }

  Future<void> _submit() async {
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

    final selectedType = widget.controller.serviceTypesList.firstWhere((t) => t.id == _selectedTypeId);
    if (!selectedType.isActive) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não é possível utilizar um tipo de atendimento desabilitado.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      String? formattedTime;
      if (_selectedTime != null) {
        final hour = _selectedTime!.hour.toString().padLeft(2, '0');
        final minute = _selectedTime!.minute.toString().padLeft(2, '0');
        formattedTime = "$hour:$minute";
      }

      final total = StringUtils.parseCurrency(_totalCtrl.text) ?? 0;
      final sessionVal = StringUtils.parseCurrency(_sessionValueCtrl.text) ?? 0;
      final currentWeekDaysStr = _selectedWeekDays.isEmpty ? null : _selectedWeekDays.join(',');

      // Se estiver editando, verificar se houve mudanças que exigem reagendamento
      if (_isEditing && widget.package != null) {
        final pkg = widget.package!;
        bool mudouAgendamento = false;

        if (_selectedStartDate != pkg.startDate) mudouAgendamento = true;
        if (formattedTime != pkg.horarioAtendimento) mudouAgendamento = true;
        if (currentWeekDaysStr != pkg.weekDays) mudouAgendamento = true;

        if (mudouAgendamento) {
          final confirm = await _showReorderConfirmation();
          if (!confirm) return;
        }
      }

      final packageData = PackageModel(
        id: _isEditing ? widget.package!.id : null,
        patientId: _selectedPatientId!,
        professionalId: _selectedProfessionalId!,
        serviceTypeId: _selectedTypeId!,
        quantity: int.parse(_qtdCtrl.text),
        totalValue: total,
        sessionValue: sessionVal,
        paidValue: _isEditing ? widget.package!.paidValue : 0,
        paymentMethod: _selectedPaymentMethod,
        status: _status,
        paymentDate: _selectedDate,
        startDate: _selectedStartDate,
        horarioAtendimento: formattedTime,
        weekDays: currentWeekDaysStr,
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

                const _SectionTitle(title: 'Informações do Pacote', icon: Icons.info_outline),
                const SizedBox(height: 15),

                LayoutBuilder(
                  builder: (context, constraints) => Autocomplete<PatientModel>(
                    displayStringForOption: (PatientModel option) => option.completeName,
                    initialValue: _selectedPatientId != null
                        ? TextEditingValue(
                            text: widget.controller.patientsList
                                .firstWhere((p) => p.id == _selectedPatientId)
                                .completeName)
                        : null,
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      if (textEditingValue.text.isEmpty) {
                        return const Iterable<PatientModel>.empty();
                      }
                      return widget.controller.patientsList.where((PatientModel option) {
                        return option.completeName
                            .toLowerCase()
                            .contains(textEditingValue.text.toLowerCase());
                      });
                    },
                    onSelected: (PatientModel selection) {
                      setState(() {
                        _selectedPatientId = selection.id;
                      });
                    },
                    fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
                      return TextFormField(
                        controller: textEditingController,
                        focusNode: focusNode,
                        decoration: const InputDecoration(
                          labelText: 'Paciente *',
                          prefixIcon: Icon(Icons.person_outline),
                          suffixIcon: Icon(Icons.search),
                        ),
                        onChanged: (val) {
                          if (val.isEmpty) {
                            setState(() => _selectedPatientId = null);
                          }
                        },
                        validator: (v) {
                          if (_selectedPatientId == null || v == null || v.isEmpty) {
                            return 'Selecione um paciente';
                          }
                          final selectedPatient = widget.controller.patientsList.firstWhere(
                            (p) => p.id == _selectedPatientId,
                            orElse: () => PatientModel(completeName: '', isActive: false),
                          );
                          if (v != selectedPatient.completeName) {
                            return 'Selecione um paciente da lista';
                          }
                          return null;
                        },
                      );
                    },
                    optionsViewBuilder: (context, onSelected, options) {
                      return Align(
                        alignment: Alignment.topLeft,
                        child: Material(
                          elevation: 4.0,
                          child: SizedBox(
                            width: constraints.maxWidth,
                            child: ListView.builder(
                              padding: EdgeInsets.zero,
                              shrinkWrap: true,
                              itemCount: options.length,
                              itemBuilder: (BuildContext context, int index) {
                                final PatientModel option = options.elementAt(index);
                                return ListTile(
                                  title: Text(option.completeName),
                                  subtitle: option.isActive
                                      ? null
                                      : const Text('Inativo', style: TextStyle(color: Colors.red, fontSize: 11)),
                                  onTap: () => onSelected(option),
                                );
                              },
                            ),
                          ),
                        ),
                      );
                    },
                  ),
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
                      .where((t) => t.isActive || t.id == _selectedTypeId)
                      .map((t) => DropdownMenuItem(value: t.id, child: Text(t.name)))
                      .toList(),
                  onChanged: (val) => setState(() => _selectedTypeId = val),
                  validator: (v) => v == null ? 'Selecione o tipo' : null,
                ),
                if (_selectedTypeId != null)
                  Builder(builder: (context) {
                    final t = widget.controller.serviceTypesList.firstWhere((t) => t.id == _selectedTypeId);    
                    if (!t.isActive) {
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
                                  'Tipo de atendimento desabilitado.',
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
                    setState(() {});
                  },
                  validator: (v) => (v == null || v.isEmpty) ? 'Informe a quantidade' : null,
                ),
                TextFormField(
                  controller: _totalCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    CurrencyInputFormatter(),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Valor Total do Pacote (R\$) *',
                    prefixIcon: Icon(Icons.monetization_on_outlined),
                  ),
                  onChanged: (_) {
                    _calculateSessionValue();
                    setState(() {});
                  },
                  validator: (v) => (v == null || v.isEmpty) ? 'Informe o valor total' : null,
                ),
                if (_isEditing && widget.package?.paymentDate != null)
                  Builder(builder: (context) {
                    final novoTotalStr = _totalCtrl.text.replaceAll('.', '').replaceAll(',', '.');
                    final novoTotal = double.tryParse(novoTotalStr) ?? 0;
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

                // --- SEÇÃO: HORÁRIO E DIAS ---
                _SectionTitle(
                  title: _isEditing ? 'Horário e Dias de Atendimento' : 'Agendamento Automático', 
                  icon: Icons.auto_awesome
                ),
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
                  validator: (v) => (v == null || v.isEmpty) ? 'Informe a data de início' : null,
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: _timeCtrl,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: 'Horário do Atendimento *',
                    prefixIcon: Icon(Icons.access_time),
                    suffixIcon: Icon(Icons.edit_calendar),
                  ),
                  onTap: _pickTime,
                  validator: (v) => (v == null || v.isEmpty) ? 'Informe o horário' : null,  
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
                const SizedBox(height: 15),

                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Forma de Pagamento',
                    prefixIcon: Icon(Icons.payment_outlined),
                  ),
                  value: _selectedPaymentMethod,
                  items: const [
                    DropdownMenuItem(value: "DEBITO", child: Text("Débito")),
                    DropdownMenuItem(value: "CREDITO", child: Text("Crédito")),
                    DropdownMenuItem(value: "PIX", child: Text("PIX")),
                    DropdownMenuItem(value: "ESPECIE", child: Text("Espécie")),
                    DropdownMenuItem(value: "OUTROS", child: Text("Outros")),
                  ],
                  onChanged: (val) => setState(() => _selectedPaymentMethod = val),
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

                      bool isTypeInactive = false;
                      if (_selectedTypeId != null) {
                        final t = widget.controller.serviceTypesList.firstWhere((t) => t.id == _selectedTypeId);
                        isTypeInactive = !t.isActive;
                      }

                      return ElevatedButton(
                        onPressed: (widget.controller.isLoading || isPatientInactive || isTypeInactive) ? null : _submit,
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
