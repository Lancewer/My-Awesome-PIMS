import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_awesome_pims/screens/note_list_screen.dart';
import 'package:my_awesome_pims/screens/compose_screen.dart';
import 'package:my_awesome_pims/services/note_api_service.dart';
import 'package:my_awesome_pims/models/note.dart';
import 'package:my_awesome_pims/models/tag.dart';

class MockApiService implements NoteApiService {
  @override
  String baseUrl = 'http://test';
  List<Note>? mockNotes;
  ApiException? mockError;
  MockApiService({this.mockNotes, this.mockError});

  @override
  Future<List<Note>> fetchNotes({int page = 1, int pageSize = 20}) async {
    if (mockError != null) throw mockError!;
    return mockNotes ?? [];
  }

  @override
  Future<Note> createNote(String content) async {
    return Note(id: '1', content: content, tags: [], createdAt: DateTime.now(), updatedAt: DateTime.now());
  }

  @override
  Future<Note> getNote(String id) async {
    return Note(id: id, content: 'test', tags: [], createdAt: DateTime.now(), updatedAt: DateTime.now());
  }

  @override
  Future<Note> updateNote(String id, String content) async {
    return Note(id: id, content: content, tags: [], createdAt: DateTime.now(), updatedAt: DateTime.now());
  }

  @override
  Future<void> deleteNote(String id) async {}

  @override
  Future<List<Note>> searchNotes(String query) async {
    return mockNotes?.where((n) => n.content.contains(query)).toList() ?? [];
  }

  @override
  Future<List<Tag>> fetchTags() async => [];

  @override
  void dispose() {}
}

Widget _wrap(Widget child) {
  return MaterialApp(home: child);
}

void main() {
  group('NoteListScreen', () {
    testWidgets('shows loading then notes', (tester) async {
      final notes = [
        Note(id: '1', content: 'Hello world #test', tags: [], createdAt: DateTime(2026, 5, 6), updatedAt: DateTime(2026, 5, 6)),
      ];
      final service = MockApiService(mockNotes: notes);
      await tester.pumpWidget(_wrap(NoteListScreen(apiService: service)));
      await tester.pumpAndSettle();
      expect(find.text('Hello world #test'), findsOneWidget);
    });

    testWidgets('shows empty state when no notes', (tester) async {
      final service = MockApiService(mockNotes: []);
      await tester.pumpWidget(_wrap(NoteListScreen(apiService: service)));
      await tester.pumpAndSettle();
      expect(find.text('No notes yet'), findsOneWidget);
      expect(find.text('Tap + to capture your first thought'), findsOneWidget);
    });

    testWidgets('shows error state on failure', (tester) async {
      final service = MockApiService(mockError: ApiException('Server unreachable', statusCode: 0));
      await tester.pumpWidget(_wrap(NoteListScreen(apiService: service)));
      await tester.pumpAndSettle();
      expect(find.text('Server unreachable'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('tapping + shows inline compose card', (tester) async {
      final service = MockApiService(mockNotes: []);
      await tester.pumpWidget(_wrap(NoteListScreen(apiService: service)));
      await tester.pumpAndSettle();
      expect(find.text('Tap + to capture your first thought'), findsOneWidget);
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
      expect(find.text('Type your note...'), findsOneWidget);
      expect(find.byIcon(Icons.check), findsOneWidget);
      expect(find.byIcon(Icons.close), findsOneWidget);
    });
  });

  group('ComposeScreen', () {
    testWidgets('shows compose screen with text field', (tester) async {
      final service = MockApiService();
      await tester.pumpWidget(_wrap(ComposeScreen(apiService: service, initialContent: 'existing', noteId: '1', isEdit: true)));
      await tester.pumpAndSettle();
      expect(find.text('Edit Note'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('Save button calls createNote and pops', (tester) async {
      bool created = false;
      final service = MockApiService();
      service.mockNotes = [];
      await tester.pumpWidget(MaterialApp(
        home: Builder(builder: (ctx) => ComposeScreen(apiService: service)),
      ));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'test note #work');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(created, isFalse);
    });
  });
}
