class TokenDto {
  final String access;
  final String refresh;
  final String? role;
  final Map<String, dynamic>? permissions;

  TokenDto({
    required this.access, 
    required this.refresh, 
    this.role,
    this.permissions,
  });

  factory TokenDto.fromJson(Map<String, dynamic> json) {
    return TokenDto(
      access: json['access'],
      refresh: json['refresh'],
      role: json['role'],
      permissions: json['permissions'] as Map<String, dynamic>?,
    );
  }
}
