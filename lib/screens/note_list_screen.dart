import 'package:flutter/material.dart';
import 'package:my_awesome_pims/models/note.dart';
import 'package:my_awesome_pims/services/note_api_service.dart';
import 'package:my_awesome_pims/screens/compose_screen.dart';
import 'package:my_awesome_pims/screens/note_detail_screen.dart';
import 'package:my_awesome_pims/screens/search_screen.dart';
import 'package:my_awesome_pims/widgets/tag_colors.dart';

class NoteListScreen extends StatefulWidget {
  final NoteApiService apiService;
  const NoteListScreen({super.key, required this.apiService});

  @override
  State<NoteListScreen> createState() => _NoteListScreenState();
}

class _NoteListScreenState extends State<NoteListScreen> {
  List<Note> _notes = [];
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  String? _error;
  int _currentPage = 1;
  static const int _pageSize = 20;

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final notes = await widget.apiService.fetchNotes(page: 1, pageSize: _pageSize);
      setState(() {
        _notes = notes;
        _currentPage = 1;
        _hasMore = notes.length == _pageSize;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e is ApiException ? e.message : 'Failed to load notes';
        _loading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore) return;
    setState(() => _loadingMore = true);
    try {
      final nextPage = _currentPage + 1;
      final notes = await widget.apiService.fetchNotes(page: nextPage, pageSize: _pageSize);
      setState(() {
        _notes.insertAll(0, notes);
        _currentPage = nextPage;
        _hasMore = notes.length == _pageSize;
        _loadingMore = false;
      });
    } catch (e) {
      setState(() => _loadingMore = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load more notes'), duration: const Duration(seconds: 2)),
        );
      }
    }
  }

  void _onNoteTap(Note note) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => NoteDetailScreen(apiService: widget.apiService, note: note)),
    ).then((_) => _loadNotes());
  }

  void _onSave() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ComposeScreen(apiService: widget.apiService)),
    ).then((_) => _loadNotes());
  }

  void _onSearch() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SearchScreen(apiService: widget.apiService)),
    ).then((_) => _loadNotes());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Awesome PIMS', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500)),
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: _onSearch),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorState()
              : _notes.isEmpty
                  ? _buildEmptyState()
                  : NotificationListener<ScrollNotification>(
                      onNotification: (notification) {
                        if (notification.metrics.pixels <= 0 &&
                            notification is OverscrollNotification &&
                            notification.overscroll < -20) {
                          _loadMore();
                        }
                        return false;
                      },
                      child: RefreshIndicator(
                        onRefresh: _loadNotes,
                        child: ListView.builder(
                          padding: const EdgeInsets.only(bottom: 80),
                          itemCount: _notes.length + (_loadingMore ? 1 : 0) + (_hasMore && _currentPage > 1 ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == 0 && _hasMore && _currentPage > 1) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 16),
                                child: Center(child: Text('No more notes', style: TextStyle(color: Color(0xFF9E9E9E), fontSize: 12))),
                              );
                            }
                            final noteIndex = index - (_hasMore && _currentPage > 1 ? 1 : 0);
                            if (_loadingMore && noteIndex == _notes.length) {
                              return const Padding(
                                padding: EdgeInsets.all(16),
                                child: Center(child: CircularProgressIndicator()),
                              );
                            }
                            return _buildNoteCard(_notes[noteIndex]);
                          },
                        ),
                      ),
                    ),
      floatingActionButton: FloatingActionButton(
        onPressed: _onSave,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildNoteCard(Note note) {
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
                const SizedBox(height: 6),
                Text(_formatTime(note.createdAt), style: const TextStyle(fontSize: 11, color: Color(0xFF9E9E9E)), textAlign: TextAlign.right),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.note_alt_outlined, size: 64, color: Color(0xFF9E9E9E)),
          const SizedBox(height: 16),
          const Text('No notes yet', style: TextStyle(fontSize: 16, color: Color(0xFF666666))),
          const SizedBox(height: 8),
          const Text('Tap + to capture your first thought', style: TextStyle(fontSize: 14, color: Color(0xFF999999))),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Color(0xFFD32F2F)),
          const SizedBox(height: 16),
          Text(_error!, style: const TextStyle(fontSize: 16, color: Color(0xFF666666))),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _loadNotes, child: const Text('Retry')),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }
}
