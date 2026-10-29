import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../api_config.dart';

// ---------------------------------------------------------
// WHAT IS THIS FILE?
// This is the "Brain" or "ViewModel" for the Committee Head Supervisor Allocation.
// It handles all the data and API calls for allocating supervisors to a group.
// It allows filtering project groups based on FYP-1 or FYP-2 toggle state.
// It is written simply with primary schooler comments so anyone can understand!
// ---------------------------------------------------------

class CommitteeHeadSupervisorAllocationViewModel {
  
  // 1. A list of supervisors downloaded from the internet.
  List<Map<String, dynamic>> supervisors = [];

  // 2. A list of project groups downloaded from the internet for the dropdown selector.
  List<Map<String, dynamic>> groups = [];

  // 3. A loading variable to know if we should show a spinning circle on screen.
  bool isLoading = false;

  // ---------------------------------------------------------
  // FUNCTION: fetchSupervisors
  // Gets the list of supervisors and their group counts from the server.
  // ---------------------------------------------------------
  Future<void> fetchSupervisors() async {
    try {
      final url = Uri.parse("${ApiConfig.baseUrl}/committee-meetings/group-count");
      debugPrint("--> [Primary Schooler] Loading supervisor counts: $url");

      final response = await http.get(url);

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        List<dynamic> rawData = jsonDecode(response.body);
        supervisors = rawData.map((item) => item as Map<String, dynamic>).toList();
        debugPrint("--> [Primary Schooler] Loaded ${supervisors.length} supervisors successfully!");
      }
    } catch (e) {
      debugPrint("!!! [Primary Schooler Error] Failed to load supervisors: $e");
    }
  }

  // ---------------------------------------------------------
  // FUNCTION: fetchGroups
  // Fetches approved project groups for a SPECIFIC fyp semester ('FYP-1' or 'FYP-2').
  // ---------------------------------------------------------
  Future<void> fetchGroups(String activeFyp) async {
    try {
      debugPrint("--> [Primary Schooler] Loading approved groups list for $activeFyp...");
      
      final url = Uri.parse("${ApiConfig.baseUrl}/committee-meetings/groups/approved/$activeFyp");
      final response = await http.get(url);

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        List<dynamic> raw = jsonDecode(response.body);
        groups = raw.map((item) => item as Map<String, dynamic>).toList();
        debugPrint("--> [Primary Schooler] Loaded ${groups.length} groups for $activeFyp successfully!");
      } else {
        groups = [];
      }
    } catch (e) {
      groups = [];
      debugPrint("!!! [Primary Schooler Error] Failed to load approved groups: $e");
    }
  }

  // ---------------------------------------------------------
  // FUNCTION: loadAllData
  // Simply runs both fetch functions for a specific FYP to set up the screen.
  // ---------------------------------------------------------
  Future<void> loadAllData(String activeFyp) async {
    isLoading = true;
    await fetchSupervisors();
    await fetchGroups(activeFyp);
    isLoading = false;
  }

  // ---------------------------------------------------------
  // FUNCTION: autoAllocateSupervisor
  // Finds the supervisor who has the absolute LEAST amount of groups.
  // ---------------------------------------------------------
  Map<String, dynamic>? autoAllocateSupervisor() {
    if (supervisors.isEmpty) return null;

    Map<String, dynamic> leastBusy = supervisors[0];

    for (var s in supervisors) {
      int currentSupervisorGroups = s['TotalGroups'] ?? 0;
      int leastBusyGroups = leastBusy['TotalGroups'] ?? 0;

      if (currentSupervisorGroups < leastBusyGroups) {
        leastBusy = s;
      }
    }

    return leastBusy;
  }

  // ---------------------------------------------------------
  // FUNCTION: allocateSupervisorToGroup
  // Tells the backend database to assign the supervisor to the project group.
  // ---------------------------------------------------------
  Future<bool> allocateSupervisorToGroup(int groupId, String supervisorId) async {
    try {
      final url = Uri.parse("${ApiConfig.baseUrl}/committee-meetings/allocateSupervisor");
      debugPrint("--> [Primary Schooler] Sending Allocation request to: $url");

      final body = jsonEncode({
        "groupId": groupId,
        "supervisorId": supervisorId,
      });

      final response = await http.put(
        url,
        headers: {"Content-Type": "application/json"},
        body: body,
      );

      if (response.statusCode == 200) {
        debugPrint("--> [Primary Schooler] Group allocated successfully!");
        return true;
      }
    } catch (e) {
      debugPrint("!!! [Primary Schooler Error] Failed to allocate supervisor: $e");
    }
    return false;
  }
}
