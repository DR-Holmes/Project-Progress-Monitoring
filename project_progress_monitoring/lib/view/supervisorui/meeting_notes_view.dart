import 'package:flutter/material.dart';
import '../../viewmodels/supervisorviewmodel/meeting_notes_view_model.dart';

class MeetingNotesView extends StatefulWidget {
  final int meetingId;
  final String meetingTitle;
  final bool isReadOnly;

  const MeetingNotesView({
    super.key,
    required this.meetingId,
    required this.meetingTitle,
    this.isReadOnly = false,
  });

  @override
  State<MeetingNotesView> createState() => _MeetingNotesViewState();
}

class _MeetingNotesViewState extends State<MeetingNotesView> {
  final MeetingNotesViewModel _viewModel = MeetingNotesViewModel();
  final TextEditingController _notesController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    await _viewModel.fetchMeetingNotes(widget.meetingId);
    if (mounted) {
      setState(() {
        _notesController.text = _viewModel.notes ?? "";
      });
    }
  }

  Future<void> _saveNotes() async {
    setState(() => _isSaving = true);
    bool success = await _viewModel.saveMeetingNotes(widget.meetingId, _notesController.text);
    if (mounted) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? "Notes saved successfully!" : "Failed to save notes"),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
      if (success) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("Notes: ${widget.meetingTitle}", style: const TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          if (!widget.isReadOnly)
            _isSaving
                ? const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                  )
                : IconButton(
                    icon: const Icon(Icons.check, color: Colors.blue),
                    onPressed: _saveNotes,
                  ),
        ],
      ),
      body: _viewModel.isLoading && _notesController.text.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Meeting Remarks & Instructions",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: TextField(
                        controller: _notesController,
                        readOnly: widget.isReadOnly,
                        maxLines: null,
                        expands: true,
                        decoration: InputDecoration(
                          hintText: widget.isReadOnly ? "No notes available for this meeting." : "Write down what was discussed, changes required, and next steps...",
                          border: InputBorder.none,
                        ),
                        style: const TextStyle(fontSize: 15, height: 1.5),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
