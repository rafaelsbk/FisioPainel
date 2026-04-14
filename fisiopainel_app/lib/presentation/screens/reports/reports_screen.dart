import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../data/repositories/report_repository.dart';
import '../../../data/repositories/professional_repository.dart';
import '../../../domain/models/appointment_model.dart';
import '../../../domain/models/professional_model.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  // Repositories
  final ReportRepository _reportRepo = ReportRepository();
  final ProfessionalRepository _profRepo = ProfessionalRepository();

  // State
  List<ProfessionalModel> _professionals = [];
  int? _selectedProfessionalId;
  DateTimeRange? _selectedDateRange;

  bool _isLoading = false;
  Map<String, dynamic>? _reportData;
  Map<String, dynamic>? _financialData;

  @override
  void initState() {
    super.initState();
    _loadProfessionals();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadProfessionals() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final role = prefs.getString('user_role');

      if (role == 'ADMIN') {
        final list = await _profRepo.getProfessionals();
        if (mounted) {
          setState(() {
            _professionals = list;
          });
        }
      } else {
        // Assume user is PROFESSIONAL (or anything else restricted)
        // Construct a single item list with current user
        final userIdStr = prefs.getString('user_id');
        final username = prefs.getString('username') ?? 'Eu';

        if (userIdStr != null) {
          final currentProf = ProfessionalModel(
            id: int.parse(userIdStr),
            username: username,
            firstName:
                username, // Fallback as we might not have full details here without extra fetch
            lastName: '',
            email: '',
            phoneNumber: '',
            cpf: '',
            crefito: '',
          );

          if (mounted) {
            setState(() {
              _professionals = [currentProf];
              _selectedProfessionalId = currentProf.id;
            });
          }
        }
      }
    } catch (e) {
    }
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDateRange:
          _selectedDateRange ??
          DateTimeRange(
            start: DateTime.now().subtract(const Duration(days: 7)),
            end: DateTime.now(),
          ),
    );

    if (picked != null) {
      setState(() {
        _selectedDateRange = picked;
      });
    }
  }

  Future<void> _generateReport() async {
    if (_selectedProfessionalId == null || _selectedDateRange == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Selecione um profissional e um período."),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Fetch both reports
      final opData = await _reportRepo.getProfessionalReport(
        _selectedProfessionalId!,
        _selectedDateRange!.start,
        _selectedDateRange!.end,
      );

      final finData = await _reportRepo.getFinancialReport(
        _selectedProfessionalId!,
        _selectedDateRange!.start,
        _selectedDateRange!.end,
      );

      if (mounted) {
        setState(() {
          _reportData = opData;
          _financialData = finData;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Erro ao gerar relatório: $e")));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // --- SHARED FILTERS ---
        _buildFilters(),

        // --- CONTENT ---
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: _reportData == null || _financialData == null
                      ? const Center(
                          child: Text(
                            "Selecione os filtros e clique em Gerar.",
                          ),
                        )
                      : _buildUnifiedContent(),
                ),
        ),
      ],
    );
  }

  Widget _buildFilters() {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 1,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    decoration: const InputDecoration(
                      labelText: "Profissional",
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 0,
                      ),
                    ),
                    initialValue: _selectedProfessionalId,
                    items: _professionals.map((p) {
                      return DropdownMenuItem(
                        value: p.id,
                        child: Text(
                          p.fullName,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (val) =>
                        setState(() => _selectedProfessionalId = val),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: "Período",
                      suffixIcon: Icon(Icons.calendar_month),
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 0,
                      ),
                    ),
                    controller: TextEditingController(
                      text: _selectedDateRange == null
                          ? ""
                          : "${DateFormat('dd/MM/yy').format(_selectedDateRange!.start)} - ${DateFormat('dd/MM/yy').format(_selectedDateRange!.end)}",
                    ),
                    onTap: _pickDateRange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _generateReport,
                icon: const Icon(Icons.search),
                label: const Text("GERAR RELATÓRIO"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[800],
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUnifiedContent() {
    final opSummary = _reportData!['summary'];
    final finSummary = _financialData!['resumo'];
    final finDetails = _financialData!['detalhes'] as List;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- SUMMARY CARDS ---
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                "Atendimentos",
                "${opSummary['total_realizado']}",
                Colors.blue,
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: _buildSummaryCard(
                "Faltas",
                "${opSummary['total_falta']}",
                Colors.red,
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: _buildSummaryCard(
                "Repasse Studio",
                "R\$ ${finSummary['total_studio']}",
                Colors.purple,
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: _buildSummaryCard(
                "Repasse Prof.",
                "R\$ ${finSummary['total_repasse']}",
                Colors.orange,
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: _buildSummaryCard(
                "Receita Total",
                "R\$ ${finSummary['total_receita']}",
                Colors.green,
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // --- LIST HEADER ---
        const Text(
          "Atendimentos Realizados",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),

        // --- UNIFIED LIST ---
        if (finDetails.isEmpty)
          const Padding(
            padding: EdgeInsets.all(20.0),
            child: Center(
              child: Text("Nenhum atendimento realizado no período."),
            ),
          )
        else
          Column(
            children: finDetails.map((item) {
              final date = DateTime.parse(item['data_hora']).toLocal();
              return Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      // Date Box
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            Text(
                              DateFormat('dd/MM').format(date),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue[900],
                              ),
                            ),
                            Text(
                              DateFormat('HH:mm').format(date),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Patient Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  item['paciente'],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                if (item['is_reposicao'] == true) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.orange[100],
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                        color: Colors.orange[300]!,
                                      ),
                                    ),
                                    child: const Text(
                                      "REPOSIÇÃO",
                                      style: TextStyle(
                                        color: Colors.orange,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 4),
                            if (item['is_reposicao'] == true)
                              Text(
                                "Dono do Pacote: ${item['dono_pacote']}",
                                style: TextStyle(
                                  color: Colors.blue[700],
                                  fontSize: 12,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            const SizedBox(height: 4),
                            Text(
                              "Repasse: R\$ ${item['valor_repasse']}",
                              style: TextStyle(
                                color: Colors.orange[800],
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Studio: R\$ ${item['lucro_studio']}",
                              style: TextStyle(
                                color: Colors.purple[800],
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            if (item['is_reposicao'] == true)
                              Text(
                                "Realizado por: ${item['quem_realizou']}",
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 11,
                                ),
                              ),
                            const SizedBox(height: 4),
                            Text(
                              "Pacote: R\$ ${item['valor_total_pacote']} (Sessão ${item['progresso_sessao']})",
                              style: TextStyle(
                                color: Colors.grey[700],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Value Info
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            "Valor Sessão",
                            style: TextStyle(color: Colors.grey, fontSize: 11),
                          ),
                          Text(
                            "R\$ ${item['valor_sessao']}",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.green[700],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildSummaryCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              title,
              style: TextStyle(fontSize: 10, color: color.withOpacity(0.8)),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
