import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import '../../api_config.dart';

class AssignTaskViewModel {


  // 🏫 SCHOOL LESSON: Fetch groups that belong to the supervisor!
  Future<List<dynamic>> fetchGroups(String supervisorId, String fypType) async {
    try {
      final response = await http.get(
          Uri.parse("${ApiConfig.baseUrl}/supervisor/GetSupervisorGroups/$supervisorId/$fypType")
      );
      debugPrint("<-- [Primary Schooler Info] Server responded with Status Code: ${response.statusCode}");
      debugPrint("<-- [Primary Schooler Info] Raw JSON data received: ${response.body}");
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return [];
    } catch (e) {
      debugPrint("API Error: $e");
      return [];
    }
  }

  // 🏫 SCHOOL LESSON: Fetch all students in a specific group!
  Future<List<dynamic>> fetchGroupMembers(int groupId) async {
    try {
      final response = await http.get(
          Uri.parse("${ApiConfig.baseUrl}/supervisor/GetGroupStudents/$groupId")
      );
      debugPrint("<-- [Primary Schooler Info] Server responded with Status Code: ${response.statusCode}");
      debugPrint("<-- [Primary Schooler Info] Raw JSON data received: ${response.body}");
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return [];
    } catch (e) {
      debugPrint("API Error: $e");
      return [];
    }
  }

  // 🏫 SCHOOL LESSON: Fetch supervisor meetings to help fill in task details!
  Future<List<dynamic>> fetchMeetings(String supervisorId, String fypType) async {
    try {
      final response = await http.get(
          Uri.parse("${ApiConfig.baseUrl}/supervisor/getSupervisorMeetings/$supervisorId/$fypType")
      );
      debugPrint("<-- [Primary Schooler Info] Server responded with Status Code: ${response.statusCode}");
      debugPrint("<-- [Primary Schooler Info] Raw JSON data received: ${response.body}");
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return [];
    } catch (e) {
      debugPrint("API Error: $e");
      return [];
    }
  }

  // 🏫 SCHOOL LESSON: Sending the final "Task Package" to the server!
  Future<bool> submitTask(Map<String, dynamic> taskData) async {
    try {
      final response = await http.post(
        Uri.parse("${ApiConfig.baseUrl}/supervisor/assign-task"),
        headers: {"Content-Type": "application/json"},
        body: json.encode(taskData),
      );
      debugPrint("<-- [Primary Schooler Info] Server responded with Status Code: ${response.statusCode}");
      debugPrint("<-- [Primary Schooler Info] Raw JSON data received: ${response.body}");
      return response.statusCode == 200;
    } catch (e) {
      debugPrint("API Error: $e");
      return false;
    }
  }
}