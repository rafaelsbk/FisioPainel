import 'package:flutter/material.dart';
import '../../data/repositories/appointment_repository.dart';
import '../../domain/models/package_model.dart';
import '../../domain/models/patient_model.dart';
import '../../domain/models/professional_model.dart';
import '../../domain/models/service_type_model.dart';
import '../../data/repositories/package_repository.dart';
import '../../data/repositories/patient_repository.dart';
import '../../data/repositories/professional_repository.dart';

class PackageController extends ChangeNotifier {
  final PackageRepository _repo = PackageRepository();
  final PatientRepository _patientRepo = PatientRepository();
  final ProfessionalRepository _professionalRepo = ProfessionalRepository();
  final AppointmentRepository _appointmentRepo = AppointmentRepository();

  List<PackageModel> packages = [];
  List<PackageModel> filteredPackages = [];
  List<PatientModel> patientsList = [];
  List<ProfessionalModel> professionalsList = [];
  List<ServiceTypeModel> serviceTypesList = [];

  bool isLoading = false;
  String error = '';

  // Carrega TUDO: Pacotes, Pacientes e Tipos
  Future<void> loadData() async {
    isLoading = true;
    notifyListeners();

    try {
      await Future.wait([_fetchPackages(), _fetchDependencies()]);
      filteredPackages = List.from(packages);
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void filter({String? query, DateTime? start, DateTime? end}) {
    filteredPackages = packages.where((pkg) {
      bool matchesQuery = true;
      bool matchesDate = true;

      if (query != null && query.isNotEmpty) {
        final q = query.toLowerCase();
        final pName = (pkg.patientName ?? '').toLowerCase();
        final sName = (pkg.serviceName ?? '').toLowerCase();
        matchesQuery = pName.contains(q) || sName.contains(q);
      }

      if (start != null && pkg.startDate != null) {
        matchesDate = pkg.startDate!.isAfter(start) || pkg.startDate!.isAtSameMomentAs(start);
      }
      if (matchesDate && end != null && pkg.startDate != null) {
        // Para incluir o dia final completo
        final endOfDay = DateTime(end.year, end.month, end.day, 23, 59, 59);
        matchesDate = pkg.startDate!.isBefore(endOfDay);
      }

      return matchesQuery && matchesDate;
    }).toList();
    notifyListeners();
  }

  Future<void> _fetchPackages() async {
    packages = await _repo.getPackages();
  }

  Future<void> _fetchDependencies() async {
    // Reutiliza o repositório de pacientes que já criamos
    patientsList = await _patientRepo.getPatients();
    professionalsList = await _professionalRepo.getProfessionals();
    serviceTypesList = await _repo.getServiceTypes();
  }

  Future<bool> createPackage(PackageModel package) async {
    isLoading = true;
    notifyListeners();
    try {
      // 1. Cria o pacote e obtém o modelo de retorno com o ID
      await _repo.createPackage(package);

      // 2. (Removido) Criação automática de agendamentos

      // 3. Recarrega a lista de pacotes para exibir o novo
      await _fetchPackages();
      return true;
    } catch (e) {
      error = e.toString();
      return false; // O finally vai cuidar do notifyListeners e isLoading
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updatePackage(PackageModel package) async {
    isLoading = true;
    notifyListeners();
    try {
      await _repo.updatePackage(package);
      await _fetchPackages(); // Recarrega a lista
      return true;
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deletePackage(int id) async {
    isLoading = true;
    notifyListeners();
    try {
      await _repo.deletePackage(id);
      // Remove localmente para sumir instantaneamente da tela
      packages.removeWhere((p) => p.id == id);
      filteredPackages.removeWhere((p) => p.id == id);
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
