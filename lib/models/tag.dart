class Tag {
  final String id;
  final String name;
  final String fullPath;
  final int level;

  const Tag({
    required this.id,
    required this.name,
    required this.fullPath,
    required this.level,
  });

  factory Tag.fromJson(Map<String, dynamic> json) {
    return Tag(
      id: json['id'] as String,
      name: json['name'] as String,
      fullPath: json['full_path'] as String,
      level: json['level'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'full_path': fullPath,
      'level': level,
    };
  }
}
