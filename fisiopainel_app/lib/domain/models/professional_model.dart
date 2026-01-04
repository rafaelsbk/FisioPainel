class ProfessionalModel {
  final int? id;
  final String username;
  final String? password; // Usado apenas na criação
  final String firstName;
  final String lastName;
  final String email;
  final String phoneNumber; // Mapeia para telepone_number
  final String cpf;
  final String crefito;
  final double? percentualRepasse;
  final double? valorRepasseFixo;
  final bool isActive;

  ProfessionalModel({
    this.id,
    required this.username,
    this.password,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phoneNumber,
    required this.cpf,
    required this.crefito,
    this.percentualRepasse,
    this.valorRepasseFixo,
    this.isActive = true,
  });

  // Getter auxiliar para exibir nome completo
  String get fullName => "$firstName $lastName";
}
