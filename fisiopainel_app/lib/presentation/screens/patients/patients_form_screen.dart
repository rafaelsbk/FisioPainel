import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../domain/models/patient_model.dart';
import '../../controllers/patient_controller.dart';
import '../../widgets/cpf_formatter.dart';
import '../../widgets/phone_formatter.dart';

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
  final List<TextEditingController> _phoneCtrls = [];
  final _addressCtrl = TextEditingController();
  final _rgCtrl = TextEditingController();

  final _cepCtrl = TextEditingController();
  final _stateCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _neighborhoodCtrl = TextEditingController();
  final _numberCtrl = TextEditingController();
  final _complementCtrl = TextEditingController();

  bool _isActive = true;
  bool _isCepLoading = false;

  final _cpfFocus = FocusNode();
  final _cepFocus = FocusNode();
  String? _cpfError;

  @override
  void initState() {
    super.initState();
    if (widget.patientToEdit != null) {
      final p = widget.patientToEdit!;
      _nameCtrl.text = p.completeName;
      _emailCtrl.text = p.email ?? '';
      _cpfCtrl.text = CpfInputFormatter.format(p.cpf ?? '');
      
      // Carregar telefones da lista ou do campo antigo
      if (p.phones != null && p.phones!.isNotEmpty) {
        for (var phone in p.phones!) {
          _phoneCtrls.add(TextEditingController(text: PhoneInputFormatter.format(phone.number)));
        }
      } else if (p.phoneNumber != null && p.phoneNumber!.isNotEmpty) {
        _phoneCtrls.add(TextEditingController(text: PhoneInputFormatter.format(p.phoneNumber!)));
      }

      _addressCtrl.text = p.address ?? '';
      _rgCtrl.text = p.rg ?? '';
      _isActive = p.isActive;

      _cepCtrl.text = p.cep ?? '';
      _stateCtrl.text = p.estado ?? '';
      _cityCtrl.text = p.cidade ?? '';
      _neighborhoodCtrl.text = p.bairro ?? '';
      _numberCtrl.text = p.numero ?? '';
      _complementCtrl.text = p.complemento ?? '';
    }

    // Garantir pelo menos um campo de telefone
    if (_phoneCtrls.isEmpty) {
      _phoneCtrls.add(TextEditingController());
    }

    _cpfFocus.addListener(() {
      if (!_cpfFocus.hasFocus) {
        _checkDuplicateCpf();
      }
    });

    _cepFocus.addListener(() {
      if (!_cepFocus.hasFocus) {
        _searchCep();
      }
    });
  }

  void _addPhoneField() {
    setState(() {
      _phoneCtrls.add(TextEditingController());
    });
  }

  void _removePhoneField(int index) {
    if (_phoneCtrls.length > 1) {
      setState(() {
        _phoneCtrls[index].dispose();
        _phoneCtrls.removeAt(index);
      });
    }
  }

  Future<void> _searchCep() async {
    final cep = _cepCtrl.text.replaceAll(RegExp(r'\D'), '');
    if (cep.length != 8) return;

    setState(() => _isCepLoading = true);

    try {
      final response = await http.get(Uri.parse('https://viacep.com.br/ws/$cep/json/'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['erro'] == true) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('CEP não encontrado')),
            );
          }
        } else {
          setState(() {
            _stateCtrl.text = data['uf'] ?? '';
            _cityCtrl.text = data['localidade'] ?? '';
            _neighborhoodCtrl.text = data['bairro'] ?? '';
            _addressCtrl.text = data['logradouro'] ?? '';
          });
        }
      }
    } catch (e) {
      debugPrint('Erro ao buscar CEP: $e');
    } finally {
      if (mounted) setState(() => _isCepLoading = false);
    }
  }

  void _checkDuplicateCpf() {
    final cpfRaw = _cpfCtrl.text.replaceAll(RegExp(r'\D'), '');
    if (cpfRaw.isEmpty) {
      setState(() => _cpfError = null);
      return;
    }

    // Procura duplicados na lista do controller
    PatientModel? duplicate;
    for (var p in widget.controller.allPatients) {
      final pCpfRaw = p.cpf?.replaceAll(RegExp(r'\D'), '') ?? '';
      if (pCpfRaw == cpfRaw && p.id != widget.patientToEdit?.id) {
        duplicate = p;
        break;
      }
    }

    if (duplicate != null) {
      final errorMsg = 'CPF JÁ CADASTRADO, NO NOME ${duplicate.completeName}';
      setState(() => _cpfError = errorMsg);
      
      // Mostrar Modal
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
          content: Text('Atenção: Este CPF já pertence ao paciente "${duplicate!.completeName}".'),
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
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _cpfCtrl.dispose();
    for (var ctrl in _phoneCtrls) {
      ctrl.dispose();
    }
    _addressCtrl.dispose();
    _rgCtrl.dispose();
    _cpfFocus.dispose();

    _cepCtrl.dispose();
    _stateCtrl.dispose();
    _cityCtrl.dispose();
    _neighborhoodCtrl.dispose();
    _numberCtrl.dispose();
    _complementCtrl.dispose();
    _cepFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    _checkDuplicateCpf();
    if (_cpfError != null) return;

    if (_formKey.currentState!.validate()) {
      final newPatient = PatientModel(
        id: widget.patientToEdit?.id,
        completeName: _nameCtrl.text,
        email: _emailCtrl.text,
        cpf: _cpfCtrl.text,
        phoneNumber: _phoneCtrls.isNotEmpty ? _phoneCtrls[0].text : '',
        phones: _phoneCtrls
            .where((c) => c.text.isNotEmpty)
            .map((c) => PhoneModel(number: c.text))
            .toList(),
        address: _addressCtrl.text,
        cep: _cepCtrl.text,
        estado: _stateCtrl.text,
        cidade: _cityCtrl.text,
        bairro: _neighborhoodCtrl.text,
        numero: _numberCtrl.text,
        complemento: _complementCtrl.text,
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
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Nome Completo *',
                          prefixIcon: Icon(Icons.badge_outlined),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Obrigatório';
                          if (v.isNotEmpty && v[0] != v[0].toUpperCase()) {
                            return 'A primeira letra deve ser maiúscula';
                          }
                          return null;
                        },
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
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              "Telefones *",
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF64748B)),
                            ),
                          ),
                          IconButton(
                            onPressed: _addPhoneField,
                            icon: const Icon(Icons.add_circle_outline, color: Color(0xFF3B82F6)),
                            tooltip: "Adicionar Telefone",
                          ),
                        ],
                      ),
                      ...List.generate(_phoneCtrls.length, (index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _phoneCtrls[index],
                                  decoration: InputDecoration(
                                    labelText: 'Telefone ${index + 1}',
                                    prefixIcon: const Icon(Icons.phone_outlined),
                                  ),
                                  keyboardType: TextInputType.phone,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    PhoneInputFormatter(),
                                  ],
                                  validator: (v) => (index == 0 && (v == null || v.isEmpty)) ? 'Obrigatório' : null,
                                ),
                              ),
                              if (_phoneCtrls.length > 1)
                                IconButton(
                                  onPressed: () => _removePhoneField(index),
                                  icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                                ),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: _cepCtrl,
                              focusNode: _cepFocus,
                              decoration: InputDecoration(
                                labelText: 'CEP',
                                prefixIcon: const Icon(Icons.map_outlined),
                                suffixIcon: _isCepLoading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: Padding(
                                            padding: EdgeInsets.all(12),
                                            child: CircularProgressIndicator(strokeWidth: 2)))
                                    : null,
                              ),
                              keyboardType: TextInputType.number,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              onChanged: (v) {
                                if (v.length == 8) _searchCep();
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _stateCtrl,
                              decoration: const InputDecoration(labelText: 'UF'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _cityCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Cidade',
                          prefixIcon: Icon(Icons.location_city_outlined),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _neighborhoodCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Bairro',
                          prefixIcon: Icon(Icons.holiday_village_outlined),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _addressCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Logradouro (Rua/Avenida)',
                          prefixIcon: Icon(Icons.location_on_outlined),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _numberCtrl,
                              decoration: const InputDecoration(labelText: 'Número'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: _complementCtrl,
                              decoration: const InputDecoration(labelText: 'Complemento'),
                            ),
                          ),
                        ],
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
