import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../api_config.dart';

// ---------------------------------------------------------
// WHAT IS THIS FILE?
// This is the "Brain" or "ViewModel" for the regular Committee member Supervisor Allocation.
// It is separate from the Committee Head's ViewModel so that each role is fully isolated.
// It allows filtering project groups based on FYP-1 or FYP-2 toggle state.
// It is fully commented so a Primary Schooler can learn easily!
// ---------------------------------------------------------

class CommitteeSupervisorAllocationViewModel {
  
  // 1. A simple list to keep our supervisors loaded from the database.
  List<Map<String, dynamic>> supervisors = [];

  // 2. A simple list to keep approved groups loaded from the database.
  List<Map<String, dynamic>> groups = [];

  // 3. A flag to keep track of whether we are loading data or not.
  bool isLoading = false;

  // ---------------------------------------------------------
  // FUNCTION: fetchSupervisors
  // Loads all supervisors and their current group load from the API.
  // ---------------------------------------------------------
  Future<void> fetchSupervisors() async {
    try {
      final url = Uri.parse("${ApiConfig.baseUrl}/committee-meetings/group-count");
      debugPrint("--> [Primary Schooler] Committee fetching supervisor list: $url");

      final response = await http.get(url);

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        List<dynamic> rawData = jsonDecode(response.body);
        supervisors = rawData.map((item) => item as Map<String, dynamic>).toList();
        debugPrint("--> [Primary Schooler] Committee loaded ${supervisors.length} supervisors.");
      }
    } catch (e) {
      debugPrint("!!! [Primary Schooler Error] Committee failed to fetch supervisors: $e");
    }
  }

  // ---------------------------------------------------------
  // FUNCTION: fetchGroups
  // Fetches approved project groups for a SPECIFIC fyp semester ('FYP-1' or 'FYP-2').
  // ---------------------------------------------------------
  Future<void> fetchGroups(String activeFyp) async {
    try {
      debugPrint("--> [Primary Schooler] Committee loading approved groups list for $activeFyp...");
      
      final url = Uri.parse("${ApiConfig.baseUrl}/committee-meetings/groups/approved/$activeFyp");
      final response = await http.get(url);

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        List<dynamic> raw = jsonDecode(response.body);
        groups = raw.map((item) => item as Map<String, dynamic>).toList();
        debugPrint("--> [Primary Schooler] Committee loaded ${groups.length} groups for $activeFyp successfully!");
      } else {
        groups = [];
      }
    } catch (e) {
      groups = [];
      debugPrint("!!! [Primary Schooler Error] Committee failed to load approved groups: $e");
    }
  }

  // ---------------------------------------------------------
  // FUNCTION: loadAllData
  // Simply runs both fetch functions in sequence for a specific FYP to set up the screen.
  // ---------------------------------------------------------
  Future<void> loadAllData(String activeFyp) async {
    isLoading = true;
    await fetchSupervisors();
    await fetchGroups(activeFyp);
    isLoading = false;
  }

  // ---------------------------------------------------------
  // FUNCTION: autoAllocateSupervisor
  // Loops through the list of supervisors to find the one with the fewest groups.
  // ---------------------------------------------------------
  Map<String, dynamic>? autoAllocateSupervisor() {
    if (supervisors.isEmpty) return null;

    Map<String, dynamic> leastBusy = supervisors[0];

    for (var s in supervisors) {
      int currentGroups = s['TotalGroups'] ?? 0;
      int leastBusyGroups = leastBusy['TotalGroups'] ?? 0;

      if (currentGroups < leastBusyGroups) {
        leastBusy = s;
      }
    }

    return leastBusy;
  }

  // ---------------------------------------------------------
  // FUNCTION: allocateSupervisorToGroup
  // Sends a request to the server to assign a supervisor to a group.
  // ---------------------------------------------------------
  Future<bool> allocateSupervisorToGroup(int groupId, String supervisorId) async {
    try {
      final url = Uri.parse("${ApiConfig.baseUrl}/committee-meetings/allocateSupervisor");
      debugPrint("--> [Primary Schooler] Committee submitting allocation: $url");

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
        debugPrint("--> [Primary Schooler] Allocation saved successfully!");
        return true;
      }
    } catch (e) {
      debugPrint("!!! [Primary Schooler Error] Committee allocation failed: $e");
    }
    return false;
  }
}
