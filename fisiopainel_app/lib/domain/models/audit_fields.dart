class AuditFields {
  final String? criadoPorNome;
  final DateTime? dataCriacao;
  final String? editadoPorNome;
  final DateTime? dataUltimaEdicao;

  AuditFields({
    this.criadoPorNome,
    this.dataCriacao,
    this.editadoPorNome,
    this.dataUltimaEdicao,
  });

  factory AuditFields.fromJson(Map<String, dynamic> json) {
    return AuditFields(
      criadoPorNome: json['criado_por_nome'],
      dataCriacao: (json['data_criacao'] != null && json['data_criacao'].toString().isNotEmpty) 
          ? DateTime.parse(json['data_criacao'].toString()) 
          : null,
      editadoPorNome: json['editado_por_nome'],
      dataUltimaEdicao: (json['data_ultima_edicao'] != null && json['data_ultima_edicao'].toString().isNotEmpty) 
          ? DateTime.parse(json['data_ultima_edicao'].toString()) 
          : null,
    );
  }

}