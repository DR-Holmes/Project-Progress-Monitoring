import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../api_config.dart';

// PRIMARY SCHOOLER NOTE: This is the brain file that creates a new Group.
class CreateGroupViewModel {

  // MATCHES C#: [HttpGet] Route("StudentByTech/{techName}/{regNum}")
  Future<List<Map<String, dynamic>>?> othertechstudentapi(String technology, String myRegNum) async {
    final url = Uri.parse("${ApiConfig.baseUrl}/users/StudentByTech/$technology/$myRegNum");
    debugPrint("--> [Primary Schooler Info] Visiting web address: $url");

    try {
      final response = await http.get(url);
      debugPrint("<-- [Primary Schooler Info] Server responded with Status Code: ${response.statusCode}");
      debugPrint("<-- [Primary Schooler Info] Raw JSON data received: ${response.body}");
      
      if (response.statusCode == 200) {
        final List<dynamic> students = jsonDecode(response.body);
        return students.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      print("Search Student Error: $e");
    }
    return null;
  }

  // MATCHES C#: [HttpGet] Route("getAllDepartments")
  Future<List<Map<String, dynamic>>?> getDepartments() async {
    final url = Uri.parse("${ApiConfig.baseUrl}/users/getAllDepartments");
    debugPrint("--> [Primary Schooler Info] Visiting web address: $url");

    try {
      final response = await http.get(url);
      debugPrint("<-- [Primary Schooler Info] Server responded with Status Code: ${response.statusCode}");
      debugPrint("<-- [Primary Schooler Info] Raw JSON data received: ${response.body}");
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      print("Get Dept Error: $e");
    }
    return null;
  }

  // MATCHES C#: [HttpPost] Route("CreateGroup")
  Future<bool> createGroupApi(String regNum, int sessionId) async {
    final url = Uri.parse("${ApiConfig.baseUrl}/users/CreateGroup");
    debugPrint("--> [Primary Schooler Info] Visiting web address: $url");

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "createdBy": regNum,
          "supervisorID": "Pending", // Default/Placeholder as per common logic
          "projectID": 0,            // Default
          "isFinalized": 0,
          "createdSession": sessionId
        }),
      );
      debugPrint("<-- [Primary Schooler Info] Server responded with Status Code: ${response.statusCode}");
      debugPrint("<-- [Primary Schooler Info] Raw JSON data received: ${response.body}");
      
      return response.statusCode == 200;
    } catch (e) {
      print("Create Group Error: $e");
      return false;
    }
  }
}