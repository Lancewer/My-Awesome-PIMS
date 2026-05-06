import 'package:my_awesome_pims/models/tag.dart';

class Note {
  final String id;
  final String content;
  final List<Tag> tags;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Note({
    required this.id,
    required this.content,
    required this.tags,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      id: json['id'] as String,
      content: json['content'] as String,
      tags: (json['tags'] as List<dynamic>)
          .map((t) => Tag.fromJson(t as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'tags': tags.map((t) => t.toJson()).toList(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
