import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../supervisorui/meeting_notes_view.dart';
import '../../api_config.dart';

// ============================================================
//            --- STUDENT MEETING DETAILS VIEW ---
// ============================================================
// WHAT THIS SCREEN DOES:
//   Shows the full details of one meeting that the student tapped on.
//   Displays: Title, Date, Time, Location, Description.
//   If the meeting requires a file upload (isFileRequired == true),
//   it shows a "Upload Required File" section at the bottom.
//
// HOW FILE UPLOADING WORKS:
//   The meeting's scheduleId is passed in the meeting Map.
//   The student taps "Upload File" → file picker opens →
//   they pick any file → we POST it to /committee-meetings/upload-ppt
//   with form fields: "file" (the actual file) + "scheduleId" (which schedule).
//
// WHY StatefulWidget (not StatelessWidget):
//   Because we have file upload state (_pickedFileName, _isUploading)
//   that changes and needs to redraw the UI.
// ============================================================
class StudentMeetingdetailsView extends StatefulWidget {
  // The meeting data map passed from the meetings list screen
  final Map<String, dynamic> meeting;

  const StudentMeetingdetailsView({super.key, required this.meeting});

  @override
  State<StudentMeetingdetailsView> createState() => _StudentMeetingdetailsViewState();
}

class _StudentMeetingdetailsViewState extends State<StudentMeetingdetailsView> {

  // --- STATE VARIABLES ---
  // _pickedFileName: Shows which file name the student has picked (or null if none)
  // _isUploading: true while the file is being sent to the server
  // _pickedFilePath: The full path to the file on the device (needed to read and send it)
  String? _pickedFileName;
  String? _pickedFilePath;
  bool _isUploading = false;

