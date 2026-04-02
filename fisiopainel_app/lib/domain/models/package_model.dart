import 'audit_fields.dart';

class PackageModel {
  final int? id;
  final int patientId; // 'paciente'
  final int? professionalId; // 'profissional'
  final int serviceTypeId; // 'tipo_atendimento'
  final int quantity; // 'quantidade_total'
  final double totalValue; // 'valor_total'
  final double sessionValue; // 'valor_por_sessao'
  final String status; // 'status'
  final DateTime? paymentDate; // 'data_pagamento'
  
  // Scheduling fields
  final DateTime? startDate; // 'data_inicio'
  final String? weekDays; // 'dias_semana' (Ex: "0,2,4")

  // Campos auxiliares para exibição na lista
  final String? patientName;
  final String? professionalName;
  final String? serviceName;
  final AuditFields? audit;

  PackageModel({
    this.id,
    required this.patientId,
    this.professionalId,
    required this.serviceTypeId,
    required this.quantity,
    required this.totalValue,
    required this.sessionValue,
    this.status = 'ATIVO',
    this.paymentDate,
    this.startDate,
    this.weekDays,
    this.patientName,
    this.professionalName,
    this.serviceName,
    this.audit,
  });
}
