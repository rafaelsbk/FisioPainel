import '../../domain/models/appointment_request_model.dart';
import 'appointment_dto.dart';

class AppointmentRequestDto {
  static AppointmentRequestModel fromJson(Map<String, dynamic> json) {
    return AppointmentRequestModel(
      id: json['id'],
      solicitanteId: json['solicitante'],
      solicitanteName: json['solicitante_nome'],
      profissionalSolicitadoId: json['profissional_solicitado'],
      profissionalSolicitadoName: json['profissional_solicitado_nome'],
      agendamentoId: json['agendamento'],
      agendamentoDetalhes: json['agendamento_detalhes'] != null 
          ? AppointmentDto.fromJson(json['agendamento_detalhes']) 
          : null,
      status: json['status'],
      message: json['mensagem'],
      dataCriacao: DateTime.parse(json['data_criacao']),
    );
  }

  static Map<String, dynamic> toJson(AppointmentRequestModel model) {
    return {
      "profissional_solicitado": model.profissionalSolicitadoId,
      "agendamento": model.agendamentoId,
      "mensagem": model.message,
    };
  }
}
