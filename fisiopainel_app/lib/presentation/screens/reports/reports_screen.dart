import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../data/services/storage_service.dart';
import '../../../data/repositories/report_repository.dart';
import '../../../data/repositories/professional_repository.dart';
import '../../../data/services/report_pdf_service.dart';
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
  final StorageService _storage = StorageService();

  // State
  List<ProfessionalModel> _professionals = [];
  int? _selectedProfessionalId;
  DateTimeRange? _selectedDateRange;

  bool _isLoading = false;
  bool _isPdfLoading = false;
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
      final role = await _storage.getUserRole();

      if (role == 'ADMIN') {
        final list = await _profRepo.getProfessionals();
        if (mounted) {
          setState(() {
            _professionals = list;
          });
        }
      } else {
        // Restricted access: Professional only sees themselves
        final userIdStr = await _storage.getUserId();
        final username = await _storage.getUsername() ?? 'Eu';

        if (userIdStr != null) {
          final userId = int.parse(userIdStr);

          // Try to find the full professional profile if already loaded or from API
          final allProfs = await _profRepo.getProfessionals();
          final currentProf = allProfs.firstWhere(
            (p) => p.id == userId,
            orElse: () => ProfessionalModel(
              id: userId,
              username: username,
              firstName: username,
              lastName: '',
              email: '',
              phoneNumber: '',
              cpf: '',
              crefito: '',
            ),
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
      debugPrint("Erro ao carregar profissionais: $e");
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

  Future<void> _downloadPdf() async {
    if (_reportData == null || _financialData == null || _selectedProfessionalId == null || _selectedDateRange == null) return;

    setState(() => _isPdfLoading = true);
    try {
      final prof = _professionals.firstWhere((p) => p.id == _selectedProfessionalId);
      await ReportPdfService.generateAndPrintReport(
        professional: prof,
        period: _selectedDateRange!,
        reportData: _reportData!,
        financialData: _financialData!,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro ao gerar PDF: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _isPdfLoading = false);
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
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _generateReport,
                    icon: const Icon(Icons.search),
                    label: const Text("GERAR RELATÓRIO"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[800],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                if (_reportData != null && _financialData != null) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 1,
                    child: OutlinedButton.icon(
                      onPressed: _isPdfLoading ? null : _downloadPdf,
                      icon: _isPdfLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.picture_as_pdf),
                      label: const Text("PDF"),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red[700],
                        side: BorderSide(color: Colors.red[700]!),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ],
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

    // Grouping logic: Month > Patient > Service Type > Appointments
    final Map<String, Map<String, Map<String, List<dynamic>>>> groupedData = {};

    for (var item in finDetails) {
      final date = DateTime.parse(item['data_hora']).toLocal();
      final monthKey = DateFormat('MMMM yyyy', 'pt_BR').format(date).toUpperCase();
      final patientKey = item['paciente'] ?? 'Desconhecido';
      final serviceKey = item['tipo_atendimento'] ?? 'Não informado';

      groupedData.putIfAbsent(monthKey, () => {});
      groupedData[monthKey]!.putIfAbsent(patientKey, () => {});
      groupedData[monthKey]![patientKey]!.putIfAbsent(serviceKey, () => []);
      groupedData[monthKey]![patientKey]![serviceKey]!.add(item);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- SUMMARY CARDS ---
        Row(
          children: [
            Expanded(child: _buildSummaryCard("Atendimentos", "${opSummary['total_realizado']}", Colors.blue)),
            const SizedBox(width: 4),
            Expanded(child: _buildSummaryCard("Faltas", "${opSummary['total_falta']}", Colors.red)),
            const SizedBox(width: 4),
            Expanded(child: _buildSummaryCard("Repasse Studio", "R\$ ${finSummary['total_studio']}", Colors.purple)),
            const SizedBox(width: 4),
            Expanded(child: _buildSummaryCard("Repasse Prof.", "R\$ ${finSummary['total_repasse']}", Colors.orange)),
            const SizedBox(width: 4),
            Expanded(child: _buildSummaryCard("Receita Total", "R\$ ${finSummary['total_receita']}", Colors.green)),
          ],
        ),

        const SizedBox(height: 24),

        if (groupedData.isEmpty)
          const Padding(
            padding: EdgeInsets.all(20.0),
            child: Center(child: Text("Nenhum atendimento realizado no período.")),
          )
        else
          ...groupedData.entries.map((monthEntry) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // MONTH HEADER
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.blueGrey[800],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    monthEntry.key,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                const SizedBox(height: 12),

                ...monthEntry.value.entries.map((patientEntry) {
                  return Padding(
                    padding: const EdgeInsets.only(left: 8.0, bottom: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // PATIENT HEADER
                        Row(
                          children: [
                            const Icon(Icons.person, size: 20, color: Colors.blue),
                            const SizedBox(width: 8),
                            Text(
                              patientEntry.key,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                            ),
                          ],
                        ),
                        const Divider(),

                        ...patientEntry.value.entries.map((serviceEntry) {
                          return Padding(
                            padding: const EdgeInsets.only(left: 16.0, bottom: 12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // SERVICE TYPE HEADER
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.blue[50],
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: Colors.blue[100]!),
                                  ),
                                  child: Text(
                                    serviceEntry.key.toUpperCase(),
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blue[900]),
                                  ),
                                ),
                                const SizedBox(height: 8),

                                // SESSIONS LIST
                                ...serviceEntry.value.map((item) {
                                  final date = DateTime.parse(item['data_hora']).toLocal();
                                  return _buildAppointmentCard(item, date);
                                }).toList(),
                              ],
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  );
                }).toList(),
                const SizedBox(height: 16),
              ],
            );
          }).toList(),
      ],
    );
  }

  Widget _buildAppointmentCard(dynamic item, DateTime date) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            // Date Box
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Text(
                    DateFormat('dd/MM').format(date),
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue[900]),
                  ),
                  Text(
                    DateFormat('HH:mm').format(date),
                    style: TextStyle(fontSize: 12, color: Colors.blue[700]),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        "Sessão ${item['progresso_sessao']}",
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      if (item['is_reposicao'] == true) ...[
                        const SizedBox(width: 8),
                        _buildBadge("REPOSIÇÃO", Colors.orange),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Repasse: R\$ ${item['valor_repasse']} | Studio: R\$ ${item['lucro_studio']}",
                    style: TextStyle(color: Colors.grey[700], fontSize: 12),
                  ),
                  if (item['is_reposicao'] == true)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        "Realizado por: ${item['quem_realizou']}",
                        style: TextStyle(color: Colors.grey[600], fontSize: 11, fontStyle: FontStyle.italic),
                      ),
                    ),
                ],
              ),
            ),

            // Value Info
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text("Valor", style: TextStyle(color: Colors.grey, fontSize: 11)),
                Text(
                  "R\$ ${item['valor_sessao']}",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green[700]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
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
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
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
