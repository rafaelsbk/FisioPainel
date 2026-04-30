import 'package:flutter/material.dart';
import '../widgets/string_utils.dart';
import '../../domain/models/patient_model.dart';
import '../../data/repositories/patient_repository.dart';

class PatientController extends ChangeNotifier {
  final PatientRepository repository = PatientRepository();

  List<PatientModel> _allPatients = [];
  List<PatientModel> get allPatients => _allPatients;
  List<PatientModel> filteredPatients = [];
  bool isLoading = false;
  String error = '';

  // Carregar da API
  Future<void> fetchPatients() async {
    isLoading = true;
    error = '';
    notifyListeners();

    try {
      _allPatients = await repository.getPatients();
      // Ordena
      _allPatients.sort((a, b) => a.completeName.compareTo(b.completeName));
      filteredPatients = List.from(_allPatients);
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // Filtrar (Mantido igual, ajustado para novos campos)
  void filter(String query) {
    if (query.isEmpty) {
      filteredPatients = List.from(_allPatients);
    } else {
      filteredPatients = _allPatients.where((p) {
        return StringUtils.containsAccentInsensitive(p.completeName, query) ||
            (p.cpf != null && p.cpf!.contains(query)) ||
            (p.email != null &&
                StringUtils.containsAccentInsensitive(p.email!, query));
      }).toList();
    }
    notifyListeners();
  }

  // Salvar (Decide se Cria ou Edita)
  Future<bool> savePatient(PatientModel patient) async {
    isLoading = true;
    notifyListeners();
    try {
      if (patient.id == null) {
        await repository.createPatient(patient);
      } else {
        await repository.updatePatient(patient);
      }
      await fetchPatients(); // Recarrega a lista
      return true;
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
