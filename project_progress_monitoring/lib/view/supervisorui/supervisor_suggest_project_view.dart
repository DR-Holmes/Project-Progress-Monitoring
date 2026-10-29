import 'package:flutter/material.dart';
import '../../viewmodels/supervisorviewmodel/supervisor_suggest_project_viewmodel.dart';

// ---------------------------------------------------------
// WHAT IS THIS FILE?
// This is the "View" (UI Screen) for Supervisors to suggest a project idea.
// It allows entering a Title and Objectives, setting it as Active/Inactive,
// and submits it back to the database.
// ---------------------------------------------------------

class SupervisorSuggestProjectView extends StatefulWidget {
  final Map<String, dynamic> userMap;
  const SupervisorSuggestProjectView({super.key, required this.userMap});

  @override
  State<SupervisorSuggestProjectView> createState() => _SupervisorSuggestProjectViewState();
}

class _SupervisorSuggestProjectViewState extends State<SupervisorSuggestProjectView> {
  // 1. Instantiate our Brain (ViewModel)
  final SupervisorSuggestProjectViewModel _viewModel = SupervisorSuggestProjectViewModel();

  // 2. Form Controllers to capture typed text
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _objectivesController = TextEditingController();
  bool _isActive = true; // By default, suggested projects are set to Active

  // ---------------------------------------------------------
  // FUNCTION: _submitSuggestion
  // Submits the typed form fields to the viewmodel.
  // ---------------------------------------------------------
  void _submitSuggestion() async {
    final title = _titleController.text.trim();
    final objectives = _objectivesController.text.trim();

    if (title.isEmpty || objectives.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ Please fill in all fields before submitting.")),
      );
      return;
    }

    final supervisorId = widget.userMap['id'].toString();

    // Call viewmodel to save details
    final success = await _viewModel.suggestNewProject(
      title,
      objectives,
      supervisorId,
      _isActive,
    );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("✅ Project suggested and registered successfully!"),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context); // Go back to the dashboard
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("❌ Failed to suggest project. Try again later."),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Suggest Project Idea", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Instruction header banner card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade100),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lightbulb_outline, color: Colors.blue, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "New Idea Suggestion",
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue, fontSize: 13),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Submit a project idea. Once submitted, it will be listed under Offered Projects for student groups to allocate.",
                          style: TextStyle(color: Colors.blue.shade700, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Field 1: Project Title
            const Text(
              "Project Title",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                hintText: "Enter a descriptive title...",
                filled: true,
                fillColor: Colors.grey.shade50,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
              ),
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 20),

            // Field 2: Objectives
            const Text(
              "Objectives & Description",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _objectivesController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: "List key goals, scope, and technical requirements...",
                filled: true,
                fillColor: Colors.grey.shade50,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
              ),
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 20),

            // Switch 3: Active Status
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Set as Active Idea",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      Text(
                        "Allows instant discovery in student allocation search",
                        style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                  Switch(
                    value: _isActive,
                    onChanged: (val) {
                      setState(() => _isActive = val);
                    },
                    activeColor: Colors.blue,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
                onPressed: _viewModel.isSubmitting ? null : _submitSuggestion,
                child: _viewModel.isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text(
                        "Submit Suggestion",
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
