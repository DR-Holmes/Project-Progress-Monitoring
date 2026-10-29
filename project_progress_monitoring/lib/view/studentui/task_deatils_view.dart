import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../viewmodels/studentviewmodel/tasks_view_model.dart';

// ============================================================
//                --- TASK DETAILS VIEW ---
// ============================================================
// WHAT THIS SCREEN DOES:
//   Shows full details of ONE task — exactly like the React TaskDetail page.
//
// HOW IT WORKS (matching React):
//   1. The task ID comes from the task Map passed from the tasks list screen.
//   2. On load, it calls GET /students/tasks/{taskId} to get fresh full data.
//      This single API call returns: title, status, dates, description,
//      progress (0–100), remarks, and submissionFilePath — all in one shot.
//   3. Displays 4 sections: Header, Description, Progress, Remarks.
//   4. Shows an "Upload Submission" button at the bottom.
//
// ARCHITECTURE: VVM — View talks to ViewModel, ViewModel talks to server.
// STATE: Uses simple setState() — no BLoC, no Provider, nothing fancy.
// ============================================================
class TaskDetailsView extends StatefulWidget {
  // The task Map passed in from the tasks list screen.
  // We use the 'id' from this Map to fetch fresh full details.
  // We also use 'assignedType' since the detail endpoint doesn't return it.
  final Map<String, dynamic> task;

  const TaskDetailsView({super.key, required this.task});

  @override
  State<TaskDetailsView> createState() => _TaskDetailsViewState();
}

class _TaskDetailsViewState extends State<TaskDetailsView> {

  // Our "brain" — handles all server calls
  final TasksViewModel _viewModel = TasksViewModel();

