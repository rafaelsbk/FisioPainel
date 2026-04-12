import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../domain/models/professional_model.dart';
import '../../controllers/professional_controller.dart';
import '../../../domain/models/user_role_model.dart';
import '../../widgets/cpf_formatter.dart';
import '../../widgets/phone_formatter.dart';

class ProfessionalFormScreen extends StatefulWidget {
  final ProfessionalController controller;
  final ProfessionalModel? professionalToEdit;

  const ProfessionalFormScreen({
    super.key,
    required this.controller,
    this.professionalToEdit,
  });

  @override
  State<ProfessionalFormScreen> createState() => _ProfessionalFormScreenState();
}

enum TaxaReposicaoTipo { porcentagem, fixo }
enum RepasseTipo { porcentagem, fixo }

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

  final _cpfFocus = FocusNode();
  String? _cpfError;

  TaxaReposicaoTipo _taxaReposicaoTipo = TaxaReposicaoTipo.porcentagem;
  RepasseTipo _repasseTipo = RepasseTipo.porcentagem;

  @override
  void initState() {
    super.initState();
    if (widget.professionalToEdit != null) {
      final p = widget.professionalToEdit!;
      _usernameCtrl.text = p.username;
      _firstNameCtrl.text = p.firstName;
      _lastNameCtrl.text = p.lastName;
      _emailCtrl.text = p.email;
      _phoneCtrl.text = PhoneInputFormatter.format(p.phoneNumber);
      _cpfCtrl.text = CpfInputFormatter.format(p.cpf);
      _crefitoCtrl.text = p.crefito;
      _percentualCtrl.text = p.percentualRepasse?.toString() ?? '';
      _valorRepasseFixoCtrl.text = p.valorRepasseFixo?.toString() ?? '';
      _percentualTaxaReposicaoCtrl.text = p.percentualTaxaReposicao?.toString() ?? '';
      _valorTaxaReposicaoFixoCtrl.text = p.valorTaxaReposicaoFixo?.toString() ?? '';
      _selectedRoleId = p.usersRoles?.id;

      if (p.valorRepasseFixo != null && p.valorRepasseFixo! > 0) {
        _repasseTipo = RepasseTipo.fixo;
      } else {
        _repasseTipo = RepasseTipo.porcentagem;
      }

      if (p.valorTaxaReposicaoFixo != null && p.valorTaxaReposicaoFixo! > 0) {
        _taxaReposicaoTipo = TaxaReposicaoTipo.fixo;
      } else {
        _taxaReposicaoTipo = TaxaReposicaoTipo.porcentagem;
      }
    }

    _cpfFocus.addListener(() {
      if (!_cpfFocus.hasFocus) {
        _checkDuplicateCpf();
      }
    });
  }

  void _checkDuplicateCpf() {
    final cpfRaw = _cpfCtrl.text.replaceAll(RegExp(r'\D'), '');
    if (cpfRaw.isEmpty) {
      setState(() => _cpfError = null);
      return;
    }

    ProfessionalModel? duplicate;
    for (var p in widget.controller.allProfessionals) {
      final pCpfRaw = p.cpf.replaceAll(RegExp(r'\D'), '');
      if (pCpfRaw == cpfRaw && p.id != widget.professionalToEdit?.id) {
        duplicate = p;
        break;
      }
    }

    if (duplicate != null) {
      final errorMsg = 'CPF JÁ CADASTRADO, NO NOME ${duplicate.fullName}';
      setState(() => _cpfError = errorMsg);

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange),
              SizedBox(width: 10),
              Text('CPF Duplicado'),
            ],
          ),
          content: Text('Atenção: Este CPF já pertence ao profissional "${duplicate!.fullName}".'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('ENTENDI'),
            ),
          ],
        ),
      );
    } else {
      setState(() => _cpfError = null);
    }
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _cpfCtrl.dispose();
    _crefitoCtrl.dispose();
    _percentualCtrl.dispose();
    _valorRepasseFixoCtrl.dispose();
    _percentualTaxaReposicaoCtrl.dispose();
    _valorTaxaReposicaoFixoCtrl.dispose();
    _cpfFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    _checkDuplicateCpf();
    if (_cpfError != null) return;

    if (_formKey.currentState!.validate()) {
      if (_passwordCtrl.text != _confirmPasswordCtrl.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('As senhas não coincidem')),
        );
        return;
      }

      double? percentualRepasse = _repasseTipo == RepasseTipo.porcentagem
          ? double.tryParse(_percentualCtrl.text.replaceAll(',', '.'))
          : null;
      double? valorRepasseFixo = _repasseTipo == RepasseTipo.fixo
          ? double.tryParse(_valorRepasseFixoCtrl.text.replaceAll(',', '.'))
          : null;

      double? percentualReposicao = _taxaReposicaoTipo == TaxaReposicaoTipo.porcentagem
          ? double.tryParse(_percentualTaxaReposicaoCtrl.text.replaceAll(',', '.'))
          : null;
      double? valorReposicaoFixo = _taxaReposicaoTipo == TaxaReposicaoTipo.fixo
          ? double.tryParse(_valorTaxaReposicaoFixoCtrl.text.replaceAll(',', '.'))
          : null;

      final newProfessional = ProfessionalModel(
        id: widget.professionalToEdit?.id,
        username: _usernameCtrl.text,
        password: _passwordCtrl.text.isEmpty ? null : _passwordCtrl.text,
        firstName: _firstNameCtrl.text,
        lastName: _lastNameCtrl.text,
        email: _emailCtrl.text,
        phoneNumber: _phoneCtrl.text,
        cpf: _cpfCtrl.text,
        crefito: _crefitoCtrl.text,
        usersRoles: _selectedRoleId != null ? UserRoleModel(id: _selectedRoleId!, nomeCargo: '', ativo: false) : null,
        percentualRepasse: percentualRepasse,
        valorRepasseFixo: valorRepasseFixo,
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
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 8,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 800, minWidth: 400),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isEditing ? 'Editar Profissional' : 'Novo Profissional',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(height: 32),
            Flexible(
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // SEÇÃO: DADOS DE ACESSO
                      const _SectionHeader(title: 'Dados de Acesso', icon: Icons.lock_outline),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _usernameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Usuário *',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordCtrl,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: isEditing ? 'Nova Senha (opcional)' : 'Senha *',
                          prefixIcon: const Icon(Icons.key_outlined),
                          suffixIcon: IconButton(
                            icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                        validator: (v) => (!isEditing && (v == null || v.isEmpty)) ? 'Obrigatório' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _confirmPasswordCtrl,
                        obscureText: _obscureConfirmPassword,
                        decoration: InputDecoration(
                          labelText: isEditing ? 'Confirmar Nova Senha' : 'Confirmar Senha *',
                          prefixIcon: const Icon(Icons.key_outlined),
                          suffixIcon: IconButton(
                            icon: Icon(_obscureConfirmPassword ? Icons.visibility : Icons.visibility_off),
                            onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                          ),
                        ),
                        validator: (v) {
                          if (!isEditing && (v == null || v.isEmpty)) return 'Obrigatório';
                          if (_passwordCtrl.text.isNotEmpty && v != _passwordCtrl.text) return 'As senhas não coincidem';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      FutureBuilder<List<UserRoleModel>>(
                        future: widget.controller.getUserRoles(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const LinearProgressIndicator();
                          }
                          final roles = snapshot.data ?? [];
                          if (_selectedRoleId == null && roles.isNotEmpty) {
                            _selectedRoleId = roles.firstWhere((r) => r.nomeCargo == 'Profissional', orElse: () => roles.first).id;
                          }
                          return DropdownButtonFormField<int?>(
                            value: _selectedRoleId,
                            decoration: const InputDecoration(
                              labelText: 'Nível de Acesso *',
                              prefixIcon: Icon(Icons.admin_panel_settings_outlined),
                            ),
                            items: roles.map((role) {
                              return DropdownMenuItem<int?>(value: role.id, child: Text(role.nomeCargo));
                            }).toList(),
                            onChanged: (val) => setState(() => _selectedRoleId = val),
                          );
                        },
                      ),

                      const SizedBox(height: 32),

                      // SEÇÃO: DADOS PESSOAIS
                      const _SectionHeader(title: 'Dados Pessoais', icon: Icons.person_outline),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _firstNameCtrl,
                        decoration: const InputDecoration(labelText: 'Nome', prefixIcon: Icon(Icons.badge_outlined)),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _lastNameCtrl,
                        decoration: const InputDecoration(labelText: 'Sobrenome', prefixIcon: Icon(Icons.badge_outlined)),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _emailCtrl,
                        decoration: const InputDecoration(labelText: 'E-mail', prefixIcon: Icon(Icons.email_outlined)),
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _cpfCtrl,
                        focusNode: _cpfFocus,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          CpfInputFormatter(),
                        ],
                        decoration: InputDecoration(
                          labelText: 'CPF',
                          prefixIcon: const Icon(Icons.credit_card_outlined),
                          errorText: _cpfError,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _phoneCtrl,
                        decoration: const InputDecoration(labelText: 'Telefone', prefixIcon: Icon(Icons.phone_outlined)),
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          PhoneInputFormatter(),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _crefitoCtrl,
                        decoration: const InputDecoration(labelText: 'CREFITO', prefixIcon: Icon(Icons.medical_services_outlined)),
                      ),

                      const SizedBox(height: 32),

                      // SEÇÃO: REPASSE FINANCEIRO
                      const _SectionHeader(title: 'Repasse Financeiro', icon: Icons.payments_outlined),
                      const SizedBox(height: 16),
                      const Text("Tipo de Repasse:", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.blueGrey)),
                      Row(
                        children: [
                          Expanded(
                            child: RadioListTile<RepasseTipo>(
                              title: const Text('Porcentagem (%)', style: TextStyle(fontSize: 12)),
                              value: RepasseTipo.porcentagem,
                              groupValue: _repasseTipo,
                              contentPadding: EdgeInsets.zero,
                              onChanged: (val) => setState(() => _repasseTipo = val!),
                            ),
                          ),
                          Expanded(
                            child: RadioListTile<RepasseTipo>(
                              title: const Text('Valor Fixo (R\$)', style: TextStyle(fontSize: 12)),
                              value: RepasseTipo.fixo,
                              groupValue: _repasseTipo,
                              contentPadding: EdgeInsets.zero,
                              onChanged: (val) => setState(() => _repasseTipo = val!),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (_repasseTipo == RepasseTipo.porcentagem)
                        TextFormField(
                          controller: _percentualCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
                          decoration: const InputDecoration(
                            labelText: '% Repasse',
                            prefixIcon: Icon(Icons.percent),
                          ),
                        )
                      else
                        TextFormField(
                          controller: _valorRepasseFixoCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
                          decoration: const InputDecoration(
                            labelText: 'Valor Repasse Fixo (R\$)',
                            prefixIcon: Icon(Icons.attach_money),
                          ),
                        ),

                      const SizedBox(height: 32),

                      // SEÇÃO: TAXA DE REPOSIÇÃO
                      const _SectionHeader(title: 'Taxa de Reposição', icon: Icons.swap_horiz_outlined),
                      const SizedBox(height: 16),
                      const Text("Tipo de Taxa (Substituição):", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.blueGrey)),
                      Row(
                        children: [
                          Expanded(
                            child: RadioListTile<TaxaReposicaoTipo>(
                              title: const Text('Porcentagem (%)', style: TextStyle(fontSize: 12)),
                              value: TaxaReposicaoTipo.porcentagem,
                              groupValue: _taxaReposicaoTipo,
                              contentPadding: EdgeInsets.zero,
                              onChanged: (val) => setState(() => _taxaReposicaoTipo = val!),
                            ),
                          ),
                          Expanded(
                            child: RadioListTile<TaxaReposicaoTipo>(
                              title: const Text('Valor Fixo (R\$)', style: TextStyle(fontSize: 12)),
                              value: TaxaReposicaoTipo.fixo,
                              groupValue: _taxaReposicaoTipo,
                              contentPadding: EdgeInsets.zero,
                              onChanged: (val) => setState(() => _taxaReposicaoTipo = val!),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (_taxaReposicaoTipo == TaxaReposicaoTipo.porcentagem)
                        TextFormField(
                          controller: _percentualTaxaReposicaoCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
                          decoration: const InputDecoration(
                            labelText: '% Taxa Reposição',
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
                            prefixIcon: Icon(Icons.attach_money),
                          ),
                        ),

                      const SizedBox(height: 40),

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
                                  isEditing ? 'SALVAR ALTERAÇÕES' : 'CADASTRAR PROFISSIONAL',
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
