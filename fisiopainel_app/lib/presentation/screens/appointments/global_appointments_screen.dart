import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../../controllers/global_appointment_controller.dart';
import '../../controllers/package_controller.dart';
import '../../../domain/models/appointment_model.dart';
import '../packages/package_form_screen.dart';
import 'appointment_detail_screen.dart';
import '../../widgets/network_error_dialog.dart';

class GlobalAppointmentsScreen extends StatefulWidget {
  const GlobalAppointmentsScreen({super.key});

  @override
  State<GlobalAppointmentsScreen> createState() => _GlobalAppointmentsScreenState();
}

class _GlobalAppointmentsScreenState extends State<GlobalAppointmentsScreen> {
  final GlobalAppointmentController _controller = GlobalAppointmentController();
  final PackageController _packageController = PackageController();
  bool _isListView = false;
  DateTime _focusedDate = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  bool _localeInitialized = false;

  @override
  void initState() {
    super.initState();
    _initLocale();
    _controller.addListener(_onControllerChange);
    _controller.loadAppointments();
    _packageController.loadData();
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

  // --- NAVEGAÇÃO ---
  void _previousWeek() {
    setState(() {
      _focusedDate = _focusedDate.subtract(const Duration(days: 7));
      _selectedDay = _selectedDay.subtract(const Duration(days: 7));
    });
  }

  void _nextWeek() {
    setState(() {
      _focusedDate = _focusedDate.add(const Duration(days: 7));
      _selectedDay = _selectedDay.add(const Duration(days: 7));
    });
  }

  void _today() {
    setState(() {
      _focusedDate = DateTime.now();
      _selectedDay = DateTime.now();
    });
  }

  void _createPackageForSlot(DateTime day, int hour) {
    showDialog(
      context: context,
      builder: (context) => PackageFormScreen(
        controller: _packageController,
        initialStartDate: day,
        initialTime: TimeOfDay(hour: hour, minute: 0),
      ),
    ).then((success) {
      if (success == true) {
        _controller.loadAppointments();
      }
    });
  }

  void _updateAppointmentDateTime(AppointmentModel appt, DateTime newDate, int? newHour) {
    final originalDateTime = appt.dateTime ?? DateTime.now();
    final hour = newHour ?? originalDateTime.hour;
    final minute = originalDateTime.minute;
    
    final newDateTime = DateTime(newDate.year, newDate.month, newDate.day, hour, minute);
    
    _controller.updateAppointmentDateTime(appt, newDateTime).then((success) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Agendamento atualizado com sucesso"),
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });
  }

  // --- CÁLCULO DE DIAS ---
  DateTime _getStartOfWeek(DateTime date) {
    return date.subtract(Duration(days: date.weekday - 1));
  }

