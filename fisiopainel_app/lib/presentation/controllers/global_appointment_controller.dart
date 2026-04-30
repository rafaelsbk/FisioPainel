import 'package:flutter/material.dart';
import '../../data/repositories/appointment_repository.dart';
import '../../domain/models/appointment_model.dart';

class GlobalAppointmentController extends ChangeNotifier {
  final AppointmentRepository _repo = AppointmentRepository();
  List<AppointmentModel> appointments = [];
  bool isLoading = false;
  String error = '';

  Future<void> loadAppointments() async {
    isLoading = true;
    notifyListeners();
    try {
      appointments = await _repo.getAllAppointments();
      // Ordena por data (mais recente primeiro, ou futuro primeiro)
      appointments.sort((a, b) {
        if (a.dateTime == null) return 1;
        if (b.dateTime == null) return -1;
        return a.dateTime!.compareTo(b.dateTime!);
      });
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateAppointmentDateTime(AppointmentModel appt, DateTime newDateTime) async {
    try {
      final updatedAppt = AppointmentModel(
        id: appt.id,
        packageId: appt.packageId,
        dateTime: newDateTime,
        status: appt.status,
        professionalId: appt.professionalId,
      );
      
      await _repo.updateAppointment(updatedAppt);
      
      // Atualiza localmente para feedback imediato
      final index = appointments.indexWhere((a) => a.id == appt.id);
      if (index != -1) {
        appointments[index] = AppointmentModel(
          id: appt.id,
          packageId: appt.packageId,
          dateTime: newDateTime,
          status: appt.status,
          professionalId: appt.professionalId,
          professionalName: appt.professionalName,
          patientName: appt.patientName,
          sessionProgress: appt.sessionProgress,
          packageTotalValue: appt.packageTotalValue,
        );
        notifyListeners();
      }
      return true;
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
