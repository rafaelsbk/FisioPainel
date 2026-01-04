import 'package:flutter/material.dart';
import '../../data/repositories/appointment_repository.dart';
import '../../domain/models/package_model.dart';
import '../../domain/models/patient_model.dart';
import '../../domain/models/service_type_model.dart';
import '../../data/repositories/package_repository.dart';
import '../../data/repositories/patient_repository.dart';

class PackageController extends ChangeNotifier {
  final PackageRepository _repo = PackageRepository();
  final PatientRepository _patientRepo = PatientRepository();
  final AppointmentRepository _appointmentRepo = AppointmentRepository();

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
      // 1. Cria o pacote e obtém o modelo de retorno com o ID
      await _repo.createPackage(package);

      // 2. (Removido) Criação automática de agendamentos

      // 3. Recarrega a lista de pacotes para exibir o novo
      await _fetchPackages();
      return true;
    } catch (e) {
      error = e.toString();
      // ignore: avoid_print
      print('Erro ao criar pacote: $e'); // Adicionado para depuração
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
}
