import 'package:flutter/material.dart';
import 'package:my_awesome_pims/services/note_api_service.dart';

class ComposeScreen extends StatefulWidget {
  final NoteApiService apiService;
  final String? initialContent;
  final bool isEdit;
  const ComposeScreen({super.key, required this.apiService, this.initialContent, this.isEdit = false});

  @override
  State<ComposeScreen> createState() => _ComposeScreenState();
}

class _ComposeScreenState extends State<ComposeScreen> {
  final _controller = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialContent != null) {
      _controller.text = widget.initialContent!;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final content = _controller.text.trim();
    if (content.isEmpty) return;

    setState(() => _saving = true);
    try {
      await widget.apiService.createNote(content);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _saving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: ${e is ApiException ? e.message : e.toString()}')),
        );
      }
    }
  }

  Future<void> _onBack() async {
    if (_controller.text.trim().isNotEmpty) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Discard note?'),
          content: const Text('Your changes will be lost.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Discard')),
          ],
        ),
      );
      if (confirm == true && mounted) Navigator.pop(context);
    } else if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: _onBack),
        title: Text(widget.isEdit ? 'Edit Note' : 'New Note'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Save', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ],
      ),
      body: TextField(
        controller: _controller,
        autofocus: true,
        maxLines: null,
        expands: true,
        minLines: null,
        textAlignVertical: TextAlignVertical.top,
        style: const TextStyle(fontSize: 16),
        decoration: const InputDecoration(
          hintText: "What's on your mind? Use #tags to organize...",
          border: InputBorder.none,
          contentPadding: EdgeInsets.all(16),
        ),
      ),
    );
  }
}
