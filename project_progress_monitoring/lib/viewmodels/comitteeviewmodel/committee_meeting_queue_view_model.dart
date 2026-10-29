import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../api_config.dart';

// ---------------------------------------------------------
// WHAT IS THIS FILE?
// This is the "Brain" (ViewModel) for the Committee Meeting Queue.
// It handles:
// - Fetching today's meetings for a semester (FYP-1 / FYP-2).
// - Loading details of a tapped meeting (description, venue, times).
// - Loading schedule details to get dynamic presentation PPT file paths!
// - Loading group students using 'getDataForUpdateMarks' with dynamic API prefix (fyp1-scores / fyp2-scores).
// - Checking if Project and Supervisor are allocated to the group.
// - Loading evaluation criteria and checking if the meeting is graded.
// - Fetching student remarks with dynamic API prefix (fyp1-scores / fyp2-scores).
// - Submitting student remarks back to the server with dynamic API prefix.
// ---------------------------------------------------------

class CommitteeMeetingQueueViewModel {
  
  // 1. Lists and maps to hold our fetched data
  List<Map<String, dynamic>> meetings = [];
  List<Map<String, dynamic>> groupStudents = [];
  Map<String, dynamic>? selectedMeetingDetails;
  Map<String, dynamic>? scheduleDetails;
  
  // 2. Loading flags to show spinners while downloading from the internet
  bool isLoading = false;
  bool isDetailsLoading = false;
  
  // 3. Allocation status badges
  bool isProjectAllocated = false;
  bool isSupervisorAllocated = false;
  
  // 4. Evaluation panel configuration
  bool isGraded = false;
  List<Map<String, dynamic>> evaluationParams = [];

