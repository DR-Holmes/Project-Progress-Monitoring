import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../api_config.dart';

// ---------------------------------------------------------
// WHAT IS THIS FILE?
// This is the "Brain" (ViewModel) for the Committee's Project Allocation screen.
// It handles:
// - Fetching all enrolled groups from the database for dropdown selection.
// - Fetching specific details of a selected group (student name, CGPA, technology).
// - Fetching all offered project ideas (from suggested projects session join).
// - Allocating a selected project to the group via a PUT API request.
// ---------------------------------------------------------

class ProjectAllocationViewModel {
  // 1. Lists to hold fetched data
  List<dynamic> groups = [];
  List<dynamic> projects = [];
  List<dynamic> groupMembers = [];

  // 2. Local variables to hold current selections
  String? selectedGroupId;
  String? selectedProjectId;
  String? selectedProjectTitle;

  // 3. Status flags for showing loaders
  bool isLoading = false;
  bool isMembersLoading = false;
  bool isSubmitting = false;

  // ---------------------------------------------------------
  // FUNCTION: fetchEnrolledGroups
  // Fetches a list of all enrolled groups for the dropdown.
  // ---------------------------------------------------------
  Future<void> fetchEnrolledGroups(String fypType) async {
    try {
      final url = Uri.parse("${ApiConfig.baseUrl}/committee-meetings/groups/approved/$fypType");
      debugPrint("--> [Primary Schooler] Loading enrolled groups list from: $url");
      
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        // Filter: Only include groups that have NOT been allocated a project yet
        groups = data.where((g) => g['projectID'] == null && (g['projectTitle'] == null || g['projectTitle'].toString().trim().isEmpty)).toList();
        debugPrint("--> [Primary Schooler] Loaded ${groups.length} unallocated groups successfully!");
      } else {
        groups = [];
      }
    } catch (e) {
      debugPrint("!!! [Primary Schooler Error] Failed to fetch enrolled groups: $e");
      groups = [];
    }
  }

  // ---------------------------------------------------------
  // FUNCTION: fetchOfferedProjects
  // Fetches all available projects from offered projects join list.
  // ---------------------------------------------------------
  Future<void> fetchOfferedProjects() async {
    try {
      final url = Uri.parse("${ApiConfig.baseUrl}/committee-meetings/getAllOfferedProjects");
      debugPrint("--> [Primary Schooler] Loading offered projects from: $url");

      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        projects = data;
        debugPrint("--> [Primary Schooler] Loaded ${projects.length} offered projects successfully!");
      } else {
        projects = [];
      }
    } catch (e) {
      debugPrint("!!! [Primary Schooler Error] Failed to fetch offered projects: $e");
      projects = [];
    }
  }

  // ---------------------------------------------------------
  // FUNCTION: fetchSpecificGroupMembers
  // Fetches students belonging to the specific group (CGPA, technology, name).
  // ---------------------------------------------------------
  Future<void> fetchSpecificGroupMembers(String groupId) async {
    isMembersLoading = true;
    try {
      final url = Uri.parse("${ApiConfig.baseUrl}/committee-meetings/getSpecificGroup/$groupId");
      debugPrint("--> [Primary Schooler] Loading student members for group $groupId from: $url");

      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        groupMembers = data;
        debugPrint("--> [Primary Schooler] Group members loaded: ${groupMembers.length} students.");
      } else {
        groupMembers = [];
      }
    } catch (e) {
      debugPrint("!!! [Primary Schooler Error] Failed to load specific group members: $e");
      groupMembers = [];
    }
    isMembersLoading = false;
  }

  // ---------------------------------------------------------
  // FUNCTION: allocateProjectToGroup
  // Submits the PUT request to allocate the selected project to the group.
  // ---------------------------------------------------------
  Future<bool> allocateProjectToGroup(String groupId, int projectId) async {
    isSubmitting = true;
    try {
      final url = Uri.parse("${ApiConfig.baseUrl}/committee-meetings/allocateProject");
      debugPrint("--> [Primary Schooler] Allocating Project $projectId to Group $groupId via PUT...");

      final body = json.encode({
        "groupId": int.tryParse(groupId) ?? 0,
        "projectId": projectId,
      });

      final response = await http.put(
        url,
        headers: {"Content-Type": "application/json"},
        body: body,
      );

      debugPrint("<-- [Primary Schooler Info] Allocate project API response status: ${response.statusCode}");
      isSubmitting = false;
      return response.statusCode == 200;
    } catch (e) {
      debugPrint("!!! [Primary Schooler Error] Project allocation failed: $e");
      isSubmitting = false;
      return false;
    }
  }
}