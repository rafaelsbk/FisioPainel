import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../controllers/appointment_controller.dart';
import '../../../domain/models/appointment_model.dart';
import '../../../domain/models/professional_model.dart';

class EditAppointmentDialog extends StatefulWidget {
  final AppointmentModel appointment;

  const EditAppointmentDialog({
    super.key,
    required this.appointment,
  });

  @override
  State<EditAppointmentDialog> createState() => _EditAppointmentDialogState();
}

class _EditAppointmentDialogState extends State<EditAppointmentDialog> {
  final AppointmentController _controller = AppointmentController();
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _dateController;
  late TextEditingController _timeController;
  int? _selectedProfessionalId;
  String? _selectedStatus;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  final List<String> _statusOptions = [
    'ABERTO',
    'AGENDADO',
    'REALIZADO',
    'FALTA',
    'CANCELADO'
  ];

  @override
  void initState() {
    super.initState();
    _initializeData();
    _controller.loadDependencies().then((_) {
      if (mounted) setState(() {});
    });
  }

  void _initializeData() {
    _selectedProfessionalId = widget.appointment.professionalId;
    _selectedStatus = widget.appointment.status;
    
    if (widget.appointment.dateTime != null) {
      _selectedDate = widget.appointment.dateTime;
      _selectedTime = TimeOfDay.fromDateTime(widget.appointment.dateTime!);
      _dateController = TextEditingController(
        text: DateFormat('dd/MM/yyyy').format(widget.appointment.dateTime!)
      );
      _timeController = TextEditingController(
        text: DateFormat('HH:mm').format(widget.appointment.dateTime!)
      );
    } else {
      _dateController = TextEditingController();
      _timeController = TextEditingController();
    }
  }

  @override
  void dispose() {
    _dateController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  Future<void> _pickTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? const TimeOfDay(hour: 8, minute: 0),
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
        _timeController.text = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      });
    }
  }

  Future<void> _save() async {
    if (_formKey.currentState!.validate()) {
      DateTime? finalDateTime;
      if (_selectedDate != null && _selectedTime != null) {
        finalDateTime = DateTime(
          _selectedDate!.year,
          _selectedDate!.month,
          _selectedDate!.day,
          _selectedTime!.hour,
          _selectedTime!.minute,
        );
      } else if (_selectedDate != null) {
         // Se tiver data mas não hora, assume 00:00 ou mantém se já tinha?
         // Melhor exigir ambos ou nenhum para "agendado".
         // Se status for ABERTO, pode ser null.
      }

      // Se mudar para AGENDADO, exige data e hora
      if (_selectedStatus == 'AGENDADO' && finalDateTime == null) {
         ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Para status AGENDADO, data e hora são obrigatórios.')),
        );
        return;
      }

      final updatedAppointment = AppointmentModel(
        id: widget.appointment.id,
        packageId: widget.appointment.packageId,
        dateTime: finalDateTime,
        status: _selectedStatus ?? widget.appointment.status,
        professionalId: _selectedProfessionalId,
      );

      final success = await _controller.updateAppointment(updatedAppointment);
      
      if (mounted) {
        if (success) {
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao atualizar: ${_controller.error}')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Editar Agendamento'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _dateController,
                decoration: const InputDecoration(
                  labelText: 'Data',
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                readOnly: true,
                onTap: _pickDate,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _timeController,
                decoration: const InputDecoration(
                  labelText: 'Hora',
                  suffixIcon: Icon(Icons.access_time),
                ),
                readOnly: true,
                onTap: _pickTime,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                decoration: const InputDecoration(labelText: 'Profissional'),
                value: _selectedProfessionalId,
                items: _controller.professionalsList.map((p) {
                  return DropdownMenuItem(
                    value: p.id,
                    child: Text(p.fullName),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _selectedProfessionalId = val),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Status'),
                value: _selectedStatus,
                items: _statusOptions.map((s) {
                  return DropdownMenuItem(
                    value: s,
                    child: Text(s),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _selectedStatus = val),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _controller.isLoading ? null : _save,
          child: _controller.isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Salvar'),
        ),
      ],
    );
  }
}
