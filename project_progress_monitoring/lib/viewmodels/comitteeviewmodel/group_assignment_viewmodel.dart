import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import '../../api_config.dart';

class GroupAssignmentViewModel {
  // 🏫 SCHOOL LESSON: isLoading tells the UI when to show a spinner!
  bool isLoading = false;

  /// 🏫 SCHOOL LESSON: Fetch groups that are eligible for this student's technology!
  /// We call the API: /committee-meetings/EligibleGroups/{regNum}
  Future<List<Map<String, dynamic>>> fetchEligibleGroups(String regNum) async {
    isLoading = true;
    try {
      final url = Uri.parse("${ApiConfig.baseUrl}/committee-meetings/EligibleGroups/$regNum");
      debugPrint("--> [Primary Schooler Info] Visiting web address: $url");
      final response = await http.get(url);
      debugPrint("<-- [Primary Schooler Info] Server responded with Status Code: ${response.statusCode}");
      debugPrint("<-- [Primary Schooler Info] Raw JSON data received: ${response.body}");

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data.map((g) => g as Map<String, dynamic>).toList();
      }
      return [];
    } catch (e) {
      debugPrint("🏫 Error fetching eligible groups: $e");
      return [];
    } finally {
      isLoading = false;
    }
  }

  /// 🏫 SCHOOL LESSON: Add a student to an existing group!
  /// We call the API: /committee-meetings/AddStudentToGroup?groupId={id}&regNum={reg}
  Future<bool> addStudentToGroup(int groupId, String regNum) async {
    try {
      final url = Uri.parse(
          "${ApiConfig.baseUrl}/committee-meetings/AddStudentToGroup?groupId=$groupId&regNum=$regNum");
          debugPrint("--> [Primary Schooler Info] Visiting web address: $url");
      final response = await http.post(url);
      debugPrint("<-- [Primary Schooler Info] Server responded with Status Code: ${response.statusCode}");
      debugPrint("<-- [Primary Schooler Info] Raw JSON data received: ${response.body}");

      // Return true if success
      return response.statusCode == 200;
    } catch (e) {
      debugPrint("🏫 Error adding student: $e");
      return false;
    }
  }

  /// 🏫 SCHOOL LESSON: Create a completely new group and add the student as Admin!
  /// We call the API: /users/CreateGroup
  Future<bool> createGroup(String regNum, int sessionId) async {
    try {
      final url = Uri.parse("${ApiConfig.baseUrl}/users/CreateGroup");
      debugPrint("--> [Primary Schooler Info] Visiting web address: $url");
      
      // The payload matches the ProjectGroup model in C#
      final payload = {
        'createdBy': regNum,
        'supervisorID': null,
        'projectID': null,
        'isFinalized': 0,
        'createdSession': sessionId
      };

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: json.encode(payload),
      );
      debugPrint("<-- [Primary Schooler Info] Server responded with Status Code: ${response.statusCode}");
      debugPrint("<-- [Primary Schooler Info] Raw JSON data received: ${response.body}");

      return response.statusCode == 200;
    } catch (e) {
      debugPrint("🏫 Error creating group: $e");
      return false;
    }
  }
}