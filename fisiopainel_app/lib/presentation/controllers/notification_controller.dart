import 'package:flutter/material.dart';
import '../../data/repositories/appointment_request_repository.dart';

class NotificationController extends ChangeNotifier {
  static final NotificationController _instance = NotificationController._internal();
  factory NotificationController() => _instance;
  NotificationController._internal();

  final _repo = AppointmentRequestRepository();
  int unreadCount = 0;

  Future<void> fetchCount() async {
    try {
      final count = await _repo.getUnreadCount();
      if (count != unreadCount) {
        unreadCount = count;
        notifyListeners();
      }
    } catch (e) {
      print("Erro ao buscar contagem de notificações: $e");
    }
  }

  Future<void> markAsRead() async {
    try {
      await _repo.markAsRead();
      unreadCount = 0;
      notifyListeners();
    } catch (e) {
       print("Erro ao marcar notificações como lidas: $e");
    }
  }
}
