import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../api_config.dart';

class ScheduleMeetingViewModel {
  List<dynamic> groups = [];
  bool isLoadingGroups = false;
  bool isSaving = false;

  List<dynamic> students = [];
  bool isLoadingStudents = false;

  /// 🏫 SCHOOL LESSON: How we get the list of Groups!
  /// We ask the computer to wait while we talk to the internet (async).
  /// We send the Supervisor's ID and if it's FYP-1 or FYP-2.
  Future<void> fetchGroupsForDropdown(String supervisorId, String fypType) async {
    // 1. Show the "Spinning Wheel" (Loading)
    isLoadingGroups = true;
    groups = [];
    try {
      // 2. The exact "Home Address" (URL) of the data on the server
      final url = Uri.parse("${ApiConfig.baseUrl}/supervisor/getAllGroups/$fypType/$supervisorId");
      debugPrint("--> [Primary Schooler Info] Visiting web address: $url");
      
      // 3. Knock on the door and wait for a response
      final response = await http.get(url);
      debugPrint("<-- [Primary Schooler Info] Server responded with Status Code: ${response.statusCode}");
      debugPrint("<-- [Primary Schooler Info] Raw JSON data received: ${response.body}");
      
      // 4. If the door opens (200 OK), turn the secret computer language (JSON) into a List we can use!
      if (response.statusCode == 200) {
        groups = jsonDecode(response.body);
      }
    } catch (e) {
      // 5. If something breaks, tell us why!
      debugPrint("API Error (fetchGroups): $e");
    } finally {
      // 6. Stop the "Spinning Wheel" no matter what
      isLoadingGroups = false;
    }
  }

  /// 🏫 SCHOOL LESSON: How we get the list of Students in a group!
  /// This only happens if you pick "Individual" mode.
  Future<void> fetchGroupStudents(int groupId) async {
    isLoadingStudents = true;
    students = [];
    try {
      final url = Uri.parse("${ApiConfig.baseUrl}/supervisor/GetGroupStudents/$groupId");
      debugPrint("--> [Primary Schooler Info] Visiting web address: $url");
      final response = await http.get(url);
      debugPrint("<-- [Primary Schooler Info] Server responded with Status Code: ${response.statusCode}");
      debugPrint("<-- [Primary Schooler Info] Raw JSON data received: ${response.body}");
      if (response.statusCode == 200) {
        students = jsonDecode(response.body);
      }
    } catch (e) {
      debugPrint("API Error (fetchStudents): $e");
    } finally {
      isLoadingStudents = false;
    }
  }

  /// 🏫 SCHOOL LESSON: How we Save the Meeting!
  /// We take all the info from the form and send it to the server in a package.
  Future<Map<String, dynamic>> scheduleMeeting(Map<String, dynamic> meetingData) async {
    isSaving = true;
    try {
      final url = Uri.parse("${ApiConfig.baseUrl}/supervisor/schedule-meeting");
      debugPrint("--> [Primary Schooler Info] Visiting web address: $url");

      // We send the package (jsonEncode) to the server
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(meetingData),
      );
      debugPrint("<-- [Primary Schooler Info] Server responded with Status Code: ${response.statusCode}");
      debugPrint("<-- [Primary Schooler Info] Raw JSON data received: ${response.body}");

      isSaving = false;
      if (response.statusCode == 200) {
        // High five! It worked!
        return {'success': true, 'message': 'Meeting Scheduled Successfully!'};
      } else {
        // Oh no, something went wrong on the server
        return {'success': false, 'message': 'Failed to schedule meeting.'};
      }
    } catch (e) {
      isSaving = false;
      return {'success': false, 'message': 'Error: $e'};
    }
  }
}