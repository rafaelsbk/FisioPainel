import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../../controllers/global_appointment_controller.dart';
import '../../../domain/models/appointment_model.dart';
import 'appointment_detail_screen.dart';
import '../../widgets/network_error_dialog.dart';

class GlobalAppointmentsScreen extends StatefulWidget {
  const GlobalAppointmentsScreen({super.key});

  @override
  State<GlobalAppointmentsScreen> createState() => _GlobalAppointmentsScreenState();
}

class _GlobalAppointmentsScreenState extends State<GlobalAppointmentsScreen> {
  final GlobalAppointmentController _controller = GlobalAppointmentController();
  bool _isListView = false;
  DateTime _focusedDate = DateTime.now();
  bool _localeInitialized = false;

  @override
  void initState() {
    super.initState();
    _initLocale();
    _controller.addListener(_onControllerChange);
    _controller.loadAppointments();
  }

  void _onControllerChange() {
    if (mounted) {
      if (_controller.error.isNotEmpty) {
        final err = _controller.error.toLowerCase();
        if (err.contains('socketexception') || 
            err.contains('connection refused') || 
            err.contains('failed host lookup') ||
            err.contains('was not successful')) {
          NetworkErrorDialog.show(context, _controller.error);
        }
      }
      setState(() {});
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChange);
    super.dispose();
  }

  Future<void> _initLocale() async {
    await initializeDateFormatting('pt_BR', null);
    if (mounted) {
      setState(() {
        _localeInitialized = true;
      });
    }
  }

  // --- NAVEGAÇÃO DE SEMANA ---
  void _previousWeek() {
    setState(() {
      _focusedDate = _focusedDate.subtract(const Duration(days: 7));
    });
  }

  void _nextWeek() {
    setState(() {
      _focusedDate = _focusedDate.add(const Duration(days: 7));
    });
  }

  void _today() {
    setState(() {
      _focusedDate = DateTime.now();
    });
  }

  // --- CÁLCULO DE DIAS DA SEMANA ---
  DateTime _getStartOfWeek(DateTime date) {
    // No Dart 1=Segunda, 7=Domingo. Queremos que a semana comece na Segunda.
    return date.subtract(Duration(days: date.weekday - 1));
  }

  List<DateTime> _getWeekDays() {
    final start = _getStartOfWeek(_focusedDate);
    return List.generate(7, (i) => DateTime(start.year, start.month, start.day + i));
  }