  // ============================================================
  // STATE VARIABLES
  // ============================================================
  // _taskDetail : The full task data fetched from the server.
  //               Starts empty, gets filled when the API call finishes.
  // _isLoading  : true while we are waiting for the server to respond.
  //               Shows a spinner so the user knows something is happening.
  // _isUploading: true while a file is being sent to the server.
  //               Disables the upload button to prevent double-taps.
  Map<String, dynamic> _taskDetail = {};
  bool _isLoading = true;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    // As soon as the screen opens, fetch the full task details from the server.
    // This matches the React useEffect(() => { if (taskId) fetchTask(); }, [taskId])
    _loadTaskDetail();
  }

  // ============================================================
  // FUNCTION: _loadTaskDetail
  // WHAT: Fetches the complete task data from the server.
  //       Exactly matches React's fetchTask() function.
  // HOW:  1. Show spinner (_isLoading = true)
  //       2. Ask ViewModel to call GET /students/tasks/{taskId}
  //       3. Save the result to _taskDetail
  //       4. Hide spinner (_isLoading = false)
  // ============================================================
  Future<void> _loadTaskDetail() async {
    // Show the spinner
    setState(() => _isLoading = true);

    // Get the task ID from the Map passed in from the previous screen
    int taskId = widget.task['id'] ?? 0;

    // Ask the ViewModel to fetch fresh task details from the server
    Map<String, dynamic> detail = await _viewModel.fetchTaskDetail(taskId);

    // Only update the screen if it's still open (mounted = still on screen)
    if (mounted) {
      setState(() {
        _taskDetail = detail;
        _isLoading = false;
      });
    }
  }

  // ============================================================
  // FUNCTION: _handleUpload
  // WHAT: Step 1 — Opens the file picker (MUST be done here in the View,
  //                NOT in the ViewModel, because FilePicker.platform needs
  //                to be called from a Widget context to initialize properly).
  //       Step 2 — Passes the chosen file path to the ViewModel for the HTTP upload.
  // WHY the split: Calling FilePicker.platform from inside a ViewModel causes:
  //                "LateInitializationError: Field '_instance' has not been initialized"
  // ============================================================
  Future<void> _handleUpload() async {
    // STEP 1: Pick a file — called here in the View (Widget context)
    FilePickerResult? result = await FilePicker.pickFiles(
      type: FileType.any, // Allow pdf, docx, pptx, etc.
    );

    // If the student closed the picker without choosing, do nothing
    if (result == null || result.files.isEmpty) return;

    // Get the file path from the picked file
    String? filePath = result.files.first.path;

    // If no path (shouldn't happen, but safety check)
    if (filePath == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Could not read file path."), backgroundColor: Colors.red),
        );
      }
      return;
    }

    // Show the uploading spinner
    setState(() => _isUploading = true);

    int taskId = widget.task['id'] ?? 0;

    // STEP 2: Pass the file path to the ViewModel — it handles the HTTP upload
    bool success = await _viewModel.uploadFile(taskId, filePath);

    // Turn off the spinner
    if (mounted) setState(() => _isUploading = false);

    // Show success or failure message
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? "✅ Uploaded successfully!" : "❌ Upload failed. Try again."),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
      // Refresh the task so status/progress updates after a successful upload
      if (success) _loadTaskDetail();
    }
  }

  // ============================================================
  // HELPER: _getStatusColor
  // WHAT: Returns a background color for the status badge.
  //       Matches the React getStatusColor() function exactly.
  // ============================================================
  Color _getStatusColor(String? status) {
    if (status == null) return Colors.grey;
    final s = status.toLowerCase();
    if (s == "completed") return Colors.green;
    if (s == "pending") return Colors.orange;
    if (s == "in progress") return Colors.blue;
    return Colors.red; // overdue or anything else
  }

  // ============================================================
  // BUILD METHOD: Draws the whole screen
  // ============================================================
  @override
  Widget build(BuildContext context) {

    // --- LOADING STATE ---
    // While fetching from server, show a full-screen spinner.
    // Matches React: if (loading) { return <div>Loading...</div> }
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.grey.shade50,
        appBar: AppBar(
          title: const Text("Task Details", style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // --- NO DATA STATE ---
    // If the server returned nothing, show a friendly message.
    // Matches React: if (!task) { return <div>Task not found</div> }
    if (_taskDetail.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.grey.shade50,
        appBar: AppBar(
          title: const Text("Task Details", style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
        ),
        body: Center(
          child: Text(
            "Task not found.",
            style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
          ),
        ),
      );
    }

    // --- READ VALUES FROM THE FETCHED MAP ---
    // These key names come directly from the C# API response.
    // We use ?? to give a safe default in case the value is missing.
    String title = _taskDetail['title'] ?? "Task";
    String status = _taskDetail['taskStatus'] ?? "Pending";
    String dueDate = _formatDate(_taskDetail['dueDate']);
    String assignDate = _formatDate(_taskDetail['assignDate']);
    String description = _taskDetail['taskDescription'] ?? "No description";
    int progress = _taskDetail['progress'] ?? 0;
    String remarks = _taskDetail['remarks'] ?? "No remarks";

    // 'assignedType' is NOT returned by the detail endpoint.
    // We fall back to the value from the task list Map (passed from prev screen).
    String assignedType = widget.task['assignedType'] ?? "Individual";

    // --- MAIN SCREEN ---
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text("Task Details", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        // Refresh button at the top right
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTaskDetail,
          ),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [

            // ============================================================
            // SECTION 1: HEADER CARD
            // Shows title, colored status badge, due date, assign date, type.
            // Matches React's {/* HEADER */} section.
            // ============================================================
            _buildCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // Top row: Task title + status badge side by side
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title takes all available space
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Colored status badge (green, orange, blue, red)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getStatusColor(status),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          status,
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Due Date row
                  _infoRow(Icons.calendar_today, "Due: $dueDate"),
                  const SizedBox(height: 10),

                  // Assigned Date row
                  _infoRow(Icons.access_time, "Assigned: $assignDate"),
                  const SizedBox(height: 10),

                  // Task Type row (Individual or Group)
                  _infoRow(Icons.person_outline, "Assigned Type: $assignedType"),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ============================================================
            // SECTION 2: DESCRIPTION CARD
            // Shows the full task instructions.
            // Matches React's {/* DESCRIPTION */} section.
            // ============================================================
            _buildCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Description",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    description,
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade700, height: 1.5),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ============================================================
            // SECTION 3: PROGRESS BAR CARD
            // Shows a visual bar (0% to 100%) for task completion.
            // Matches React's {/* PROGRESS */} section.
            // ============================================================
            _buildCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Progress",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 12),

                  // The progress bar — gray background, blue/green fill
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      // Flutter uses 0.0 to 1.0, so we divide by 100
                      value: progress / 100.0,
                      minHeight: 10,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        progress == 100 ? Colors.green : Colors.blue,
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),
                  // Text below the bar: "75% completed"
                  Text(
                    "$progress% completed",
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ============================================================
            // SECTION 4: REMARKS CARD
            // Shows the supervisor's feedback/remarks on this task.
            // Matches React's {/* REMARKS */} section.
            // The 'remarks' field comes directly from the detail API — no extra call needed.
            // ============================================================
            _buildCard(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // File text icon on the left
                  Icon(Icons.description_outlined, color: Colors.blue, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Remarks",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          remarks,
                          style: TextStyle(fontSize: 14, color: Colors.grey.shade600, height: 1.5),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ============================================================
            // UPLOAD SUBMISSION BUTTON
            // Matches React's <Button>Upload Submission</Button>
            // The button is disabled (grayed out) while uploading.
            // ============================================================
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                // null = button is disabled (grayed out) — prevents double-taps while uploading
                onPressed: _isUploading ? null : _handleUpload,
                icon: _isUploading
                    ? const SizedBox(
                        width: 18, height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                      )
                    : const Icon(Icons.cloud_upload_outlined),
                label: Text(
                  _isUploading ? "Uploading..." : "Upload Submission",
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),

            const SizedBox(height: 20),

          ], // End of Column children
        ),
      ),
    );
  }

  // ============================================================
  // HELPER WIDGET: _buildCard
  // WHAT: Wraps content in a white rounded card with a subtle border.
  //       Every section (Header, Description, Progress, Remarks) uses this.
  // WHY:  Keeps the card styling consistent throughout the screen.
  // ============================================================
  Widget _buildCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: child,
    );
  }

  // ============================================================
  // HELPER WIDGET: _infoRow
  // WHAT: One row with an icon and text.
  //       Used for the Due Date, Assigned Date, and Type lines.
  // ============================================================
  Widget _infoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade500),
        const SizedBox(width: 10),
        Text(text, style: TextStyle(fontSize: 14, color: Colors.grey.shade700)),
      ],
    );
  }

  // ============================================================
  // HELPER: _formatDate
  // WHAT: Converts "2025-01-15T00:00:00" into "2025-01-15"
  //       (cuts off the time part that the server sends back)
  // ============================================================
  String _formatDate(dynamic rawDate) {
    if (rawDate == null) return "N/A";
    try {
      // Parse then format cleanly
      DateTime dt = DateTime.parse(rawDate.toString());
      return "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}";
    } catch (_) {
      return rawDate.toString();
    }
  }
}