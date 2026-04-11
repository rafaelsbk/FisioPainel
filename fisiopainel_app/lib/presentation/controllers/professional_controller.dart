import 'package:flutter/material.dart';
import '../../domain/models/professional_model.dart';
import '../../data/repositories/professional_repository.dart';
import '../../domain/models/user_role_model.dart';
import '../../data/repositories/user_role_repository.dart';

class ProfessionalController extends ChangeNotifier {
  final ProfessionalRepository repository = ProfessionalRepository();
  final UserRoleRepository _userRoleRepository = UserRoleRepository();

  // Lista "Original" (Backup de tudo que veio da API)
  List<ProfessionalModel> _allProfessionals = [];
  List<ProfessionalModel> get allProfessionals => _allProfessionals;

  // Lista "Exibida" (O que aparece na tela, podendo ser filtrada)
  List<ProfessionalModel> filteredProfessionals = [];

  bool isLoading = false;
  String error = '';

  Future<List<UserRoleModel>> getUserRoles() async {
    try {
      return await _userRoleRepository.getUserRoles();
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return [];
    }
  }

  // Carregar da API
  Future<void> fetchProfessionals() async {
    isLoading = true;
    error = '';
    notifyListeners();

    try {
      _allProfessionals = await repository.getProfessionals();

      // Ordena por nome
      _allProfessionals.sort((a, b) => a.firstName.compareTo(b.firstName));

      // Inicialmente, a lista filtrada é igual à completa
      filteredProfessionals = List.from(_allProfessionals);
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // Lógica de Filtro Inteligente
  void filter(String query) {
    if (query.isEmpty) {
      // Se a busca estiver vazia, restaura a lista completa
      filteredProfessionals = List.from(_allProfessionals);
    } else {
      final lowerQuery = query.toLowerCase();
      filteredProfessionals = _allProfessionals.where((prof) {
        // Busca por Nome, Username, CPF, Email ou Crefito
        return prof.fullName.toLowerCase().contains(lowerQuery) ||
            prof.username.toLowerCase().contains(lowerQuery) ||
            prof.cpf.contains(query) ||
            prof.crefito.toLowerCase().contains(lowerQuery) ||
            prof.email.toLowerCase().contains(lowerQuery);
      }).toList();
    }
    notifyListeners(); // Avisa a tela para redesenhar
  }

  // Salvar (Cria ou Edita)
  Future<bool> saveProfessional(ProfessionalModel professional) async {
    isLoading = true;
    notifyListeners();
    try {
      if (professional.id == null) {
        await repository.createProfessional(professional);
      } else {
        await repository.updateProfessional(professional);
      }
      await fetchProfessionals(); // Recarrega tudo e limpa o filtro
      return true;
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Bloquear ou Desbloquear
  Future<bool> toggleProfessionalStatus(ProfessionalModel professional) async {
    if (professional.id == null) return false;

    isLoading = true;
    notifyListeners();

    try {
      // Inverte o status atual (Se era true, vira false)
      final newStatus = !professional.isActive;

      await repository.toggleStatus(professional.id!, newStatus);
      await fetchProfessionals(); // Recarrega a lista para ver a mudança visual
      return true;
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