  // --- FILTRAGEM ---
  List<AppointmentModel> _getAppointmentsForSlot(DateTime day, int hour) {
    return _controller.appointments.where((a) {
      if (a.dateTime == null) return false;
      return a.dateTime!.year == day.year &&
             a.dateTime!.month == day.month &&
             a.dateTime!.day == day.day &&
             a.dateTime!.hour == hour;
    }).toList();
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'AGENDADO': return Colors.blue[700]!;
      case 'REALIZADO': return Colors.green[700]!;
      case 'CANCELADO': return Colors.red[700]!;
      case 'FALTA': return Colors.orange[800]!;
      default: return Colors.grey[700]!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          _buildHeader(),
          const SizedBox(height: 10),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _controller.loadAppointments,
              child: _controller.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _isListView ? _buildListView() : _buildCalendarView(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final weekDays = _getWeekDays();
    final monthName = DateFormat('MMMM yyyy', 'pt_BR').format(_focusedDate);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  monthName.toUpperCase(),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue),
                  overflow: TextOverflow.ellipsis,
                ),
                const Text("Agenda Geral", style: TextStyle(color: Colors.grey)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  IconButton(onPressed: _previousWeek, icon: const Icon(Icons.chevron_left)),
                  TextButton(onPressed: _today, child: const Text("HOJE")),
                  IconButton(onPressed: _nextWeek, icon: const Icon(Icons.chevron_right)),
                  const SizedBox(width: 10),
                  const VerticalDivider(),
                  const SizedBox(width: 10),
                  ToggleButtons(
                    isSelected: [!_isListView, _isListView],
                    onPressed: (index) => setState(() => _isListView = index == 1),
                    borderRadius: BorderRadius.circular(8),
                    constraints: const BoxConstraints(minHeight: 36, minWidth: 44),
                    children: const [
                      Icon(Icons.calendar_view_week, size: 20),
                      Icon(Icons.list, size: 20),
                    ],
                  ),
                  const SizedBox(width: 10),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: () => _controller.loadAppointments(),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarView() {
    final days = _getWeekDays();
    final hours = List.generate(14, (i) => i + 6); // 6:00 até 19:00

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Header dos Dias
          Container(
            padding: const EdgeInsets.only(left: 60),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
            ),
            child: Row(
              children: days.map((day) {
                final isToday = day.day == DateTime.now().day && day.month == DateTime.now().month;
                return Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Column(
                      children: [
                        Text(
                          DateFormat('EEE', 'pt_BR').format(day).toUpperCase(),
                          style: TextStyle(fontSize: 12, color: isToday ? Colors.blue : Colors.grey[600]),
                        ),
                        const SizedBox(height: 4),
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: isToday ? Colors.blue : Colors.transparent,
                          child: Text(
                            day.day.toString(),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isToday ? Colors.white : Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          // Grid de Horários
          Expanded(
            child: SingleChildScrollView(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Coluna de Horas
                  Column(
                    children: hours.map((hour) => Container(
                      width: 60,
                      height: 80,
                      alignment: Alignment.topCenter,
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        "${hour.toString().padLeft(2, '0')}:00",
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    )).toList(),
                  ),
                  // Colunas de Agendamentos
                  ...days.map((day) => Expanded(
                    child: Stack(
                      children: [
                        // Linhas de Fundo
                        Column(
                          children: hours.map((hour) => Container(
                            height: 80,
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(color: Colors.grey[100]!),
                                left: BorderSide(color: Colors.grey[100]!),
                              ),
                            ),
                          )).toList(),
                        ),
                        // Agendamentos Reais
                        ...hours.expand((hour) {
                          final appts = _getAppointmentsForSlot(day, hour);
                          return appts.map((appt) => Positioned(
                            top: (hour - 6) * 80.0 + 4,
                            left: 2,
                            right: 2,
                            child: GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => AppointmentDetailScreen(appointment: appt),
                                  ),
                                ).then((_) => _controller.loadAppointments());
                              },
                              child: Container(
                                height: 72,
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(appt.status).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: _getStatusColor(appt.status).withOpacity(0.3)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      appt.patientName ?? "S/ Paciente",
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: _getStatusColor(appt.status),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const Spacer(),
                                    Text(
                                      appt.professionalName ?? "S/ Prof.",
                                      style: TextStyle(fontSize: 9, color: Colors.grey[700]),
                                      maxLines: 1,
                                    ),
                                    Text(
                                      appt.status,
                                      style: TextStyle(fontSize: 8, fontWeight: FontWeight.w500, color: _getStatusColor(appt.status)),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ));
                        }).toList(),
                      ],
                    ),
                  )).toList(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListView() {
    final list = _controller.appointments;
    if (list.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.3),
          const Center(child: Text("Nenhum agendamento encontrado.")),
        ],
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(8),
      itemCount: list.length,
      itemBuilder: (ctx, i) {
        final appt = list[i];
        final date = appt.dateTime ?? DateTime.now();
        return Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 6),
          child: ListTile(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AppointmentDetailScreen(appointment: appt)),
              ).then((_) => _controller.loadAppointments());
            },
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _getStatusColor(appt.status).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.event, color: _getStatusColor(appt.status)),
            ),
            title: Text(
              DateFormat('dd/MM/yyyy HH:mm - EEEE', 'pt_BR').format(date),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text("Paciente: ${appt.patientName ?? 'N/D'}\nProfissional: ${appt.professionalName ?? 'N/D'}"),
            trailing: Chip(
              label: Text(appt.status, style: const TextStyle(fontSize: 10)),
              backgroundColor: _getStatusColor(appt.status).withOpacity(0.1),
              labelStyle: TextStyle(color: _getStatusColor(appt.status)),
            ),
          ),
        );
      },
    );
  }
}
