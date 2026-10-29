import 'package:flutter/material.dart';

import '../../viewmodels/supervisorviewmodel/edit_meeting_viewmodel.dart';

// --- VIEW ---
class EditMeetingView extends StatefulWidget {
  final Map<String, dynamic> meeting;

  const EditMeetingView({super.key, required this.meeting});

  @override
  State<EditMeetingView> createState() => _EditMeetingViewState();
}

class _EditMeetingViewState extends State<EditMeetingView> {
  final EditMeetingViewModel _viewModel = EditMeetingViewModel();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _descController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Fill the text boxes with the current meeting details
    _titleController.text = widget.meeting['Title'] ?? widget.meeting['title'] ?? "";
    _descController.text = widget.meeting['Description'] ?? widget.meeting['description'] ?? "";
    
    // We only want the date part, e.g., '2025-11-02'
    String fullDate = widget.meeting['Date'] ?? widget.meeting['date'] ?? "";
    if (fullDate.contains("T")) {
      _dateController.text = fullDate.split("T")[0];
    } else {
      _dateController.text = fullDate;
    }
  }

  void _onSave() async {
    setState(() => _viewModel.isLoading = true);
    
    Map<String, dynamic> updatedData = {
      "id": widget.meeting['Id'] ?? widget.meeting['id'],
      "title": _titleController.text,
      "date": _dateController.text,
      "description": _descController.text,
    };

    await _viewModel.updateMeeting(updatedData);
    
    if (mounted) {
      setState(() => _viewModel.isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Meeting Updated Successfully! (Mock)")),
      );
      Navigator.pop(context); // Go back after saving
    }
  }

  void _onCancelMeeting() async {
    setState(() => _viewModel.isLoading = true);
    
    String meetingId = (widget.meeting['Id'] ?? widget.meeting['id'] ?? "").toString();
    await _viewModel.cancelMeeting(meetingId);
    
    if (mounted) {
      setState(() => _viewModel.isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("This meeting has been cancelled! (Mock)")),
      );
      Navigator.pop(context); // Go back after cancelling
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Edit Meeting", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        foregroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _viewModel.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _label("Meeting Title"),
                        TextField(
                          controller: _titleController,
                          decoration: _inputDeco("Enter title"),
                        ),
                        const SizedBox(height: 16),

                        _label("Meeting Date"),
                        TextField(
                          controller: _dateController,
                          decoration: _inputDeco("YYYY-MM-DD"),
                          // A simple text field for now to match React's type="date"
                        ),
                        const SizedBox(height: 16),

                        _label("Meeting Description"),
                        TextField(
                          controller: _descController,
                          maxLines: 4,
                          decoration: _inputDeco("Write meeting details, agenda, instructions..."),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _onSave,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        elevation: 0,
                      ),
                      child: const Text("Save Changes", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Cancel This Meeting Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _onCancelMeeting,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade600,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        elevation: 0,
                      ),
                      child: const Text("Cancel This Meeting", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Back Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text("Back", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87)),
    );
  }

  InputDecoration _inputDeco(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      filled: true,
      fillColor: Colors.grey.shade50,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade200)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade200)),
    );
  }
}
