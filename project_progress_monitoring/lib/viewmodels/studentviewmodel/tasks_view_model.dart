import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../api_config.dart';

// --- VIEWMODEL ---
// WHAT IT DOES: This is the "brain" for the Tasks screens.
// It fetches tasks from the server, fetches supervisor remarks, and handles file uploads.
// WHY IT EXISTS: We keep all server communication here so the View file stays clean.
class TasksViewModel {

  // ============================================================
  // FUNCTION: fetchTasks
  // WHAT: Gets all tasks (group + individual) for a student.
  // HOW:  1. First fetches the student's profile to get their groupId.
  //       2. Then fetches all tasks for that group + student.
  // ============================================================
  Future<List<Map<String, dynamic>>> fetchTasks(String studentId) async {
    try {
      // Step 1: Get student profile so we know their group ID
      final profileUrl = Uri.parse("${ApiConfig.baseUrl}/students/$studentId");
      final profileRes = await http.get(profileUrl);

      if (profileRes.statusCode == 200) {
        final profileData = jsonDecode(profileRes.body);
        int? groupId = profileData['groupId'] ?? profileData['GroupId'];

        if (groupId != null) {
          // Step 2: Fetch all tasks for this student in their group
          final taskUrl = Uri.parse("${ApiConfig.baseUrl}/supervisor/StudentTasks/$groupId/$studentId");
          final taskRes = await http.get(taskUrl);

          if (taskRes.statusCode == 200) {
            List<dynamic> data = jsonDecode(taskRes.body);

            return data.map((t) {
              final taskMap = t as Map<String, dynamic>;

              // --- FIGURE OUT THE STATUS ---
              // The status can be "completed", "pending", or "overdue"
              // We check the due date ourselves to see if it is overdue.
              String status = "pending";
              String rawStatus = taskMap['taskStatus']?.toString().toLowerCase() ?? "";

              if (rawStatus == "completed") {
                status = "completed";
              } else if (taskMap['dueDate'] != null) {
                DateTime dueDate = DateTime.parse(taskMap['dueDate'].toString());
                if (dueDate.isBefore(DateTime.now())) {
                  status = "overdue";
                }
              }

              // Return a simple Map for the View to use
              return {
                'id': taskMap['id'],
                'title': taskMap['title'] ?? "Untitled Task",
                'dueDate': taskMap['dueDate'] != null ? _formatDate(taskMap['dueDate']) : "No due date",
                'assignDate': taskMap['assignDate'] != null ? _formatDate(taskMap['assignDate']) : "N/A",
                'status': status,
                'taskStatus': taskMap['taskStatus'] ?? "Pending",
                'progress': taskMap['progress'] ?? 0,
                'isPptRequired': taskMap['isPptRequired'] ?? false,
                'assignedType': taskMap['AssignedType'] ?? taskMap['assignedType'] ?? "Individual",
                'description': taskMap['taskDescription'] ?? "",
              };
            }).toList();
          }
        } else {
          debugPrint("Student is not in any group yet.");
        }
      }
    } catch (e) {
      debugPrint("Error fetching tasks: $e");
    }
    return [];
  }

  // ============================================================
  // FUNCTION: _formatDate (private helper)
  // WHAT: Turns a messy date string like "2025-01-01T00:00:00"
  //       into a clean "2025-01-01".
  // ============================================================
  String _formatDate(String isoString) {
    try {
      DateTime dt = DateTime.parse(isoString);
      return "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}";
    } catch (e) {
      return isoString;
    }
  }

  // ============================================================
  // FUNCTION: getTaskEvaluation
  // WHAT: Gets the supervisor's remarks/score for a specific task.
  // Returns a Map with 'remarks' and 'evaluationDate', or null if not evaluated yet.
  // ============================================================
  Future<Map<String, dynamic>?> getTaskEvaluation(int taskId) async {
    try {
      final url = Uri.parse("${ApiConfig.baseUrl}/users/GetTaskEvaluation/$taskId");
      final response = await http.get(url);
      if (response.statusCode == 200 && response.body.isNotEmpty) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint("Error fetching evaluation: $e");
    }
    return null;
  }

  // ============================================================
  // FUNCTION: fetchTaskDetail
  // WHAT: Fetches the FULL details of ONE specific task from the server.
  //       This is exactly what the React TaskDetail page does:
  //       GET /students/tasks/{taskId}
  // WHY: The task list doesn't include remarks or submission info.
  //      This detail endpoint returns everything in one go:
  //      title, taskDescription, assignDate, dueDate, taskStatus,
  //      isPptRequired, progress, remarks, submissionFilePath
  // RETURNS: A Map with all task details, or an empty Map if it fails.
  // ============================================================
  Future<Map<String, dynamic>> fetchTaskDetail(int taskId) async {
    try {
      // Build the URL: /students/tasks/{taskId}
      final url = Uri.parse("${ApiConfig.baseUrl}/students/tasks/$taskId");
      debugPrint("--> Fetching task detail from: $url");

      final response = await http.get(url);
      debugPrint("<-- Server responded: ${response.statusCode}");

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        // Parse and return the task as a Map
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint("Error fetching task detail: $e");
    }
    // Return empty Map if something went wrong
    return {};
  }

  // ============================================================
  // FUNCTION: uploadFile
  // WHAT: Sends a file that has ALREADY been picked by the View
  //       to the server via multipart/form-data.
  // WHY: FilePicker.platform MUST be called from inside a Widget
  //      (the View), not from a ViewModel. Calling it from a ViewModel
  //      causes: LateInitializationError: Field '_instance' has not been initialized.
  //      So we split the job:
  //        - View:      picks the file (FilePicker.platform.pickFiles)
  //        - ViewModel: uploads the file (this method)
  // PARAMS:
  //   taskId   - which task this file belongs to
  //   filePath - the full path to the chosen file on the device
  // RETURNS: true if upload worked, false if it failed.
  // ============================================================
  Future<bool> uploadFile(int taskId, String filePath) async {
    try {
      // Build the URL for the upload endpoint
      final url = Uri.parse("${ApiConfig.baseUrl}/supervisor/upload-task-ppt");

      // Build a multipart request
      // WHY multipart: The server expects a real file (like an HTML <input type=file>).
      //                JSON cannot send binary file data — multipart/form-data is required.
      var request = http.MultipartRequest("POST", url);

      // Attach the file — "file" matches httpRequest.Files["file"] in C#
      request.files.add(
        await http.MultipartFile.fromPath("file", filePath),
      );

      // Attach the taskId — "taskId" matches httpRequest["taskId"] in C#
      request.fields["taskId"] = taskId.toString();

      // Send the request and wait for the server's response
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      debugPrint("Upload response: ${response.statusCode} - ${response.body}");
      return response.statusCode == 200;

    } catch (e) {
      debugPrint("File upload error: $e");
      return false;
    }
  } // End of uploadFile method
}