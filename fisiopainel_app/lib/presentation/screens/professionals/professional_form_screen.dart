import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../domain/models/professional_model.dart';
import '../../controllers/professional_controller.dart';
import '../../../domain/models/user_role_model.dart';

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

enum TaxaReposicaoTipo { porcentagem, fixo }

class _ProfessionalFormScreenState extends State<ProfessionalFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _cpfCtrl = TextEditingController();
  final _crefitoCtrl = TextEditingController();
  final _percentualCtrl = TextEditingController();
  final _valorRepasseFixoCtrl = TextEditingController();
  final _percentualTaxaReposicaoCtrl = TextEditingController();
  final _valorTaxaReposicaoFixoCtrl = TextEditingController();
  int? _selectedRoleId;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  TaxaReposicaoTipo _taxaReposicaoTipo = TaxaReposicaoTipo.porcentagem;

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
      _valorRepasseFixoCtrl.text = p.valorRepasseFixo?.toString() ?? '';
      _percentualTaxaReposicaoCtrl.text = p.percentualTaxaReposicao?.toString() ?? '';
      _valorTaxaReposicaoFixoCtrl.text = p.valorTaxaReposicaoFixo?.toString() ?? '';
      _selectedRoleId = p.usersRoles?.id;

      if (p.valorTaxaReposicaoFixo != null && p.valorTaxaReposicaoFixo! > 0) {
        _taxaReposicaoTipo = TaxaReposicaoTipo.fixo;
      } else {
        _taxaReposicaoTipo = TaxaReposicaoTipo.porcentagem;
      }
    }
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      if (_passwordCtrl.text != _confirmPasswordCtrl.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('As senhas não coincidem')),
        );
        return;
      }

      double? percentualReposicao = _taxaReposicaoTipo == TaxaReposicaoTipo.porcentagem 
          ? double.tryParse(_percentualTaxaReposicaoCtrl.text.replaceAll(',', '.')) 
          : null;
      double? valorReposicaoFixo = _taxaReposicaoTipo == TaxaReposicaoTipo.fixo 
          ? double.tryParse(_valorTaxaReposicaoFixoCtrl.text.replaceAll(',', '.')) 
          : null;

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
        usersRoles: _selectedRoleId != null ? UserRoleModel(id: _selectedRoleId!, nomeCargo: '', ativo: false) : null,
        percentualRepasse: double.tryParse(_percentualCtrl.text.replaceAll(',', '.')),
        valorRepasseFixo: double.tryParse(_valorRepasseFixoCtrl.text.replaceAll(',', '.')),
        percentualTaxaReposicao: percentualReposicao,
        valorTaxaReposicaoFixo: valorReposicaoFixo,
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
                              obscureText: _obscurePassword,
                              decoration: InputDecoration(
                                labelText: isEditing
                                    ? 'Nova Senha (opcional)'
                                    : 'Senha *',
                                border: const OutlineInputBorder(),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility
                                        : Icons.visibility_off,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                              ),
                              validator: (v) =>
                                  (!isEditing && (v == null || v.isEmpty))
                                  ? 'Obrigatório'
                                  : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _confirmPasswordCtrl,
                        obscureText: _obscureConfirmPassword,
                        decoration: InputDecoration(
                          labelText: isEditing
                              ? 'Confirmar Nova Senha'
                              : 'Confirmar Senha *',
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirmPassword
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureConfirmPassword =
                                    !_obscureConfirmPassword;
                              });
                            },
                          ),
                        ),
                        validator: (v) {
                          if (!isEditing && (v == null || v.isEmpty)) {
                            return 'Obrigatório';
                          }
                          if (_passwordCtrl.text.isNotEmpty &&
                              v != _passwordCtrl.text) {
                            return 'As senhas não coincidem';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 10),
                      FutureBuilder<List<UserRoleModel>>(
                        future: widget.controller.getUserRoles(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          if (snapshot.hasError) {
                            return const Text('Erro ao carregar os níveis de acesso');
                          }
                          final roles = snapshot.data ?? [];
                          if (_selectedRoleId == null && roles.isNotEmpty) {
                            _selectedRoleId = roles.firstWhere((r) => r.nomeCargo == 'Profissional', orElse: () => roles.first).id;
                          }
                          return DropdownButtonFormField<int?>(
                            initialValue: _selectedRoleId,
                            decoration: const InputDecoration(
                              labelText: 'Nível de Acesso (Role)',
                              border: OutlineInputBorder(),
                            ),
                            items: roles.map((role) {
                              return DropdownMenuItem<int?>(
                                value: role.id,
                                child: Text(role.nomeCargo),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  _selectedRoleId = val;
                                });
                              }
                            },
                          );
                        },
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
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
                        decoration: const InputDecoration(
                          labelText: '% Repasse',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _valorRepasseFixoCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
                        decoration: const InputDecoration(
                          labelText: 'Valor Repasse Fixo (R\$)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        "Taxas de Reposição (Substituição)",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          Expanded(
                            child: RadioListTile<TaxaReposicaoTipo>(
                              title: const Text('Porcentagem (%)', style: TextStyle(fontSize: 12)),
                              value: TaxaReposicaoTipo.porcentagem,
                              groupValue: _taxaReposicaoTipo,
                              contentPadding: EdgeInsets.zero,
                              onChanged: (val) {
                                setState(() => _taxaReposicaoTipo = val!);
                              },
                            ),
                          ),
                          Expanded(
                            child: RadioListTile<TaxaReposicaoTipo>(
                              title: const Text('Valor Fixo (R\$)', style: TextStyle(fontSize: 12)),
                              value: TaxaReposicaoTipo.fixo,
                              groupValue: _taxaReposicaoTipo,
                              contentPadding: EdgeInsets.zero,
                              onChanged: (val) {
                                setState(() => _taxaReposicaoTipo = val!);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      if (_taxaReposicaoTipo == TaxaReposicaoTipo.porcentagem)
                        TextFormField(
                          controller: _percentualTaxaReposicaoCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
                          decoration: const InputDecoration(
                            labelText: '% Taxa Reposição',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.percent),
                          ),
                        )
                      else
                        TextFormField(
                          controller: _valorTaxaReposicaoFixoCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
                          decoration: const InputDecoration(
                            labelText: 'Valor Taxa Reposição Fixo (R\$)',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.attach_money),
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
