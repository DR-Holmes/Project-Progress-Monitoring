import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../api_config.dart';

class CommitteeHeadMeetingScheduleViewModel {
  final String _base = "${ApiConfig.baseUrl}/committee-meetings";
  final String _apiBase = ApiConfig.baseUrl;

  // Form fields
  String title = "";
  String description = "";
  String location = "";
  DateTime? startDate;
  DateTime? endDate;
  TimeOfDay? startTime;
  TimeOfDay? endTime;

  bool isGraded = false;
  bool isFileRequired = false;
  bool isLoading = false;
  bool isCriteriaLoading = false;

  // Day selection
  List<bool> selectedDays = List.filled(7, false);
  final List<String> dayLabels = ["mon", "tue", "wed", "thu", "fri", "sat", "sun"];

  // Criteria
  List<Map<String, dynamic>> availableCriteria = [];
  List<int> selectedParameterIds = [];

  void toggleDay(int index) {
    selectedDays[index] = !selectedDays[index];
  }

  // Get current session ID
  Future<int?> _getSessionId() async {
    try {
      final response = await http.get(Uri.parse("$_apiBase/users/CurrentSession"));
      debugPrint("<-- [Primary Schooler Info] Server responded with Status Code: ${response.statusCode}");
      debugPrint("<-- [Primary Schooler Info] Raw JSON data received: ${response.body}");
      if (response.statusCode == 200) {
        return jsonDecode(response.body)['id'];
      }
    } catch (e) {
      debugPrint("Session error: $e");
    }
    return null;
  }

  // Fetch criteria filtered by FYP type
  Future<void> fetchAvailableCriteria(String fypType) async {
    isCriteriaLoading = true;
    try {
      int? sessionId = await _getSessionId();
      if (sessionId == null) return;

      String scoreBase = (fypType == "FYP-2") ? "fyp2-scores" : "fyp1-scores";
      final url = Uri.parse("$_apiBase/$scoreBase/available-criteria/$sessionId");
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
    isCriteriaLoading = false;
  }

  // Assign selected parameters to the created meeting
  Future<bool> assignParameters(int meetingId, String fypType) async {
    if (selectedParameterIds.isEmpty) return true;
    try {
      String scoreBase = (fypType == "FYP-2") ? "fyp2-scores" : "fyp1-scores";
      final url = Uri.parse("$_apiBase/$scoreBase/assign-parameters-to-meeting");
      debugPrint("--> [Primary Schooler Info] Visiting web address: $url");
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "MeetingId": meetingId,
          "ParameterIds": selectedParameterIds,
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

  // Schedule the meeting and assign parameters if graded
  Future<bool> scheduleMeeting(String fypType, BuildContext context) async {
    if (title.isEmpty || startDate == null || endDate == null ||
        startTime == null || endTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all required fields")),
      );
      return false;
    }

    List<String> activeDays = [];
    for (int i = 0; i < selectedDays.length; i++) {
      if (selectedDays[i]) activeDays.add(dayLabels[i]);
    }
    if (activeDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Select at least one recurrence day")),
      );
      return false;
    }

    int? sessionId = await _getSessionId();
    if (sessionId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Could not fetch current session")),
      );
      return false;
    }

    try {
      String startT = "${startTime!.hour.toString().padLeft(2, '0')}:${startTime!.minute.toString().padLeft(2, '0')}:00";
      String endT = "${endTime!.hour.toString().padLeft(2, '0')}:${endTime!.minute.toString().padLeft(2, '0')}:00";

      final payload = {
        "title": title,
        "meetingDescription": description,
        "venue": location,
        "startDate": startDate!.toIso8601String(),
        "endDate": endDate!.toIso8601String(),
        "startTime": startT,
        "endTime": endT,
        "selectedDays": activeDays,
        "sessionID": sessionId,
        "isGraded": isGraded,
        "isFileRequired": isFileRequired,
      };

      final url = Uri.parse("$_base/schedule-meeting?type=${Uri.encodeComponent(fypType)}");
      debugPrint("--> [Primary Schooler Info] Visiting web address: $url");
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(payload),
      );
      debugPrint("<-- [Primary Schooler Info] Server responded with Status Code: ${response.statusCode}");
      debugPrint("<-- [Primary Schooler Info] Raw JSON data received: ${response.body}");

      if (response.statusCode == 200) {
        // If graded and parameters selected, assign them
        if (isGraded && selectedParameterIds.isNotEmpty && response.body.isNotEmpty) {
          try {
            final respBody = jsonDecode(response.body);
            int meetingId = respBody['meetingId'] ?? 0;
            if (meetingId > 0) {
              await assignParameters(meetingId, fypType);
            }
          } catch (e) {
            debugPrint("Could not parse meetingId: $e");
          }
        }
        return true;
      } else {
        debugPrint("Schedule error: ${response.body}");
        return false;
      }
    } catch (e) {
      debugPrint("Scheduling exception: $e");
      return false;
    }
  }
}