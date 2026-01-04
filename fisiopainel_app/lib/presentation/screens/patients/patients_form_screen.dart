import 'package:flutter/material.dart';
import '../../../domain/models/patient_model.dart';
import '../../controllers/patient_controller.dart';

class PatientFormScreen extends StatefulWidget {
  final PatientController controller;
  final PatientModel? patientToEdit;

  const PatientFormScreen({
    super.key,
    required this.controller,
    this.patientToEdit,
  });

  @override
  State<PatientFormScreen> createState() => _PatientFormScreenState();
}

class _PatientFormScreenState extends State<PatientFormScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _cpfCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _rgCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.patientToEdit != null) {
      final p = widget.patientToEdit!;
      _nameCtrl.text = p.completeName;
      _emailCtrl.text = p.email ?? '';
      _cpfCtrl.text = p.cpf ?? '';
      _phoneCtrl.text = p.phoneNumber ?? '';
      _addressCtrl.text = p.address ?? '';
      _rgCtrl.text = p.rg ?? '';
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _cpfCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _rgCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      final newPatient = PatientModel(
        id: widget.patientToEdit?.id,
        completeName: _nameCtrl.text,
        email: _emailCtrl.text,
        cpf: _cpfCtrl.text,
        phoneNumber: _phoneCtrl.text,
        address: _addressCtrl.text,
        rg: _rgCtrl.text,
      );

      final success = await widget.controller.savePatient(newPatient);

      if (success && mounted) {
        // AQUI ESTÁ O SEGREDINHO:
        // Retorna 'true' para indicar que salvou com sucesso
        Navigator.of(context).pop(true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Usamos 'Dialog' para criar a janela flutuante
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 5,
      child: Container(
        // Define uma largura máxima para não ficar esticado em telas grandes
        constraints: const BoxConstraints(maxWidth: 600),
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min, // Ocupa apenas o espaço necessário
          children: [
            // --- CABAÇALHO DO MODAL ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.patientToEdit == null
                      ? 'Novo Paciente'
                      : 'Editar Paciente',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () =>
                      Navigator.of(context).pop(false), // Fecha sem salvar
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 10),

            // --- CONTEÚDO ROLÁVEL ---
            // Flexible + ListView permite que o modal role se a tela for pequena
            Flexible(
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _nameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Nome Completo *',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
                      ),
                      const SizedBox(height: 15),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _cpfCtrl,
                              decoration: const InputDecoration(
                                labelText: 'CPF',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: TextFormField(
                              controller: _rgCtrl,
                              decoration: const InputDecoration(
                                labelText: 'RG',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      TextFormField(
                        controller: _emailCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 15),
                      TextFormField(
                        controller: _phoneCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Telefone',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 15),
                      TextFormField(
                        controller: _addressCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Endereço',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 25),

                      // --- BOTÃO DE AÇÃO ---
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
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : const Text(
                                  'SALVAR',
                                  style: TextStyle(fontSize: 18),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
