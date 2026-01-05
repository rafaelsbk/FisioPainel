import 'audit_fields.dart';

class PackageModel {
  final int? id;
  final int patientId; // 'paciente'
  final int serviceTypeId; // 'tipo_atendimento'
  final int quantity; // 'quantidade_total'
  final double totalValue; // 'valor_total'
  final double sessionValue; // 'valor_por_sessao'
  final String status; // 'status' (ATIVO, FINALIZADO)
  final DateTime? paymentDate; // 'data_pagamento'

  // Campos auxiliares para exibição na lista (Join no front ou back)
  final String? patientName;
  final String? serviceName;
  final AuditFields? audit;

  PackageModel({
    this.id,
    required this.patientId,
    required this.serviceTypeId,
    required this.quantity,
    required this.totalValue,
    required this.sessionValue,
    this.status = 'ATIVO',
    this.paymentDate,
    this.patientName,
    this.serviceName,
    this.audit,
  });
}
