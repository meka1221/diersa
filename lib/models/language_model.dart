class Language {
  final String code;
  final String name;

  Language({required this.code, required this.name});

  factory Language.fromJson(Map<String, dynamic> json) {
    return Language(
      code: json['code'],
      name: json['name'],
    );
  }
}