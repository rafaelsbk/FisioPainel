class TokenDto {
  final String access;
  final String refresh;
  final String? role;

  TokenDto({required this.access, required this.refresh, this.role});

  factory TokenDto.fromJson(Map<String, dynamic> json) {
    return TokenDto(
      access: json['access'],
      refresh: json['refresh'],
      role: json['role'],
    );
  }
}
