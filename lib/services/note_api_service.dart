import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:my_awesome_pims/models/note.dart';
import 'package:my_awesome_pims/models/tag.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException(this.message, {this.statusCode});
}

class NoteApiService {
  final String baseUrl;
  final http.Client _client;

  NoteApiService({required this.baseUrl, http.Client? client})
      : _client = client ?? http.Client();

  // Timeout + retry configuration
  static const Duration _timeout = Duration(seconds: 10);
  static const int _maxRetries = 1;

  Future<T> _withRetry<T>(Future<T> Function() operation) async {
    int attempts = 0;
    while (true) {
      try {
        return await operation().timeout(_timeout);
      } on TimeoutException {
        attempts++;
        if (attempts > _maxRetries) {
          throw ApiException('Request timed out. Server may be unreachable.', statusCode: 0);
        }
        await Future.delayed(Duration(milliseconds: 500 * attempts));
      } on http.ClientException {
        attempts++;
        if (attempts > _maxRetries) {
          throw ApiException('Connection failed. Please check your network.', statusCode: 0);
        }
        await Future.delayed(Duration(milliseconds: 500 * attempts));
      }
    }
  }

  Future<List<Note>> fetchNotes({int page = 1, int pageSize = 20}) {
    return _withRetry(() async {
      final response = await _client.get(
        Uri.parse('$baseUrl/api/v1/notes?page=$page&page_size=$pageSize'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final notes = (data['notes'] as List<dynamic>)
            .map((n) => Note.fromJson(n as Map<String, dynamic>))
            .toList();
        return notes;
      }
      throw ApiException('Failed to load notes', statusCode: response.statusCode);
    });
  }

  Future<Note> createNote(String content) {
    return _withRetry(() async {
      final response = await _client.post(
        Uri.parse('$baseUrl/api/v1/notes'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'content': content}),
      );
      if (response.statusCode == 201) {
        return Note.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
      }
      if (response.statusCode == 422) {
        throw ApiException('Content is invalid', statusCode: 422);
      }
      throw ApiException('Failed to create note', statusCode: response.statusCode);
    });
  }

  Future<Note> getNote(String id) {
    return _withRetry(() async {
      final response = await _client.get(
        Uri.parse('$baseUrl/api/v1/notes/$id'),
      );
      if (response.statusCode == 200) {
        return Note.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
      }
      if (response.statusCode == 404) {
        throw ApiException('Note not found', statusCode: 404);
      }
      throw ApiException('Failed to load note', statusCode: response.statusCode);
    });
  }

  Future<Note> updateNote(String id, String content) {
    return _withRetry(() async {
      final response = await _client.put(
        Uri.parse('$baseUrl/api/v1/notes/$id'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'content': content}),
      );
      if (response.statusCode == 200) {
        return Note.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
      }
      if (response.statusCode == 404) {
        throw ApiException('Note no longer exists', statusCode: 404);
      }
      throw ApiException('Failed to update note', statusCode: response.statusCode);
    });
  }

  Future<void> deleteNote(String id) {
    return _withRetry(() async {
      final response = await _client.delete(
        Uri.parse('$baseUrl/api/v1/notes/$id'),
      );
      if (response.statusCode == 200) {
        return;
      }
      if (response.statusCode == 404) {
        throw ApiException('Note not found', statusCode: 404);
      }
      throw ApiException('Failed to delete note', statusCode: response.statusCode);
    });
  }

  Future<List<Note>> searchNotes(String query) {
    return _withRetry(() async {
      final response = await _client.get(
        Uri.parse('$baseUrl/api/v1/search?q=${Uri.encodeComponent(query)}'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return (data['notes'] as List<dynamic>)
            .map((n) => Note.fromJson(n as Map<String, dynamic>))
            .toList();
      }
      throw ApiException('Search failed', statusCode: response.statusCode);
    });
  }

  Future<List<Tag>> fetchTags() {
    return _withRetry(() async {
      final response = await _client.get(
        Uri.parse('$baseUrl/api/v1/tags'),
      );
      if (response.statusCode == 200) {
        return (jsonDecode(response.body) as List<dynamic>)
            .map((t) => Tag.fromJson(t as Map<String, dynamic>))
            .toList();
      }
      throw ApiException('Failed to load tags', statusCode: response.statusCode);
    });
  }

  void dispose() {
    _client.close();
  }
}
