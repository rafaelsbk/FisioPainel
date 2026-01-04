import 'package:flutter/material.dart';
import '../../../domain/models/professional_model.dart';
import '../../controllers/professional_controller.dart';

class ProfessionalFormScreen extends StatefulWidget {
  final ProfessionalController controller;
  final ProfessionalModel? professionalToEdit; // Novo parâmetro

  const ProfessionalFormScreen({
    super.key,
    required this.controller,
    this.professionalToEdit, // Opcional
  });

  @override
  State<ProfessionalFormScreen> createState() => _ProfessionalFormScreenState();
}

class _ProfessionalFormScreenState extends State<ProfessionalFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _cpfCtrl = TextEditingController();
  final _crefitoCtrl = TextEditingController();
  final _percentualCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Se for edição, preenche os campos
    if (widget.professionalToEdit != null) {
      final p = widget.professionalToEdit!;
      _usernameCtrl.text = p.username;
      _firstNameCtrl.text = p.firstName;
      _lastNameCtrl.text = p.lastName;
      _emailCtrl.text = p.email;
      _phoneCtrl.text = p.phoneNumber;
      _cpfCtrl.text = p.cpf;
      _crefitoCtrl.text = p.crefito;
      _percentualCtrl.text = p.percentualRepasse?.toString() ?? '';
    }
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      final newProfessional = ProfessionalModel(
        id: widget.professionalToEdit?.id, // Mantém ID se existir
        username: _usernameCtrl.text,
        password: _passwordCtrl.text.isEmpty
            ? null
            : _passwordCtrl.text, // Senha opcional na edição
        firstName: _firstNameCtrl.text,
        lastName: _lastNameCtrl.text,
        email: _emailCtrl.text,
        phoneNumber: _phoneCtrl.text,
        cpf: _cpfCtrl.text,
        crefito: _crefitoCtrl.text,
        percentualRepasse: double.tryParse(_percentualCtrl.text),
        valorRepasseFixo: null,
      );

      final success = await widget.controller.saveProfessional(newProfessional);

      if (success && mounted) {
        Navigator.of(context).pop(true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.professionalToEdit != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 700),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isEditing ? 'Editar Profissional' : 'Novo Profissional',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(),
            Flexible(
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Seção Acesso
                      const Text(
                        "Dados de Acesso",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _usernameCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Usuário *',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          // Senha só é obrigatória se NÃO estiver editando
                          Expanded(
                            child: TextFormField(
                              controller: _passwordCtrl,
                              obscureText: true,
                              decoration: InputDecoration(
                                labelText: isEditing
                                    ? 'Senha (Deixe vazio para manter)'
                                    : 'Senha *',
                                border: const OutlineInputBorder(),
                              ),
                              validator: (v) =>
                                  (!isEditing && (v == null || v.isEmpty))
                                  ? 'Obrigatório'
                                  : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Outros campos (resumido para brevidade - mantenha os do passo anterior)
                      TextFormField(
                        controller: _firstNameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Nome',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _lastNameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Sobrenome',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _emailCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _cpfCtrl,
                        decoration: const InputDecoration(
                          labelText: 'CPF',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _phoneCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Telefone',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _crefitoCtrl,
                        decoration: const InputDecoration(
                          labelText: 'CREFITO',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _percentualCtrl,
                        decoration: const InputDecoration(
                          labelText: '% Repasse',
                          border: OutlineInputBorder(),
                        ),
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
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : const Text('SALVAR'),
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