  List<DateTime> _getWeekDays() {
    final start = _getStartOfWeek(_focusedDate);
    return List.generate(7, (i) => DateTime(start.year, start.month, start.day + i));
  }

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
          const SizedBox(height: 12),
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
    final monthName = DateFormat('MMMM yyyy', 'pt_BR').format(_focusedDate);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    monthName.toUpperCase(),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                  ),
                  const Text("Agenda de Atendimentos", style: TextStyle(color: Colors.grey, fontSize: 13)),
                ],
              ),
              Row(
                children: [
                  DragTarget<AppointmentModel>(
                    onWillAccept: (data) => true,
                    onAccept: (appt) {
                      _previousWeek();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Semana anterior. Solte o card no novo dia/horário.")),
                      );
                    },
                    builder: (context, candidateData, rejectedData) => IconButton(
                      onPressed: _previousWeek, 
                      icon: const Icon(Icons.chevron_left),
                      style: IconButton.styleFrom(
                        backgroundColor: candidateData.isNotEmpty ? Colors.blue[200] : Colors.grey[100],
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  DragTarget<AppointmentModel>(
                    onWillAccept: (data) => true,
                    onAccept: (appt) {
                      _nextWeek();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Próxima semana. Solte o card no novo dia/horário.")),
                      );
                    },
                    builder: (context, candidateData, rejectedData) => IconButton(
                      onPressed: _nextWeek, 
                      icon: const Icon(Icons.chevron_right),
                      style: IconButton.styleFrom(
                        backgroundColor: candidateData.isNotEmpty ? Colors.blue[200] : Colors.grey[100],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _getWeekDays().map((day) => _buildDayItem(day)).toList(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _buildViewToggle(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDayItem(DateTime day) {
    final isSelected = day.day == _selectedDay.day && day.month == _selectedDay.month;
    final isToday = day.day == DateTime.now().day && day.month == DateTime.now().month;

    return DragTarget<AppointmentModel>(
      onWillAccept: (data) => true,
      onAccept: (appt) => _updateAppointmentDateTime(appt, day, null),
      builder: (context, candidateData, rejectedData) {
        final isOver = candidateData.isNotEmpty;
        return GestureDetector(
          onTap: () => setState(() => _selectedDay = day),
          child: Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isOver ? Colors.blue[300] : (isSelected ? Colors.blue : (isToday ? Colors.blue[50] : Colors.grey[50])),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isOver ? Colors.blue[800]! : (isSelected ? Colors.blue : (isToday ? Colors.blue[200]! : Colors.transparent))),
            ),
            child: Column(
              children: [
                Text(
                  DateFormat('EEE', 'pt_BR').format(day).toUpperCase(),
                  style: TextStyle(
                    fontSize: 10, 
                    fontWeight: FontWeight.bold, 
                    color: (isSelected || isOver) ? Colors.white70 : Colors.grey[600]
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  day.day.toString(),
                  style: TextStyle(
                    fontSize: 16, 
                    fontWeight: FontWeight.bold, 
                    color: (isSelected || isOver) ? Colors.white : Colors.black87
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildViewToggle() {
    return Container(
      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _toggleIcon(Icons.calendar_view_week, !_isListView, () => setState(() => _isListView = false)),
          _toggleIcon(Icons.list, _isListView, () => setState(() => _isListView = true)),
        ],
      ),
    );
  }

  Widget _toggleIcon(IconData icon, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: active ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: active ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)] : [],
        ),
        child: Icon(icon, size: 20, color: active ? Colors.blue : Colors.grey),
      ),
    );
  }

  Widget _buildCalendarView() {
    final hours = List.generate(15, (i) => i + 6); // 06:00 - 20:00

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: hours.length,
      itemBuilder: (context, index) {
        final hour = hours[index];
        final appts = _getAppointmentsForSlot(_selectedDay, hour);
        return _buildHourRow(hour, appts);
      },
    );
  }

  Widget _buildHourRow(int hour, List<AppointmentModel> appts) {
    return DragTarget<AppointmentModel>(
      onWillAccept: (data) => true,
      onAccept: (appt) => _updateAppointmentDateTime(appt, _selectedDay, hour),
      builder: (context, candidateData, rejectedData) {
        final isOver = candidateData.isNotEmpty;
        return Container(
          padding: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: isOver ? Colors.blue.withOpacity(0.05) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 55,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isOver ? Colors.blue[800] : Colors.blue[600],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    "${hour.toString().padLeft(2, '0')}:00",
                    style: const TextStyle(
                      color: Colors.white, 
                      fontWeight: FontWeight.bold,
                      fontSize: 12
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (appts.isEmpty)
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _createPackageForSlot(_selectedDay, hour),
                          child: Container(
                            height: 40,
                            decoration: BoxDecoration(
                              border: Border.all(color: isOver ? Colors.blue[300]! : Colors.grey[200]!),
                              borderRadius: BorderRadius.circular(12),
                              color: isOver ? Colors.blue[50] : Colors.white.withOpacity(0.5),
                            ),
                            child: Center(child: Icon(Icons.add, color: isOver ? Colors.blue : Colors.grey, size: 20)),
                          ),
                        ),
                      )
                    else ...[
                      ...appts.map((appt) => Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _buildAppointmentCard(appt),
                        ),
                      )).toList(),
                      GestureDetector(
                        onTap: () => _createPackageForSlot(_selectedDay, hour),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[200]!),
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.white.withOpacity(0.5),
                          ),
                          child: const Center(child: Icon(Icons.add, color: Colors.grey, size: 20)),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAppointmentCard(AppointmentModel appt) {
    final statusColor = _getStatusColor(appt.status);
    final serviceColor = appt.serviceColor != null 
        ? Color(int.parse(appt.serviceColor!.replaceFirst('#', '0xFF'))) 
        : statusColor;

    final card = Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: serviceColor.withOpacity(0.4), width: 1.5),
        boxShadow: [BoxShadow(color: serviceColor.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 6,
                height: 24,
                decoration: BoxDecoration(color: serviceColor, borderRadius: BorderRadius.circular(3)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  appt.patientName ?? "S/ Paciente",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            appt.professionalName ?? "S/ Prof.",
            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              appt.status,
              style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: statusColor),
            ),
          ),
        ],
      ),
    );

    if (kIsWeb) {
      return Draggable<AppointmentModel>(
        data: appt,
        feedback: Material(
          color: Colors.transparent,
          child: SizedBox(
            width: 200,
            child: card,
          ),
        ),
        childWhenDragging: Opacity(
          opacity: 0.3,
          child: card,
        ),
        child: GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => AppointmentDetailScreen(appointment: appt)),
            ).then((_) => _controller.loadAppointments());
          },
          child: card,
        ),
      );
    }

    return LongPressDraggable<AppointmentModel>(
      data: appt,
      feedback: Material(
        color: Colors.transparent,
        child: SizedBox(
          width: 200,
          child: card,
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: card,
      ),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AppointmentDetailScreen(appointment: appt)),
          ).then((_) => _controller.loadAppointments());
        },
        child: card,
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
