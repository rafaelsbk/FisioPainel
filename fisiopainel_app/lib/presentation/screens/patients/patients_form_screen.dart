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
  bool _isActive = true;

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
      _isActive = p.isActive;
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
        isActive: _isActive,
      );

      final success = await widget.controller.savePatient(newPatient);

      if (success && mounted) {
        Navigator.of(context).pop(true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 8,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 800, minWidth: 400),
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- CABEÇALHO ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.patientToEdit == null ? 'Novo Paciente' : 'Editar Paciente',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(false),
                ),
              ],
            ),
            const Divider(height: 32),

            // --- CONTEÚDO ---
            Flexible(
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // SEÇÃO: IDENTIFICAÇÃO
                      const _SectionHeader(title: 'Identificação', icon: Icons.person_outline),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _nameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Nome Completo *',
                          prefixIcon: Icon(Icons.badge_outlined),
                        ),
                        validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _cpfCtrl,
                        decoration: const InputDecoration(
                          labelText: 'CPF',
                          prefixIcon: Icon(Icons.credit_card_outlined),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _rgCtrl,
                        decoration: const InputDecoration(
                          labelText: 'RG',
                          prefixIcon: Icon(Icons.fingerprint_outlined),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // SEÇÃO: CONTATO E ENDEREÇO
                      const _SectionHeader(title: 'Contato e Endereço', icon: Icons.contact_mail_outlined),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _emailCtrl,
                        decoration: const InputDecoration(
                          labelText: 'E-mail',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _phoneCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Telefone',
                          prefixIcon: Icon(Icons.phone_outlined),
                        ),
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _addressCtrl,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Endereço Completo',
                          prefixIcon: Icon(Icons.location_on_outlined),
                          alignLabelWithHint: true,
                        ),
                      ),

                      const SizedBox(height: 32),

                      // SEÇÃO: STATUS
                      if (widget.patientToEdit != null) ...[
                        const _SectionHeader(title: 'Configurações', icon: Icons.settings_outlined),
                        const SizedBox(height: 8),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Paciente Ativo'),
                          subtitle: Text(
                            _isActive ? 'Habilitado para novos pacotes' : 'Desabilitado pela administração',
                            style: const TextStyle(fontSize: 12),
                          ),
                          value: _isActive,
                          onChanged: (val) => setState(() => _isActive = val),
                          activeThumbColor: const Color(0xFF10B981),
                        ),
                      ],

                      const SizedBox(height: 32),

                      // BOTÃO DE AÇÃO
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          onPressed: widget.controller.isLoading ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3B82F6),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          child: widget.controller.isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : Text(
                                  widget.patientToEdit == null ? 'CADASTRAR PACIENTE' : 'SALVAR ALTERAÇÕES',
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                        ),
                      ),
                      const SizedBox(height: 8),
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

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF64748B)),
        const SizedBox(width: 8),
        Text(
          title.toUpperCase(),
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Color(0xFF64748B),
            letterSpacing: 1.1,
          ),
        ),
      ],
    );
  }
}
