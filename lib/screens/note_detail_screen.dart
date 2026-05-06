import 'package:flutter/material.dart';
import 'package:my_awesome_pims/models/note.dart';
import 'package:my_awesome_pims/services/note_api_service.dart';
import 'package:my_awesome_pims/screens/compose_screen.dart';
import 'package:my_awesome_pims/widgets/tag_colors.dart';

class NoteDetailScreen extends StatefulWidget {
  final NoteApiService apiService;
  final Note note;
  const NoteDetailScreen({super.key, required this.apiService, required this.note});

  @override
  State<NoteDetailScreen> createState() => _NoteDetailScreenState();
}

class _NoteDetailScreenState extends State<NoteDetailScreen> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.note.content);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _edit() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => ComposeScreen(apiService: widget.apiService, initialContent: widget.note.content, isEdit: true)),
    );
    if (result == true && mounted) {
      _reloadNote();
    }
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete this note?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Color(0xFFD32F2F))),
          ),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await widget.apiService.deleteNote(widget.note.id);
        if (mounted) Navigator.pop(context);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete: ${e is ApiException ? e.message : e.toString()}')),
          );
        }
      }
    }
  }

  Future<void> _reloadNote() async {
    try {
      final note = await widget.apiService.getNote(widget.note.id);
      if (mounted) {
        setState(() {
          _controller.text = note.content;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Note no longer exists')),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
        actions: [
          IconButton(icon: const Icon(Icons.edit), onPressed: _edit),
          IconButton(icon: const Icon(Icons.delete_outline, color: Color(0xFFD32F2F)), onPressed: _delete),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.note.content, style: const TextStyle(fontSize: 15, height: 1.5, color: Color(0xFF212121))),
            if (widget.note.tags.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(spacing: 4, runSpacing: 4, children: widget.note.tags.map((tag) {
                final colors = TagColors.get(tag.name);
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: colors['bg'], borderRadius: BorderRadius.circular(10)),
                  child: Text(tag.name, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: colors['fg'])),
                );
              }).toList()),
            ],
            const Spacer(),
            Text('Created: ${_formatDate(widget.note.createdAt)}', style: const TextStyle(fontSize: 12, color: Color(0xFF9E9E9E))),
            if (widget.note.updatedAt != widget.note.createdAt)
              Text('Updated: ${_formatDate(widget.note.updatedAt)}', style: const TextStyle(fontSize: 12, color: Color(0xFF9E9E9E))),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} at ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
