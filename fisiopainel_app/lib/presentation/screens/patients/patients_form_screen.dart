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
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 5,
      child: Container(
        // Define uma largura máxima para não ficar esticado em telas grandes
        constraints: const BoxConstraints(maxWidth: 600),
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min, // Ocupa apenas o espaço necessário
          children: [
            // --- CABEÇALHO DO MODAL ---
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
            
            // --- CONTEÚDO ROLÁVEL ---
            Flexible(
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _nameCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Nome Completo *',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
                        ),
                        const SizedBox(height: 15),
                        // Layout adaptativo para CPF/RG
                        LayoutBuilder(builder: (context, constraints) {
                          if (constraints.maxWidth < 400) {
                            return Column(
                              children: [
                                TextFormField(
                                  controller: _cpfCtrl,
                                  decoration: const InputDecoration(
                                    labelText: 'CPF',
                                    border: OutlineInputBorder(),
                                    isDense: true,
                                  ),
                                ),
                                const SizedBox(height: 15),
                                TextFormField(
                                  controller: _rgCtrl,
                                  decoration: const InputDecoration(
                                    labelText: 'RG',
                                    border: OutlineInputBorder(),
                                    isDense: true,
                                  ),
                                ),
                              ],
                            );
                          }
                          return Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _cpfCtrl,
                                  decoration: const InputDecoration(
                                    labelText: 'CPF',
                                    border: OutlineInputBorder(),
                                    isDense: true,
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
                                    isDense: true,
                                  ),
                                ),
                              ),
                            ],
                          );
                        }),
                        const SizedBox(height: 15),
                        TextFormField(
                          controller: _emailCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                        const SizedBox(height: 15),
                        TextFormField(
                          controller: _phoneCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Telefone',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                        const SizedBox(height: 15),
                        TextFormField(
                          controller: _addressCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Endereço',
                            border: OutlineInputBorder(),
                            isDense: true,
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
                              backgroundColor: Colors.teal[700],
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: widget.controller.isLoading
                                ? const CircularProgressIndicator(
                                    color: Colors.white,
                                  )
                                : const Text(
                                    'SALVAR',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
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
