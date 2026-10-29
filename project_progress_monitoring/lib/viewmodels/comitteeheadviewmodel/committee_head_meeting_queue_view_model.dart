import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../api_config.dart';

class CommitteeHeadMeetingQueueViewModel {
  final String _baseUrl = ApiConfig.baseUrl;

  // 1. Fetch meetings based on FYP-1 or FYP-2
  Future<List<Map<String, dynamic>>> fetchMeetings(String activeFYP) async {
    try {
      final response = await http.get(Uri.parse("$_baseUrl/committee-meetings/today-meetings/$activeFYP"));
      debugPrint("<-- [Primary Schooler Info] Server responded with Status Code: ${response.statusCode}");
      debugPrint("<-- [Primary Schooler Info] Raw JSON data received: ${response.body}");

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        return data.map((e) => e as Map<String, dynamic>).toList();
      }
    } catch (e) {
      debugPrint("Error fetching meetings: $e");
    }
    return [];
  }

  // 2. Fetch specific meeting details
  Future<Map<String, dynamic>?> fetchMeetingInfo(int meetingId) async {
    try {
      final meetingResp = await http.get(Uri.parse("$_baseUrl/committee-meetings/meetings/$meetingId"));
      if (meetingResp.statusCode == 200) {
        List<dynamic> data = jsonDecode(meetingResp.body);
        if (data.isNotEmpty) return data[0] as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint("Error fetching meeting info: $e");
    }
    return null;
  }

  // 3. Fetch group students for meeting
  Future<List<Map<String, dynamic>>> fetchSpecificGroup(int groupId) async {
    try {
      final response = await http.get(Uri.parse("$_baseUrl/committee-meetings/getSpecificGroup/$groupId"));
      debugPrint("<-- [Primary Schooler Info] Server responded with Status Code: ${response.statusCode}");
      debugPrint("<-- [Primary Schooler Info] Raw JSON data received: ${response.body}");
      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        return data.map((e) => e as Map<String, dynamic>).toList();
      }
    } catch (e) {
      debugPrint("Error fetching specific group: $e");
    }
    return [];
  }

  // 4. Check Project Allocation
  Future<bool> checkProjectAllocation(int groupId) async {
    try {
      final response = await http.get(Uri.parse("$_baseUrl/committee-meetings/IsProjectAllocate/$groupId"));
      debugPrint("<-- [Primary Schooler Info] Server responded with Status Code: ${response.statusCode}");
      debugPrint("<-- [Primary Schooler Info] Raw JSON data received: ${response.body}");
      if (response.statusCode == 200) {
        return jsonDecode(response.body) == true;
      }
    } catch (e) {
      debugPrint("Error checking project allocation: $e");
    }
    return false;
  }

  // 5. Check Supervisor Allocation
  Future<bool> checkSupervisorAllocation(int groupId) async {
    try {
      final response = await http.get(Uri.parse("$_baseUrl/committee-meetings/IsSupervisorAllocate/$groupId"));
      debugPrint("<-- [Primary Schooler Info] Server responded with Status Code: ${response.statusCode}");
      debugPrint("<-- [Primary Schooler Info] Raw JSON data received: ${response.body}");
      if (response.statusCode == 200) {
        return jsonDecode(response.body) == true;
      }
    } catch (e) {
      debugPrint("Error checking supervisor allocation: $e");
    }
    return false;
  }

  // 6. Fetch Evaluation Parameters
  Future<List<Map<String, dynamic>>> fetchEvaluationParameters(int meetingId, String activeFYP) async {
    try {
      final response = await http.get(Uri.parse("$_baseUrl/committee-meetings/evaluation-parameters/$meetingId/$activeFYP"));
      debugPrint("<-- [Primary Schooler Info] Server responded with Status Code: ${response.statusCode}");
      debugPrint("<-- [Primary Schooler Info] Raw JSON data received: ${response.body}");
      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        return data.map((e) => e as Map<String, dynamic>).toList();
      }
    } catch (e) {
      debugPrint("Error fetching evaluation parameters: $e");
    }
    return [];
  }

  // 7. Fetch remarks for a student
  Future<List<Map<String, dynamic>>> fetchRemarks(int studentEnrollID, String evaluatorID, int sessionID) async {
    try {
      final response = await http.get(Uri.parse("$_baseUrl/fyp1-scores/get-remarks/$studentEnrollID/$evaluatorID/$sessionID"));
      debugPrint("<-- [Primary Schooler Info] Server responded with Status Code: ${response.statusCode}");
      debugPrint("<-- [Primary Schooler Info] Raw JSON data received: ${response.body}");
      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        return data.map((e) => e as Map<String, dynamic>).toList();
      }
    } catch (e) {
      debugPrint("Error fetching remarks: $e");
    }
    return [];
  }

  // 8. Save or Update Remark
  Future<bool> saveStudentRemark(Map<String, dynamic> payload) async {
    try {
      final response = await http.post(
        Uri.parse("$_baseUrl/fyp1-scores/save"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(payload),
      );
      debugPrint("<-- [Primary Schooler Info] Server responded with Status Code: ${response.statusCode}");
      debugPrint("<-- [Primary Schooler Info] Raw JSON data received: ${response.body}");
      return response.statusCode == 200;
    } catch (e) {
      debugPrint("Error saving remark: $e");
      return false;
    }
  }

  // 9. Auto-Sync meeting times globally
  Future<bool> updateMeetingTimesDynamic() async {
    try {
      final response = await http.post(
        Uri.parse("$_baseUrl/committee-meetings/update-meeting-times-dynamic"),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint("Error auto-syncing times: $e");
      return false;
    }
  }

  // 10. Handle Delay (Merge / New)
  Future<bool> handleDelay(Map<String, dynamic> payload) async {
    try {
      final response = await http.post(
        Uri.parse("$_baseUrl/committee-meetings/handle-delay"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(payload),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint("Error handling delay: $e");
      return false;
    }
  }

  // 11. Reschedule Group/Student
  Future<bool> rescheduleMeeting(Map<String, dynamic> payload) async {
    try {
      final response = await http.post(
        Uri.parse("$_baseUrl/committee-meetings/reschedule-meeting"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(payload),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint("Error rescheduling: $e");
      return false;
    }
  }

  // 12. Update (Edit) Meeting
  Future<bool> updateMeeting(int meetingId, String fypType, Map<String, dynamic> payload) async {
    try {
      final response = await http.put(
        Uri.parse("$_baseUrl/committee-meetings/$meetingId?type=$fypType&userId=HEAD-001"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(payload),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint("Error editing meeting: $e");
      return false;
    }
  }

  // 13. Delete Meeting
  Future<bool> deleteMeeting(int meetingId) async {
    try {
      final response = await http.delete(
        Uri.parse("$_baseUrl/committee-meetings/$meetingId"),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint("Error deleting meeting: $e");
      return false;
    }
  }
}