import 'package:flutter_test/flutter_test.dart';
import 'package:my_awesome_pims/models/tag.dart';
import 'package:my_awesome_pims/models/note.dart';

void main() {
  group('Tag', () {
    test('fromJson parses correctly', () {
      final json = {
        'id': 'tag-1',
        'name': 'work',
        'full_path': 'project/work',
        'level': 2,
      };
      final tag = Tag.fromJson(json);
      expect(tag.id, 'tag-1');
      expect(tag.name, 'work');
      expect(tag.fullPath, 'project/work');
      expect(tag.level, 2);
    });

    test('toJson serializes correctly', () {
      final tag = const Tag(id: 't1', name: 'dev', fullPath: 'dev', level: 1);
      final json = tag.toJson();
      expect(json['id'], 't1');
      expect(json['name'], 'dev');
      expect(json['full_path'], 'dev');
      expect(json['level'], 1);
    });
  });

  group('Note', () {
    test('fromJson parses correctly with tags', () {
      final json = {
        'id': 'note-1',
        'content': 'Test note #work',
        'tags': [
          {'id': 'tag-1', 'name': 'work', 'full_path': 'work', 'level': 1},
        ],
        'created_at': '2026-05-06T10:00:00Z',
        'updated_at': '2026-05-06T10:05:00Z',
      };
      final note = Note.fromJson(json);
      expect(note.id, 'note-1');
      expect(note.content, 'Test note #work');
      expect(note.tags.length, 1);
      expect(note.tags.first.name, 'work');
      expect(note.createdAt, DateTime.utc(2026, 5, 6, 10, 0, 0));
      expect(note.updatedAt, DateTime.utc(2026, 5, 6, 10, 5, 0));
    });

    test('fromJson parses empty tags', () {
      final json = {
        'id': 'note-2',
        'content': 'No tags here',
        'tags': [],
        'created_at': '2026-05-06T10:00:00Z',
        'updated_at': '2026-05-06T10:00:00Z',
      };
      final note = Note.fromJson(json);
      expect(note.tags.isEmpty, true);
    });

    test('toJson serializes correctly', () {
      final note = Note(
        id: 'n1',
        content: 'Hello #test',
        tags: const [Tag(id: 't1', name: 'test', fullPath: 'test', level: 1)],
        createdAt: DateTime.utc(2026, 5, 6, 10, 0, 0),
        updatedAt: DateTime.utc(2026, 5, 6, 10, 5, 0),
      );
      final json = note.toJson();
      expect(json['id'], 'n1');
      expect(json['content'], 'Hello #test');
      expect(json['tags'].length, 1);
      expect(json['tags'][0]['name'], 'test');
    });
  });
}