  // ---------------------------------------------------------
  // FUNCTION: fetchMeetings
  // Downloads today's scheduled meetings from the API for FYP-1 or FYP-2.
  // ---------------------------------------------------------
  Future<void> fetchMeetings(String fypType) async {
    isLoading = true;
    try {
      final url = Uri.parse("${ApiConfig.baseUrl}/committee-meetings/today-meetings/$fypType");
      debugPrint("--> [Primary Schooler] Loading meetings list from: $url");

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        meetings = data.map((e) => e as Map<String, dynamic>).toList();
        debugPrint("--> [Primary Schooler] Loaded ${meetings.length} meetings successfully!");
      } else {
        meetings = [];
      }
    } catch (e) {
      debugPrint("!!! [Primary Schooler Error] Fetching meetings failed: $e");
      meetings = [];
    }
    isLoading = false;
  }

  // ---------------------------------------------------------
  // FUNCTION: fetchMeetingDetails
  // Tapping a meeting downloads:
  // A. Meeting info (description, venue, days, hours)
  // B. Schedule details (for dynamic PPT file path)
  // C. Group members WITH EnrollmentID using dynamic fyp1-scores / fyp2-scores
  // D. Project allocation status
  // E. Supervisor allocation status
  // F. Evaluation parameter templates
  // ---------------------------------------------------------
  Future<void> fetchMeetingDetails(Map<String, dynamic> meeting, String activeFyp) async {
    isDetailsLoading = true;

    // Safely extract the IDs we need
    final int meetingId = meeting['id'] ?? meeting['meetingId'] ?? 0;
    final int groupId = meeting['GroupIDs'] ?? meeting['groupId'] ?? 0;
    final int scheduleId = meeting['scheduleId'] ?? meeting['ScheduleID'] ?? 0;

    final String scoreApi = activeFyp.toLowerCase() == "fyp-2" ? "fyp2-scores" : "fyp1-scores";

    try {
      debugPrint("--> [Primary Schooler] Fetching details for Meeting $meetingId, Group $groupId (API: $scoreApi)");

      // A. Get general meeting metadata (venue, days, times)
      final mRes = await http.get(Uri.parse("${ApiConfig.baseUrl}/committee-meetings/meetings/$meetingId"));
      if (mRes.statusCode == 200) {
        final List mData = json.decode(mRes.body);
        selectedMeetingDetails = mData.isNotEmpty ? mData[0] : null;
      }

      // B. Get schedule details for presentation PPT file path
      if (scheduleId > 0) {
        final scRes = await http.get(Uri.parse("${ApiConfig.baseUrl}/committee-meetings/schedule/$scheduleId"));
        if (scRes.statusCode == 200 && scRes.body.isNotEmpty) {
          try {
            scheduleDetails = json.decode(scRes.body) as Map<String, dynamic>;
          } catch (_) {
            scheduleDetails = null;
          }
        }
      } else {
        scheduleDetails = null;
      }

      // C. Get group students using dynamic scoreApi so we get correct EnrollmentIDs!
      final gRes = await http.get(Uri.parse("${ApiConfig.baseUrl}/$scoreApi/getDataForUpdateMarks/$groupId"));
      if (gRes.statusCode == 200) {
        final List gData = json.decode(gRes.body);
        groupStudents = gData.map((e) => e as Map<String, dynamic>).toList();
      }

      // D. Check if group has a project allocated
      final pRes = await http.get(Uri.parse("${ApiConfig.baseUrl}/committee-meetings/IsProjectAllocate/$groupId"));
      isProjectAllocated = pRes.body.toLowerCase() == "true";

      // E. Check if group has a supervisor allocated
      final sRes = await http.get(Uri.parse("${ApiConfig.baseUrl}/committee-meetings/IsSupervisorAllocate/$groupId"));
      isSupervisorAllocated = sRes.body.toLowerCase() == "true";

      // F. Load evaluation parameters for marks grading
      final eRes = await http.get(Uri.parse("${ApiConfig.baseUrl}/committee-meetings/evaluation-parameters/$meetingId/$activeFyp"));
      if (eRes.statusCode == 200) {
        final List eData = json.decode(eRes.body);
        evaluationParams = eData.map((e) => e as Map<String, dynamic>).toList();
        
        // Match meeting title to check if this specific card is graded
        final String title = (meeting['MeetingTitle'] ?? "").toString().toLowerCase().trim();
        final matched = evaluationParams.any((p) => 
          (p['ParameterName'] ?? "").toString().toLowerCase().trim() == title && 
          p['IsGraded'] == true
        );
        isGraded = matched;
      }

    } catch (e) {
      debugPrint("!!! [Primary Schooler Error] Fetching details failed: $e");
    }
    isDetailsLoading = false;
  }

  // ---------------------------------------------------------
  // FUNCTION: fetchStudentRemarks
  // Fetch existing remarks list using dynamic scoreApi, find current meeting, or fallback to latest.
  // ---------------------------------------------------------
  Future<String> fetchStudentRemarks(int enrollId, String userId, int sessionId, int selectedMeetingId, String activeFyp) async {
    final String scoreApi = activeFyp.toLowerCase() == "fyp-2" ? "fyp2-scores" : "fyp1-scores";
    try {
      final url = Uri.parse("${ApiConfig.baseUrl}/$scoreApi/get-remarks/$enrollId/$userId/$sessionId");
      debugPrint("--> [Primary Schooler] Loading remarks from: $url");
      final response = await http.get(url);

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final List data = json.decode(response.body);
        
        // 1. Try to find remark for the CURRENT meeting
        final currentRemark = data.firstWhere(
          (r) => r['meetingID'] == selectedMeetingId,
          orElse: () => null,
        );

        if (currentRemark != null) {
          return currentRemark['remarks'] ?? "";
        }

        // 2. Otherwise pick the LATEST remark based on date (updatedAt or createdAt)
        if (data.isNotEmpty) {
          data.sort((a, b) {
            final dateA = DateTime.tryParse(a['updatedAt'] ?? a['createdAt'] ?? "") ?? DateTime(1970);
            final dateB = DateTime.tryParse(b['updatedAt'] ?? b['createdAt'] ?? "") ?? DateTime(1970);
            return dateB.compareTo(dateA); // Newest first
          });
          return data[0]['remarks'] ?? "";
        }
      }
    } catch (e) {
      debugPrint("!!! [Primary Schooler Error] Remarks load failed: $e");
    }
    return "";
  }

  // ---------------------------------------------------------
  // FUNCTION: saveRemarks
  // Submits the typed remarks text for a student back to the database using dynamic scoreApi.
  // ---------------------------------------------------------
  Future<bool> saveRemarks(int enrollId, int meetingId, String evaluatorId, int sessionId, String text, String activeFyp) async {
    final String scoreApi = activeFyp.toLowerCase() == "fyp-2" ? "fyp2-scores" : "fyp1-scores";
    try {
      final url = Uri.parse("${ApiConfig.baseUrl}/$scoreApi/save-or-update");
      debugPrint("--> [Primary Schooler] Saving remark to: $url");

      final body = json.encode({
        "studentEnrollID": enrollId,
        "meetingID": meetingId,
        "evaluatorID": evaluatorId,
        "sessionID": sessionId,
        "remarks": text,
      });

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: body,
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint("!!! [Primary Schooler Error] Failed to save remarks: $e");
      return false;
    }
  }
}
