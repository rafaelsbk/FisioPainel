import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../controllers/appointment_controller.dart';
import '../../../domain/models/appointment_model.dart';
import '../../../domain/models/professional_model.dart';

class AppointmentDialog extends StatefulWidget {
  final int packageId;

  const AppointmentDialog({super.key, required this.packageId});

  @override
  State<AppointmentDialog> createState() => _AppointmentDialogState();
}

class _AppointmentDialogState extends State<AppointmentDialog> {
  final AppointmentController _controller = AppointmentController();
  final _formKey = GlobalKey<FormState>();

  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  int? _selectedProfessionalId;
  final TextEditingController _dateCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.loadDependencies().then((_) {
      if (mounted) setState(() {});
    });
    _updateDateText();
  }

  void _updateDateText() {
    final dt = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );
    _dateCtrl.text = DateFormat('dd/MM/yyyy HH:mm').format(dt);
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: _selectedTime,
      );
      if (time != null) {
        setState(() {
          _selectedDate = date;
          _selectedTime = time;
          _updateDateText();
        });
      }
    }
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      final dt = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      final appointment = AppointmentModel(
        id: 0, // ID gerado pelo backend
        packageId: widget.packageId,
        dateTime: dt,
        status: 'AGENDADO',
        professionalId: _selectedProfessionalId,
      );

      final success = await _controller.createAppointment(appointment);
      if (success && mounted) {
        Navigator.pop(context, true);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_controller.error.isNotEmpty ? _controller.error : 'Erro ao agendar'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(20),
        child: _controller.isLoading
            ? const Center(child: CircularProgressIndicator())
            : Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Novo Agendamento', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _dateCtrl,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'Data e Hora',
                        suffixIcon: Icon(Icons.calendar_today),
                        border: OutlineInputBorder(),
                      ),
                      onTap: _pickDateTime,
                    ),
                    const SizedBox(height: 15),
                    DropdownButtonFormField<int>(
                      decoration: const InputDecoration(
                        labelText: 'Profissional',
                        border: OutlineInputBorder(),
                      ),
                      value: _selectedProfessionalId,
                      items: _controller.professionalsList.map((p) {
                        return DropdownMenuItem(
                          value: p.id,
                          child: Text(p.fullName),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => _selectedProfessionalId = val),
                    ),
                    const SizedBox(height: 25),
                    ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[800],
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 45),
                      ),
                      child: const Text('AGENDAR'),
                    )
                  ],
                ),
              ),
      ),
    );
  }
}
