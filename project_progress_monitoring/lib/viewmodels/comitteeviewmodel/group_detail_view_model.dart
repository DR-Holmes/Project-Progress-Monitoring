import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import '../../api_config.dart';

class GroupDetailViewModel {
  bool isLoading = false;
  Map<String, dynamic> groupData = {};
  List<Map<String, dynamic>> eligibleStudents = [];
  List<Map<String, dynamic>> allTechnologies = [];

  /// 🏫 SCHOOL LESSON: Fetch all group details like members, supervisor, and project title.
  Future<void> fetchGroupDetails(int groupId) async {
    isLoading = true;
    try {
      final response = await http.get(Uri.parse("${ApiConfig.baseUrl}/committee-meetings/groups-details/$groupId"));
      debugPrint("<-- [Primary Schooler Info] Server responded with Status Code: ${response.statusCode}");
      debugPrint("<-- [Primary Schooler Info] Raw JSON data received: ${response.body}");
      if (response.statusCode == 200) {
        groupData = json.decode(response.body);
      }
    } catch (e) {
      debugPrint("🏫 Error fetching group details: $e");
    } finally {
      isLoading = false;
    }
  }

  /// 🏫 SCHOOL LESSON: Fetch students who can be added to this group (different technology).
  Future<void> fetchEligibleStudents(int groupId) async {
    try {
      final response = await http.get(Uri.parse("${ApiConfig.baseUrl}/committee-meetings/StudentByGroup/$groupId"));
      debugPrint("<-- [Primary Schooler Info] Server responded with Status Code: ${response.statusCode}");
      debugPrint("<-- [Primary Schooler Info] Raw JSON data received: ${response.body}");
      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        eligibleStudents = data.map((s) => s as Map<String, dynamic>).toList();
      }
    } catch (e) {
      debugPrint("🏫 Error fetching eligible students: $e");
    }
  }

  /// 🏫 SCHOOL LESSON: Fetch all available technologies from the DB.
  Future<void> fetchTechnologies() async {
    try {
      final response = await http.get(Uri.parse("${ApiConfig.baseUrl}/users/allTech"));
      debugPrint("<-- [Primary Schooler Info] Server responded with Status Code: ${response.statusCode}");
      debugPrint("<-- [Primary Schooler Info] Raw JSON data received: ${response.body}");
      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        allTechnologies = data.map((t) => t as Map<String, dynamic>).toList();
      }
    } catch (e) {
      debugPrint("🏫 Error fetching technologies: $e");
    }
  }

  /// 🏫 SCHOOL LESSON: Add a student to a group via API.
  Future<bool> addStudentToGroup(int groupId, String regNum) async {
    try {
      final response = await http.post(
        Uri.parse("${ApiConfig.baseUrl}/committee-meetings/AddStudentToGroup?groupId=$groupId&regNum=$regNum"),
      );
      debugPrint("<-- [Primary Schooler Info] Server responded with Status Code: ${response.statusCode}");
      debugPrint("<-- [Primary Schooler Info] Raw JSON data received: ${response.body}");
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// 🏫 SCHOOL LESSON: Remove a member from a group.
  Future<bool> removeMember(int groupId, String regNum) async {
    try {
      final response = await http.delete(
        Uri.parse("${ApiConfig.baseUrl}/users/RemoveGroupMember"),
        headers: {"Content-Type": "application/json"},
        body: json.encode({"GroupId": groupId, "MemberRegNum": regNum}),
      );
      debugPrint("<-- [Primary Schooler Info] Server responded with Status Code: ${response.statusCode}");
      debugPrint("<-- [Primary Schooler Info] Raw JSON data received: ${response.body}");
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// 🏫 SCHOOL LESSON: Update technologies for all students in a group.
  Future<bool> saveTechnologies(int groupId, List<Map<String, dynamic>> members) async {
    try {
      final body = {
        "Students": members.map((m) => {
          "RegNum": m['RegNum'],
          "TechnologyId": m['TechnologyId'],
        }).toList()
      };
      final response = await http.post(
        Uri.parse("${ApiConfig.baseUrl}/students/update-technologies/$groupId"),
        headers: {"Content-Type": "application/json"},
        body: json.encode(body),
      );
      debugPrint("<-- [Primary Schooler Info] Server responded with Status Code: ${response.statusCode}");
      debugPrint("<-- [Primary Schooler Info] Raw JSON data received: ${response.body}");
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}