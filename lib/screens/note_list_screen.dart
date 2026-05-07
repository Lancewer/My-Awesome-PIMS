import 'package:flutter/material.dart';
import 'package:my_awesome_pims/models/note.dart';
import 'package:my_awesome_pims/services/note_api_service.dart';
import 'package:my_awesome_pims/screens/compose_screen.dart';
import 'package:my_awesome_pims/screens/search_screen.dart';
import 'package:my_awesome_pims/widgets/tag_colors.dart';

class NoteListScreen extends StatefulWidget {
  final NoteApiService apiService;
  const NoteListScreen({super.key, required this.apiService});

  @override
  State<NoteListScreen> createState() => _NoteListScreenState();
}

class _NoteListScreenState extends State<NoteListScreen> {
  // Notes stored oldest-first. Newest notes are at the end of the list.
  List<Note> _notes = [];
  String? _expandedNoteId; // Only one note can be expanded at a time
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  String? _error;
  int _currentPage = 1;
  static const int _pageSize = 20;

  // Inline compose state
  bool _adding = false;
  final _composeController = TextEditingController();
  final _composeFocus = FocusNode();
  bool _saving = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  @override
  void dispose() {
    _composeController.dispose();
    _composeFocus.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadNotes() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final notes = await widget.apiService.fetchNotes(page: 1, pageSize: _pageSize);
      setState(() {
        // API returns newest-first. Reverse so oldest is at top, newest at bottom.
        _notes = notes.reversed.toList();
        _currentPage = 1;
        _hasMore = notes.length == _pageSize;
        _loading = false;
      });
      // Only scroll to bottom on initial load
      if (_currentPage == 1 && _notes.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      }
    } catch (e) {
      setState(() {
        _error = e is ApiException ? e.message : 'Failed to load notes';
        _loading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore) return;
    final previousOffset = _scrollController.hasClients ? _scrollController.offset : 0.0;
    setState(() => _loadingMore = true);
    try {
      final nextPage = _currentPage + 1;
      final notes = await widget.apiService.fetchNotes(page: nextPage, pageSize: _pageSize);
      setState(() {
        // Prepend older notes to the top of the list
        _notes.insertAll(0, notes.reversed);
        _currentPage = nextPage;
        _hasMore = notes.length == _pageSize;
        _loadingMore = false;
      });
      // Restore scroll position so the view stays where the user was reading
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(previousOffset);
        }
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

  void _toggleExpand(String noteId) {
    setState(() {
      if (_expandedNoteId == noteId) {
        // Tapping the already-expanded note collapses it
        _expandedNoteId = null;
      } else {
        // Expand this note, automatically collapse any other
        _expandedNoteId = noteId;
      }
    });
  }

  void _onNoteTap(Note note) {
    _toggleExpand(note.id);
  }

  void _onEditNote(Note note) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ComposeScreen(apiService: widget.apiService, initialContent: note.content, noteId: note.id, isEdit: true)),
    ).then((_) => _loadNotes());
  }

  void _onAddPressed() {
    setState(() => _adding = true);
    _composeController.clear();
    // Scroll to bottom after frame renders
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
        _composeFocus.requestFocus();
      }
    });
  }

  Future<void> _saveNewNote() async {
    final content = _composeController.text.trim();
    if (content.isEmpty) {
      setState(() => _adding = false);
      return;
    }
    setState(() => _saving = true);
    try {
      final note = await widget.apiService.createNote(content);
      setState(() {
        _notes.add(note);
        _adding = false;
        _saving = false;
      });
      _composeController.clear();
      // Scroll to new note
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      setState(() => _saving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: ${e is ApiException ? e.message : e.toString()}')),
        );
      }
    }
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
              : _notes.isEmpty && !_adding
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
                          controller: _scrollController,
                          padding: const EdgeInsets.only(bottom: 80),
                          itemCount: _notes.length + (_loadingMore ? 1 : 0) + (_adding ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index < _notes.length) {
                              return _buildNoteCard(_notes[index]);
                            }
                            if (_loadingMore) {
                              return const Padding(
                                padding: EdgeInsets.all(16),
                                child: Center(child: CircularProgressIndicator()),
                              );
                            }
                            return _buildComposeCard();
                          },
                        ),
                      ),
                    ),
      floatingActionButton: FloatingActionButton(
        onPressed: _adding ? null : _onAddPressed,
        child: _saving
            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
            : const Icon(Icons.add),
      ),
    );
  }

  Widget _buildNoteCard(Note note) {
    final isExpanded = _expandedNoteId == note.id;

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
            child: isExpanded
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(note.content, style: const TextStyle(fontSize: 14, height: 1.4, color: Color(0xFF212121))),
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
                      const SizedBox(height: 4),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text('Tap to collapse', style: const TextStyle(fontSize: 10, color: Color(0xFFBDBDBD), fontStyle: FontStyle.italic)),
                      ),
                    ],
                  )
                : SizedBox(
                    height: 80,
                    child: Stack(
                      children: [
                        // Content area
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                note.content,
                                style: const TextStyle(fontSize: 14, height: 1.4, color: Color(0xFF212121)),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (note.tags.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Wrap(spacing: 4, runSpacing: 2, children: note.tags.map((tag) {
                                final colors = TagColors.get(tag.name);
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                  decoration: BoxDecoration(color: colors['bg'], borderRadius: BorderRadius.circular(8)),
                                  child: Text(tag.name, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: colors['fg'])),
                                );
                              }).toList()),
                            ],
                            const SizedBox(height: 2),
                            Text(_formatTime(note.createdAt), style: const TextStyle(fontSize: 10, color: Color(0xFF9E9E9E))),
                          ],
                        ),
                        // Edit icon fixed at bottom-right
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: () => _onEditNote(note),
                            child: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF1A73E8)),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildComposeCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        color: const Color(0xFFF5F5F5),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: _composeController,
                  focusNode: _composeFocus,
                  maxLines: null,
                  minLines: 2,
                  style: const TextStyle(fontSize: 14),
                  decoration: const InputDecoration(
                    hintText: "Type your note...",
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 8),
                  ),
                  onSubmitted: (_) => _saveNewNote(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.check, color: Color(0xFF1A73E8)),
                onPressed: _saving ? null : _saveNewNote,
                iconSize: 28,
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Color(0xFF9E9E9E)),
                onPressed: _saving ? null : () {
                  setState(() => _adding = false);
                  _composeController.clear();
                  FocusScope.of(context).unfocus();
                },
                iconSize: 28,
              ),
            ],
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
