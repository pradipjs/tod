/// Language model for supported app languages.
class Language {
  final String code;
  final String name;
  final String nativeName;
  final String icon;

  const Language({
    required this.code,
    required this.name,
    required this.nativeName,
    required this.icon,
  });

  factory Language.fromJson(Map<String, dynamic> json) {
    return Language(
      code: json['code'] as String,
      name: json['name'] as String,
      nativeName: json['native_name'] as String,
      icon: json['icon'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'name': name,
      'native_name': nativeName,
      'icon': icon,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Language &&
          runtimeType == other.runtimeType &&
          code == other.code;

  @override
  int get hashCode => code.hashCode;

  @override
  String toString() => 'Language($code, $name)';
}
