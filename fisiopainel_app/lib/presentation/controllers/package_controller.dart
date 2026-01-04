import 'package:flutter/material.dart';
import '../../domain/models/package_model.dart';
import '../../domain/models/patient_model.dart';
import '../../domain/models/service_type_model.dart';
import '../../data/repositories/package_resitory.dart';
import '../../data/repositories/patient_repository.dart';

class PackageController extends ChangeNotifier {
  final PackageRepository _repo = PackageRepository();
  final PatientRepository _patientRepo = PatientRepository();

  List<PackageModel> packages = [];
  List<PatientModel> patientsList = [];
  List<ServiceTypeModel> serviceTypesList = [];

  bool isLoading = false;
  String error = '';

  // Carrega TUDO: Pacotes, Pacientes e Tipos
  Future<void> loadData() async {
    isLoading = true;
    notifyListeners();

    try {
      await Future.wait([_fetchPackages(), _fetchDependencies()]);
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _fetchPackages() async {
    packages = await _repo.getPackages();
  }

  Future<void> _fetchDependencies() async {
    // Reutiliza o repositório de pacientes que já criamos
    patientsList = await _patientRepo.getPatients();
    serviceTypesList = await _repo.getServiceTypes();
  }

  Future<bool> createPackage(PackageModel package) async {
    isLoading = true;
    notifyListeners();
    try {
      await _repo.createPackage(package);
      await _fetchPackages();
      return true;
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