  // ============================================================
  // FUNCTION: _pickFile
  // WHAT: Opens the device's file manager so the student can choose a file.
  // HOW: Uses the file_picker package. When they pick a file, we save
  //      its name (to display) and its path (to upload later).
  // ============================================================
  Future<void> _pickFile() async {
    // Open the file picker - any file type is allowed
    FilePickerResult? result = await FilePicker.pickFiles(
      type: FileType.any,
    );

    // If they picked a file, save its info to state (which redraws the UI)
    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _pickedFileName = result.files.first.name;   // e.g. "presentation.pptx"
        _pickedFilePath = result.files.first.path;   // e.g. "/storage/.../presentation.pptx"
      });
    }
  }

  // ============================================================
  // FUNCTION: _handleUpload
  // WHAT: Sends the picked file to the server.
  // HOW:
  //   1. Makes sure a file was picked and a scheduleId exists
  //   2. Builds a multipart HTTP request
  //   3. Attaches the file + scheduleId
  //   4. Sends it and shows success/error message
  //
  // The C# endpoint: POST /committee-meetings/upload-ppt
  //   It expects: "file" (the actual file) + "scheduleId" (int)
  // ============================================================
  Future<void> _handleUpload() async {
    // Make sure the student has picked a file first
    if (_pickedFilePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a file first.")),
      );
      return;
    }

    // Get the scheduleId from the meeting map
    // WHY scheduleId: The C# endpoint saves the file path to a GroupSchedule row
    int? scheduleId = widget.meeting['scheduleId'] ?? widget.meeting['id'];
    if (scheduleId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No schedule ID found for this meeting."), backgroundColor: Colors.red),
      );
      return;
    }

    // Turn on the uploading spinner
    setState(() => _isUploading = true);

    try {
      // Build a multipart request
      // WHY multipart: The server expects a real file (like an HTML form upload).
      //                We can't use JSON for files — multipart/form-data is required.
      final url = Uri.parse("${ApiConfig.baseUrl}/committee-meetings/upload-ppt");
      var request = http.MultipartRequest("POST", url);

      // Attach the actual file
      // "file" matches the C# code: httpRequest.Files["file"]
      request.files.add(
        await http.MultipartFile.fromPath("file", _pickedFilePath!),
      );

      // Attach the scheduleId as a text field
      // "scheduleId" matches the C# code: httpRequest["scheduleId"]
      request.fields["scheduleId"] = scheduleId.toString();

      // Send the request and wait for the server's response
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (mounted) {
        setState(() => _isUploading = false);

        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("✅ File uploaded successfully!"),
              backgroundColor: Colors.green,
            ),
          );
          // Clear the picked file state after successful upload
          setState(() {
            _pickedFileName = null;
            _pickedFilePath = null;
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("❌ Upload failed. Please try again."),
              backgroundColor: Colors.red,
            ),
          );
        }
      }

    } catch (e) {
      if (mounted) {
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  // ============================================================
  // BUILD METHOD: Draws the screen UI
  // ============================================================
  @override
  Widget build(BuildContext context) {
    // Read meeting values from the Map
    String title = widget.meeting['title'] ?? "FYP Meeting";
    String description = widget.meeting['description'] ?? "No description available.";
    String date = widget.meeting['date']?.toString().split('T')[0] ?? "N/A";
    String time = widget.meeting['time']?.toString() ?? "N/A";
    String venue = widget.meeting['location'] ?? widget.meeting['venue'] ?? "Online";

    // isFileRequired: if true, show the upload section
    // It can come as bool (true) or int (1) from different APIs
    bool isFileRequired = widget.meeting['isFileRequired'] == true
        || widget.meeting['isFileRequired'] == 1;

    // isSupervisor: Changes the badge color and label
    bool isSupervisor = widget.meeting['isSupervisor'] == true;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Meeting Details", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ---- HEADER: Icon + Title + Meeting Type Badge ----
            Center(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4A65FF).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.groups_rounded, size: 60, color: Color(0xFF4A65FF)),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  // Badge that says "Supervisor Meeting" or "Committee Meeting"
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSupervisor ? Colors.indigo.shade50 : Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isSupervisor ? "Supervisor Meeting" : (widget.meeting['type'] ?? "Committee Meeting"),
                      style: TextStyle(
                        color: isSupervisor ? Colors.indigo : Colors.blue,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // ---- SCHEDULE SECTION: Date, Time, Location ----
            _infoSection("Schedule Information", [
              _infoRow(Icons.calendar_today_outlined, "Date", date),
              _infoRow(Icons.access_time_rounded, "Time", time),
              _infoRow(Icons.location_on_outlined, "Location", venue),
            ]),

            const SizedBox(height: 30),

            // ---- AGENDA / DESCRIPTION ----
            const Text("Agenda", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Text(
                description,
                style: TextStyle(fontSize: 15, color: Colors.grey.shade800, height: 1.5),
              ),
            ),

            const SizedBox(height: 30),

            // ---- FILE UPLOAD SECTION (only shown if meeting requires a file) ----
            // This mirrors the React: {meeting.isFileRequired && (...)}
            if (isFileRequired) ...[
              const Text("Upload Required File", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // "Choose File" button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton.icon(
                        onPressed: _pickFile,
                        icon: const Icon(Icons.attach_file),
                        label: const Text("Choose File"),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF4A65FF),
                          side: const BorderSide(color: Color(0xFF4A65FF)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),

                    // Show the picked file name if one was chosen
                    if (_pickedFileName != null) ...[
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Icon(Icons.insert_drive_file, size: 16, color: Colors.grey),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              _pickedFileName!,
                              style: const TextStyle(fontSize: 13, color: Colors.grey),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 12),

                    // "Upload File" button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        // Disable button while uploading OR if no file has been picked
                        onPressed: (_isUploading || _pickedFilePath == null) ? null : _handleUpload,
                        icon: _isUploading
                            ? const SizedBox(
                                width: 18, height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                              )
                            : const Icon(Icons.cloud_upload_outlined),
                        label: Text(
                          _isUploading ? "Uploading..." : "Upload File",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4A65FF),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // ---- BACK BUTTON ----
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4A65FF),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  elevation: 0,
                ),
                child: const Text("Back to List", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),

            const SizedBox(height: 15),

            // ---- VIEW MEETING NOTES BUTTON ----
            SizedBox(
              width: double.infinity,
              height: 55,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MeetingNotesView(
                        meetingId: widget.meeting['meetingId'] ?? widget.meeting['id'],
                        meetingTitle: title,
                        isReadOnly: true,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.notes, size: 20),
                label: const Text("View Meeting Notes", style: TextStyle(fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF4A65FF),
                  side: const BorderSide(color: Color(0xFF4A65FF)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
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
  // HELPER WIDGET: _infoSection
  // WHAT: Groups a list of info rows inside a labeled card.
  //       e.g. "Schedule Information" heading + date/time/venue rows
  // ============================================================
  Widget _infoSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.bold, letterSpacing: 1),
        ),
        const SizedBox(height: 15),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  // ============================================================
  // HELPER WIDGET: _infoRow
  // WHAT: One row with icon, label, and value.
  //       e.g. calendar icon | "Date" | "2025-05-20"
  // ============================================================
  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF4A65FF)),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
              Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ],
          ),
        ],
      ),
    );
  }
}
