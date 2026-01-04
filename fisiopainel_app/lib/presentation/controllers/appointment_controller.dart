import 'package:flutter/material.dart';
import '../../data/repositories/appointment_repository.dart';
import '../../data/repositories/professional_repository.dart';
import '../../domain/models/appointment_model.dart';
import '../../domain/models/professional_model.dart';

class AppointmentController extends ChangeNotifier {
  final AppointmentRepository _repo = AppointmentRepository();
  final ProfessionalRepository _profRepo = ProfessionalRepository();

  List<ProfessionalModel> professionalsList = [];
  bool isLoading = false;
  String error = '';

  Future<void> loadDependencies() async {
    isLoading = true;
    notifyListeners();
    try {
      professionalsList = await _profRepo.getProfessionals();
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createAppointment(AppointmentModel appointment) async {
    isLoading = true;
    notifyListeners();
    try {
      await _repo.createAppointment(appointment);
      return true;
    } catch (e) {
      error = e.toString();
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateAppointment(AppointmentModel appointment) async {
    isLoading = true;
    notifyListeners();
    try {
      await _repo.updateAppointment(appointment);
      return true;
    } catch (e) {
      error = e.toString();
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
