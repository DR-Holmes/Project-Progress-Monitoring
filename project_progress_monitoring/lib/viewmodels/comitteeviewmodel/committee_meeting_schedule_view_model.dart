import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../api_config.dart'; // Ensure this points to your ApiConfig

class CommitteeMeetingScheduleViewModel {
  // Form Fields
  String title = '';
  String description = '';
  String location = '';
  DateTime? startDate;
  DateTime? endDate;
  TimeOfDay? startTime;
  TimeOfDay? endTime;

  // Days of the week (Matches C# list: ["Mon", "Tue", ...])
  List<bool> selectedDays = List.generate(7, (_) => false);
  final List<String> dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  Map<String, dynamic>? previewResult;

  Future<void> loadPreview(String type) async {
    if (startDate == null || endDate == null) {
      previewResult = null;
      return;
    }

    List<String> daysList = [];
    for (int i = 0; i < selectedDays.length; i++) {
      if (selectedDays[i]) daysList.add(dayLabels[i]);
    }

    if (daysList.isEmpty) {
      previewResult = null;
      return;
    }

    int? sessionId = await _getCurrentSessionId();
    if (sessionId == null) return;

    try {
      final url = Uri.parse(
          "${ApiConfig.baseUrl}/committee-meetings/meeting-distribution-preview"
          "?type=${Uri.encodeComponent(type)}"
          "&sessionId=$sessionId"
          "&startDate=${startDate!.toIso8601String()}"
          "&endDate=${endDate!.toIso8601String()}"
          "&selectedDays=${daysList.join("&selectedDays=")}");
          debugPrint("--> [Primary Schooler Info] Visiting web address: $url");

      final response = await http.get(url);
      debugPrint("<-- [Primary Schooler Info] Server responded with Status Code: ${response.statusCode}");
      debugPrint("<-- [Primary Schooler Info] Raw JSON data received: ${response.body}");
      if (response.statusCode == 200) {
        previewResult = jsonDecode(response.body);
      } else {
        previewResult = null;
      }
    } catch (e) {
      debugPrint("Preview error: $e");
      previewResult = null;
    }
  }

  // Checkboxes
  bool isGraded = false;
  bool isFileRequired = false;

  // State
  bool isLoading = false;
  List<Map<String, dynamic>> availableCriteria = [];
  List<int> selectedParameterIds = [];

  void toggleDay(int index) {
    selectedDays[index] = !selectedDays[index];
  }

  // 2. Fetch Available Criteria — filtered by FYP type
  Future<void> fetchAvailableCriteria(String fypType) async {
    int? sessionId = await _getCurrentSessionId();
    if (sessionId == null) return;

    // Route to fyp1-scores or fyp2-scores based on the meeting type
    String scoreBase = (fypType == "FYP-2") ? "fyp2-scores" : "fyp1-scores";
    try {
      final url = Uri.parse("${ApiConfig.baseUrl}/$scoreBase/available-criteria/$sessionId");
      debugPrint("--> [Primary Schooler Info] Visiting web address: $url");
      final response = await http.get(url);
      debugPrint("<-- [Primary Schooler Info] Server responded with Status Code: ${response.statusCode}");
      debugPrint("<-- [Primary Schooler Info] Raw JSON data received: ${response.body}");
      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        availableCriteria = data.map((e) => e as Map<String, dynamic>).toList();
      }
    } catch (e) {
      debugPrint("Error fetching criteria: $e");
    }
  }

  // 3. Assign Parameters to Meeting
  Future<bool> assignParameters(int meetingId) async {
    if (selectedParameterIds.isEmpty) return true;

    try {
      final url = Uri.parse("${ApiConfig.baseUrl}/fyp1-scores/assign-parameters-to-meeting");
      debugPrint("--> [Primary Schooler Info] Visiting web address: $url");
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "MeetingId": meetingId,
          "ParameterIds": selectedParameterIds
        }),
      );
      debugPrint("<-- [Primary Schooler Info] Server responded with Status Code: ${response.statusCode}");
      debugPrint("<-- [Primary Schooler Info] Raw JSON data received: ${response.body}");
      return response.statusCode == 200;
    } catch (e) {
      debugPrint("Error assigning parameters: $e");
      return false;
    }
  }

  // Gets the Current Session ID from the Database
  Future<int?> _getCurrentSessionId() async {
    try {
      final url = Uri.parse("${ApiConfig.baseUrl}/users/CurrentSession");
      debugPrint("--> [Primary Schooler Info] Visiting web address: $url");
      final response = await http.get(url);
      debugPrint("<-- [Primary Schooler Info] Server responded with Status Code: ${response.statusCode}");
      debugPrint("<-- [Primary Schooler Info] Raw JSON data received: ${response.body}");
      if (response.statusCode == 200) {
        return jsonDecode(response.body)['id'];
      }
    } catch (e) {
      debugPrint("Error fetching session: $e");
    }
    return null;
  }

  // Format TimeOfDay to C# TimeSpan format (HH:mm:ss)
  String _formatTimeSpan(TimeOfDay time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return "$h:$m:00";
  }

  // Calls the [HttpPost] schedule-meeting API
  Future<Map<String, dynamic>?> scheduleMeeting(String type, BuildContext context, String userId) async {
    // 1. Validate Fields
    if (title.isEmpty || startDate == null || endDate == null || startTime == null || endTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please fill all required date, time, and title fields.")));
      return null;
    }

    // 2. Extract selected days
    List<String> daysList = [];
    for (int i = 0; i < selectedDays.length; i++) {
      if (selectedDays[i]) daysList.add(dayLabels[i]);
    }

    if (daysList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select at least one recurrence day.")));
      return null;
    }

    // 3. Get Session ID
    int? sessionId = await _getCurrentSessionId();
    if (sessionId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to fetch current session. Cannot create meeting.")));
      return null;
    }

    // 4. Send Request to API
    try {
      // ---> THE FIX IS HERE: Pointing to the committee-meetings controller <---
      final url = Uri.parse("${ApiConfig.baseUrl}/committee-meetings/schedule-meeting?type=${Uri.encodeComponent(type)}&userId=${Uri.encodeComponent(userId)}");
      debugPrint("--> [Primary Schooler Info] Visiting web address: $url");

      final body = jsonEncode({
        "title": title,
        "meetingDescription": description,
        "startDate": startDate!.toIso8601String(),
        "endDate": endDate!.toIso8601String(),
        "startTime": _formatTimeSpan(startTime!),
        "endTime": _formatTimeSpan(endTime!),
        "venue": location,
        "selectedDays": daysList,
        "sessionID": sessionId,
        "isGraded": isGraded,
        "isFileRequired": isFileRequired
      });

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: body,
      );
      debugPrint("<-- [Primary Schooler Info] Server responded with Status Code: ${response.statusCode}");
      debugPrint("<-- [Primary Schooler Info] Raw JSON data received: ${response.body}");

      if (response.statusCode == 200) {
        final respBody = jsonDecode(response.body);
        int meetingId = respBody['meetingId'];
        
        // If graded, assign parameters
        if (isGraded) {
          await assignParameters(meetingId);
        }
        
        return respBody;
      } else {
        debugPrint("Error Response: ${response.body}");
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to schedule: ${response.body}")));
        return null;
      }
    } catch (e) {
      debugPrint("Exception scheduling meeting: $e");
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Network Error. Ensure backend is running.")));
      return null;
    }
  }
}