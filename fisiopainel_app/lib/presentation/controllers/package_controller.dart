import 'package:flutter/material.dart';
import '../widgets/string_utils.dart';
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
  bool isLoadingMore = false;
  bool hasMore = true;
  int currentPage = 1;
  String error = '';

  // Carrega TUDO: Pacotes, Pacientes e Tipos
  Future<void> loadData() async {
    if (isLoading) return; // Evita chamadas duplicadas simultaneas

    isLoading = true;
    error = '';
    currentPage = 1;
    hasMore = true;

    // Limpa dados atuais para garantir consistencia
    packages.clear();
    filteredPackages.clear();
    patientsList.clear();
    professionalsList.clear();
    serviceTypesList.clear();

    notifyListeners();

    try {
      // Carregamento sequencial para facilitar diagnostico de onde trava
      await _fetchInitialPackages();
      await _fetchDependencies();

      filteredPackages = List.from(packages);
    } catch (e) {
      error = "Falha ao carregar dados: ${e.toString()}";
      print("Error in PackageController.loadData: $e");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMore() async {
    if (isLoadingMore || !hasMore || isLoading) return;

    isLoadingMore = true;
    notifyListeners();

    try {
      currentPage++;
      final morePackages = await _repo.getPackages(page: currentPage);
      if (morePackages.isEmpty) {
        hasMore = false;
      } else {
        packages.addAll(morePackages);
        filteredPackages = List.from(packages);
        // Se veio menos que 20, não tem mais páginas
        hasMore = morePackages.length >= 20;
      }
    } catch (e) {
      error = "Erro ao carregar mais: ${e.toString()}";
      currentPage--;
      hasMore = false;
    } finally {
      isLoadingMore = false;
      notifyListeners();
    }
  }

  void filter({String? query, DateTime? start, DateTime? end}) {
    filteredPackages = packages.where((pkg) {
      bool matchesQuery = true;
      bool matchesDate = true;

      if (query != null && query.isNotEmpty) {
        matchesQuery = StringUtils.containsAccentInsensitive(pkg.patientName ?? '', query) ||
            StringUtils.containsAccentInsensitive(pkg.serviceName ?? '', query);
      }

      if (start != null && pkg.startDate != null) {
        matchesDate = pkg.startDate!.isAfter(start) || pkg.startDate!.isAtSameMomentAs(start);
      }
      if (matchesDate && end != null && pkg.startDate != null) {
        final endOfDay = DateTime(end.year, end.month, end.day, 23, 59, 59);
        matchesDate = pkg.startDate!.isBefore(endOfDay);
      }

      return matchesQuery && matchesDate;
    }).toList();
    notifyListeners();
  }

  Future<void> _fetchInitialPackages() async {
    try {
      packages = await _repo.getPackages(page: 1);
      // Se retornou menos que 20, ja sabemos que nao tem mais paginas
      hasMore = packages.length >= 20;
    } catch (e) {
      throw Exception("Pacotes: $e");
    }
  }

  Future<void> _fetchDependencies() async {
    try {
      patientsList = await _patientRepo.getPatients();
    } catch (e) {
      throw Exception("Pacientes: $e");
    }

    try {
      professionalsList = await _professionalRepo.getProfessionals();
    } catch (e) {
      throw Exception("Profissionais: $e");
    }

    try {
      serviceTypesList = await _repo.getServiceTypes();
    } catch (e) {
      throw Exception("Tipos de Serviço: $e");
    }
  }

  Future<bool> createPackage(PackageModel package) async {
    isLoading = true;
    notifyListeners();
    try {
      await _repo.createPackage(package);
      await loadData();
      return true;
    } catch (e) {
      error = e.toString();
      return false;
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
      await loadData();
      return true;
    } catch (e) {
      error = e.toString();
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
