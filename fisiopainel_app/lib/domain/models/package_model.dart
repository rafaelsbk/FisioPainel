import 'audit_fields.dart';

class PackageModel {
  final int? id;
  final int patientId; // 'paciente'
  final int? professionalId; // 'profissional'
  final int serviceTypeId; // 'tipo_atendimento'
  final int quantity; // 'quantidade_total'
  final double totalValue; // 'valor_total'
  final double sessionValue; // 'valor_por_sessao'
  final double paidValue; // 'valor_pago'
  final String status; // 'status'
  final DateTime? paymentDate; // 'data_pagamento'
  final DateTime? startDate; // 'data_inicio'
  final String? weekDays; // 'dias_semana' (Ex: "0,2,4")
  final int? renovatedFrom; // 'renovado_de'

  // Campos auxiliares para exibição na lista
  final String? patientName;
  final String? professionalName;
  final String? serviceName;
  final AuditFields? audit;

  double get pendingValue => totalValue - paidValue;

  PackageModel({
    this.id,
    required this.patientId,
    this.professionalId,
    required this.serviceTypeId,
    required this.quantity,
    required this.totalValue,
    required this.sessionValue,
    this.paidValue = 0,
    this.status = 'ATIVO',
    this.paymentDate,
    this.startDate,
    this.weekDays,
    this.renovatedFrom,
    this.patientName,
    this.professionalName,
    this.serviceName,
    this.audit,
  });
}
