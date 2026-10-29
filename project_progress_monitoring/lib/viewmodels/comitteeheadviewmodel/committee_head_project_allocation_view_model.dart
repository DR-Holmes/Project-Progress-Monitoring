import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../api_config.dart';

// ---------------------------------------------------------
// WHAT IS THIS FILE?
// This is the "Brain" (ViewModel) for the Committee Head's Project Allocation screen.
// It matches the Committee Member's ViewModel to maintain complete functional parity.
// ---------------------------------------------------------

class CommitteeHeadProjectAllocationViewModel {
  List<dynamic> groups = [];
  List<dynamic> projects = [];
  List<dynamic> groupMembers = [];

  String? selectedGroupId;
  String? selectedProjectId;
  String? selectedProjectTitle;

  bool isLoading = false;
  bool isMembersLoading = false;
  bool isSubmitting = false;

  // Fetches enrolled student groups
  Future<void> fetchEnrolledGroups(String fypType) async {
    try {
      final url = Uri.parse("${ApiConfig.baseUrl}/committee-meetings/groups/approved/$fypType");
      debugPrint("--> [Committee Head] Loading enrolled groups list: $url");
      
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        // Filter: Only include groups that have NOT been allocated a project yet
        groups = data.where((g) => g['projectID'] == null && (g['projectTitle'] == null || g['projectTitle'].toString().trim().isEmpty)).toList();
      } else {
        groups = [];
      }
    } catch (e) {
      debugPrint("!!! [Committee Head Error] Failed to fetch enrolled groups: $e");
      groups = [];
    }
  }

  // Fetches available projects
  Future<void> fetchOfferedProjects() async {
    try {
      final url = Uri.parse("${ApiConfig.baseUrl}/committee-meetings/getAllOfferedProjects");
      debugPrint("--> [Committee Head] Loading offered projects: $url");

      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        projects = data;
      } else {
        projects = [];
      }
    } catch (e) {
      debugPrint("!!! [Committee Head Error] Failed to fetch offered projects: $e");
      projects = [];
    }
  }

  // Fetches student details of group members
  Future<void> fetchSpecificGroupMembers(String groupId) async {
    isMembersLoading = true;
    try {
      final url = Uri.parse("${ApiConfig.baseUrl}/committee-meetings/getSpecificGroup/$groupId");
      debugPrint("--> [Committee Head] Loading student members for group $groupId: $url");

      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        groupMembers = data;
      } else {
        groupMembers = [];
      }
    } catch (e) {
      debugPrint("!!! [Committee Head Error] Failed to load specific group members: $e");
      groupMembers = [];
    }
    isMembersLoading = false;
  }

  // Allocates project using PUT
  Future<bool> allocateProjectToGroup(String groupId, int projectId) async {
    isSubmitting = true;
    try {
      final url = Uri.parse("${ApiConfig.baseUrl}/committee-meetings/allocateProject");
      debugPrint("--> [Committee Head] Allocating Project $projectId to Group $groupId...");

      final body = json.encode({
        "groupId": int.tryParse(groupId) ?? 0,
        "projectId": projectId,
      });

      final response = await http.put(
        url,
        headers: {"Content-Type": "application/json"},
        body: body,
      );

      isSubmitting = false;
      return response.statusCode == 200;
    } catch (e) {
      debugPrint("!!! [Committee Head Error] Project allocation failed: $e");
      isSubmitting = false;
      return false;
    }
  }
}
