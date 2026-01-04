class TokenDto {
  final String access;
  final String refresh;

  TokenDto({required this.access, required this.refresh});

  factory TokenDto.fromJson(Map<String, dynamic> json) {
    return TokenDto(access: json['access'], refresh: json['refresh']);
  }
}
