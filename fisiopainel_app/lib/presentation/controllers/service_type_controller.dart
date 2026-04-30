import 'package:flutter/material.dart';
import '../../data/repositories/service_type_repository.dart';
import '../../domain/models/service_type_model.dart';

class ServiceTypeController extends ChangeNotifier {
  final ServiceTypeRepository _repo = ServiceTypeRepository();
  List<ServiceTypeModel> list = [];
  bool isLoading = false;
  String error = '';

  Future<void> loadData() async {
    isLoading = true;
    notifyListeners();
    try {
      list = await _repo.getServiceTypes();
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> create(String name, String color) async {
    isLoading = true;
    notifyListeners();
    try {
      await _repo.createServiceType(name, color);
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

  Future<bool> update(int id, String name, String color, bool isActive) async {
    isLoading = true;
    notifyListeners();
    try {
      await _repo.updateServiceType(id, name, color, isActive);
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

  Future<bool> delete(int id) async {
    isLoading = true;
    notifyListeners();
    try {
      await _repo.deleteServiceType(id);
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
}
