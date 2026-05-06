import 'package:flutter/material.dart';
import 'package:my_awesome_pims/models/note.dart';
import 'package:my_awesome_pims/services/note_api_service.dart';
import 'package:my_awesome_pims/screens/note_detail_screen.dart';
import 'package:my_awesome_pims/widgets/tag_colors.dart';

class SearchScreen extends StatefulWidget {
  final NoteApiService apiService;
  const SearchScreen({super.key, required this.apiService});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  List<Note> _results = [];
  bool _searching = false;
  String _lastQuery = '';

  void _search(String query) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      setState(() {
        _results = [];
        _lastQuery = '';
      });
      return;
    }
    _lastQuery = trimmed;
    _performSearch(trimmed);
  }

  Future<void> _performSearch(String query) async {
    setState(() => _searching = true);
    try {
      final results = await widget.apiService.searchNotes(query);
      setState(() {
        _results = results;
        _searching = false;
      });
    } catch (e) {
      setState(() => _searching = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Search failed: ${e is ApiException ? e.message : e.toString()}')),
        );
      }
    }
  }

  void _onNoteTap(Note note) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => NoteDetailScreen(apiService: widget.apiService, note: note)),
    ).then((_) {
      if (_lastQuery.isNotEmpty) _performSearch(_lastQuery);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
        title: TextField(
          controller: _controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Search notes...', border: InputBorder.none),
          style: const TextStyle(fontSize: 16),
          onChanged: _search,
        ),
      ),
      body: _searching
          ? const Center(child: CircularProgressIndicator())
          : _lastQuery.isEmpty
              ? const Center(child: Text('Type to search', style: TextStyle(color: Color(0xFF9E9E9E))))
              : _results.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.search_off, size: 48, color: Color(0xFF9E9E9E)),
                          const SizedBox(height: 16),
                          Text("No notes matching '$_lastQuery'", style: const TextStyle(fontSize: 16, color: Color(0xFF666666))),
                          const SizedBox(height: 8),
                          const Text('Try a different search term', style: TextStyle(fontSize: 14, color: Color(0xFF999999))),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _results.length,
                      itemBuilder: (context, index) {
                        final note = _results[index];
                        final snippet = note.content.length > 120 ? '${note.content.substring(0, 120)}...' : note.content;
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          child: Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            child: InkWell(
                              onTap: () => _onNoteTap(note),
                              borderRadius: BorderRadius.circular(8),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(snippet, style: const TextStyle(fontSize: 14, height: 1.4, color: Color(0xFF212121)), maxLines: 2, overflow: TextOverflow.ellipsis),
                                    if (note.tags.isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      Wrap(spacing: 4, runSpacing: 4, children: note.tags.map((tag) {
                                        final colors = TagColors.get(tag.name);
                                        return Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(color: colors['bg'], borderRadius: BorderRadius.circular(10)),
                                          child: Text(tag.name, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: colors['fg'])),
                                        );
                                      }).toList()),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}
