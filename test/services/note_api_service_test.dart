import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:my_awesome_pims/services/note_api_service.dart';

void main() {
  group('NoteApiService', () {
    test('fetchNotes returns list of notes on success', () async {
      final client = MockClient((request) async {
        return http.Response('''
{"notes":[
  {"id":"1","content":"hello #test","tags":[],"created_at":"2026-05-06T10:00:00Z","updated_at":"2026-05-06T10:00:00Z"}
],"total":1,"page":1,"page_size":20}
''', 200);
      });
      final service = NoteApiService(baseUrl: 'http://test', client: client);
      final notes = await service.fetchNotes();
      expect(notes.length, 1);
      expect(notes.first.content, 'hello #test');
    });

    test('fetchNotes throws ApiException on failure', () async {
      final client = MockClient((request) async {
        return http.Response('error', 500);
      });
      final service = NoteApiService(baseUrl: 'http://test', client: client);
      expect(() => service.fetchNotes(), throwsA(isA<ApiException>()));
    });

    test('createNote returns note on 201', () async {
      final client = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.body, '{"content":"new note #tag"}');
        return http.Response('''
{"id":"2","content":"new note #tag","tags":[],"created_at":"2026-05-06T10:00:00Z","updated_at":"2026-05-06T10:00:00Z"}
''', 201);
      });
      final service = NoteApiService(baseUrl: 'http://test', client: client);
      final note = await service.createNote('new note #tag');
      expect(note.id, '2');
      expect(note.content, 'new note #tag');
    });

    test('createNote throws ApiException on 422', () async {
      final client = MockClient((request) async {
        return http.Response('{"detail":"invalid"}', 422);
      });
      final service = NoteApiService(baseUrl: 'http://test', client: client);
      expect(() => service.createNote(''), throwsA(isA<ApiException>()));
    });

    test('getNote returns note on 200', () async {
      final client = MockClient((request) async {
        return http.Response('''
{"id":"1","content":"test","tags":[],"created_at":"2026-05-06T10:00:00Z","updated_at":"2026-05-06T10:00:00Z"}
''', 200);
      });
      final service = NoteApiService(baseUrl: 'http://test', client: client);
      final note = await service.getNote('1');
      expect(note.id, '1');
    });

    test('getNote throws ApiException on 404', () async {
      final client = MockClient((request) async {
        return http.Response('not found', 404);
      });
      final service = NoteApiService(baseUrl: 'http://test', client: client);
      expect(() => service.getNote('999'), throwsA(isA<ApiException>()));
    });

    test('deleteNote succeeds on 200', () async {
      final client = MockClient((request) async {
        expect(request.method, 'DELETE');
        return http.Response('ok', 200);
      });
      final service = NoteApiService(baseUrl: 'http://test', client: client);
      await service.deleteNote('1');
    });

    test('deleteNote throws ApiException on 404', () async {
      final client = MockClient((request) async {
        return http.Response('not found', 404);
      });
      final service = NoteApiService(baseUrl: 'http://test', client: client);
      expect(() => service.deleteNote('999'), throwsA(isA<ApiException>()));
    });

    test('searchNotes returns matching notes', () async {
      final client = MockClient((request) async {
        expect(request.url.path, '/api/v1/search');
        expect(request.url.queryParameters['q'], 'hello');
        return http.Response('''
{"notes":[
  {"id":"1","content":"hello world","tags":[],"created_at":"2026-05-06T10:00:00Z","updated_at":"2026-05-06T10:00:00Z"}
],"total":1}
''', 200);
      });
      final service = NoteApiService(baseUrl: 'http://test', client: client);
      final results = await service.searchNotes('hello');
      expect(results.length, 1);
    });

    test('fetchTags returns tag list', () async {
      final client = MockClient((request) async {
        return http.Response('''
[{"id":"t1","name":"work","full_path":"work","level":1,"note_count":5}]
''', 200);
      });
      final service = NoteApiService(baseUrl: 'http://test', client: client);
      final tags = await service.fetchTags();
      expect(tags.length, 1);
      expect(tags.first.name, 'work');
    });
  });
}
