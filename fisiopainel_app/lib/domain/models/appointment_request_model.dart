import 'appointment_model.dart';

class AppointmentRequestModel {
  final int id;
  final int solicitanteId;
  final String solicitanteName;
  final int profissionalSolicitadoId;
  final String profissionalSolicitadoName;
  final int agendamentoId;
  final AppointmentModel? agendamentoDetalhes;
  final String status;
  final String? message;
  final DateTime dataCriacao;

  AppointmentRequestModel({
    required this.id,
    required this.solicitanteId,
    required this.solicitanteName,
    required this.profissionalSolicitadoId,
    required this.profissionalSolicitadoName,
    required this.agendamentoId,
    this.agendamentoDetalhes,
    required this.status,
    this.message,
    required this.dataCriacao,
  });
}
