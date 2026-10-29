import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../api_config.dart';

// ============================================================================
// GENERAL TASK ALLOCATION VIEW MODEL (The Brain)
// ============================================================================
// What is this file?
// This is the "ViewModel" (the brain) for our General Task Allocation screen.
// It contains all the variables, states, and logic to:
// 1. Fetch the approved groups from the backend server.
// 2. Fetch the task details (MidTask and Final Task description) for each group.
// 3. Filter the groups based on selection ("assigned" vs "unassigned") and search.
// 4. Send the new task description back to the backend to assign it to a group!
//
// Style Rules followed:
// - Simple VVM architecture only.
// - No models, just dynamic lists and maps: List<Map<String, dynamic>>.
// - Beginner-friendly naming and extensive newbie comments.
// ============================================================================

class GeneralTaskAllocationViewModel {
  
  // -------------------------------------------------------------
  // STATE VARIABLES (All the data we need to keep track of)
  // -------------------------------------------------------------
  
  // 1. Holds the raw list of enriched groups we get from the server.
  List<Map<String, dynamic>> groups = [];
  
  // 2. Holds the filtered list of groups currently shown to the user on screen.
  List<Map<String, dynamic>> filteredGroups = [];
  
  // 3. The currently selected group that the user is viewing/editing.
  Map<String, dynamic>? selectedGroup;
  
  // 4. Milestone Toggle: Can be "MidTask" or "FinalTask".
  // Note: We send "MidTask" or "Final Task" to the database in C#.
  String activeMilestone = "MidTask";
  
  // 5. Filter Badge Toggle: Can be "unassigned" or "assigned".
  String activeFilter = "unassigned";
  
  // 6. The search query string typed by the user in the search bar.
  String searchQuery = "";
  
  // 7. The text controller or string that stores the active task description draft.
  String taskDescription = "";
  
  // 8. Toggles to show loading indicators (spinners) on screen.
  bool isLoading = false;
  bool isSaving = false;

  // -------------------------------------------------------------
  // METHOD: fetchGroups
  // -------------------------------------------------------------
  // Downloads the groups and enriches them with milestone task descriptions.
  // We make two API calls:
  // 1. Fetch approved groups for FYP-2.
  // 2. Fetch specific task allocation/details for each group by ID.
  // -------------------------------------------------------------
  Future<void> fetchGroups() async {
    isLoading = true;
    try {
      final String approvedUrl = "${ApiConfig.baseUrl}/committee-meetings/groups/approved/FYP-2";
      debugPrint("--> [Primary Schooler] Fetching approved groups: $approvedUrl");

      final response = await http.get(Uri.parse(approvedUrl));
      if (response.statusCode == 200) {
        final List rawList = json.decode(response.body);
        
        // Let's build a new list with enriched information for each group!
        List<Map<String, dynamic>> enrichedList = [];
        
        for (var rawGroup in rawList) {
          final groupMap = Map<String, dynamic>.from(rawGroup);
          final groupId = groupMap['groupName'] ?? groupMap['id'];

          try {
            // Get detailed tasks and members from the backend for this group ID!
            final String detailUrl = "${ApiConfig.baseUrl}/fyp2-scores/groups/$groupId";
            final detailRes = await http.get(Uri.parse(detailUrl));

            if (detailRes.statusCode == 200) {
              final Map<String, dynamic> details = json.decode(detailRes.body);
              
              // Extract the midTask and finalTask descriptions
              final String midDesc = details['midTask'] ?? "";
              final String finalDesc = details['finalTask'] ?? "";
              
              // Decide which description is relevant based on our active milestone selection
              final String desc = (activeMilestone == "MidTask") ? midDesc : finalDesc;
              final bool isAssigned = desc.trim().isNotEmpty;

              enrichedList.add({
                ...groupMap,
                'projectTitle': details['projectName'] ?? groupMap['projectTitle'] ?? "No Project Assigned",
                'taskDesc': desc,
                'midTask': midDesc,
                'finalTask': finalDesc,
                'isAssigned': isAssigned,
                'evaluationStatus': isAssigned ? "assigned" : "unassigned",
                // Detail API returns objects with 'name'. Let's save the full members list!
                'members': details['members'] ?? [],
                'membersCount': (details['members'] as List?)?.length ?? (groupMap['members'] as List?)?.length ?? 0
              });
            } else {
              // Fallback if detail endpoint fails for a group
              enrichedList.add({
                ...groupMap,
                'projectTitle': groupMap['projectTitle'] ?? "No Project Assigned",
                'taskDesc': "",
                'midTask': "",
                'finalTask': "",
                'isAssigned': false,
                'evaluationStatus': "unassigned",
                'members': [],
                'membersCount': (groupMap['members'] as List?)?.length ?? 0
              });
            }
          } catch (e) {
            debugPrint("!!! [Primary Schooler VM Error] Failed to enrich group $groupId: $e");
            enrichedList.add({
              ...groupMap,
              'projectTitle': groupMap['projectTitle'] ?? "No Project Assigned",
              'taskDesc': "",
              'midTask': "",
              'finalTask': "",
              'isAssigned': false,
              'evaluationStatus': "unassigned",
              'members': [],
              'membersCount': (groupMap['members'] as List?)?.length ?? 0
            });
          }
        }

        groups = enrichedList;
        applyFilters();
      } else {
        groups = [];
        filteredGroups = [];
      }
    } catch (e) {
      debugPrint("!!! [Primary Schooler VM Error] fetchGroups failed: $e");
      groups = [];
      filteredGroups = [];
    }
    isLoading = false;
  }

  // -------------------------------------------------------------
  // METHOD: applyFilters
  // -------------------------------------------------------------
  // Filters the enriched groups list by:
  // A. activeFilter ("unassigned" vs "assigned")
  // B. searchQuery (searches Group ID, Project Name, or Supervisor Name)
  // -------------------------------------------------------------
  void applyFilters() {
    // 1. Filter by unassigned/assigned status
    List<Map<String, dynamic>> temp = groups.where((g) {
      // Re-evaluate assigned status based on current activeMilestone
      final String desc = (activeMilestone == "MidTask") ? (g['midTask'] ?? "") : (g['finalTask'] ?? "");
      final bool isAssigned = desc.trim().isNotEmpty;
      final String currentStatus = isAssigned ? "assigned" : "unassigned";
      
      return currentStatus == activeFilter;
    }).toList();

    // 2. Filter by search query if the user typed anything
    if (searchQuery.trim().isNotEmpty) {
      final q = searchQuery.toLowerCase().trim();
      temp = temp.where((g) {
        final idStr = (g['groupName'] ?? g['id'] ?? "").toString().toLowerCase();
        final proj = (g['projectTitle'] ?? "").toString().toLowerCase();
        final superv = (g['supervisor'] ?? "").toString().toLowerCase();
        return idStr.contains(q) || proj.contains(q) || superv.contains(q);
      }).toList();
    }

    filteredGroups = temp;
  }

  // -------------------------------------------------------------
  // METHOD: selectGroup
  // -------------------------------------------------------------
  // Tapping a group selects it and loads its description into the text editor.
  // -------------------------------------------------------------
  void selectGroup(Map<String, dynamic> group) {
    selectedGroup = group;
    // Load whichever task description belongs to the current active milestone
    taskDescription = (activeMilestone == "MidTask") ? (group['midTask'] ?? "") : (group['finalTask'] ?? "");
  }

  // -------------------------------------------------------------
  // METHOD: assignTask
  // -------------------------------------------------------------
  // Posts the new task description to the C# backend.
  // Body parameter keys: "groupId", "taskDescription", "taskTitle"
  // -------------------------------------------------------------
  Future<bool> assignTask() async {
    if (selectedGroup == null) return false;
    if (taskDescription.trim().isEmpty) return false;

    isSaving = true;
    try {
      final String url = "${ApiConfig.baseUrl}/fyp2-scores/assign-task";
      
      // Determine the milestone string expected by the C# backend
      final String milestoneTitle = (activeMilestone == "MidTask") ? "MidTask" : "Final Task";
      
      final Map<String, dynamic> body = {
        "groupId": selectedGroup!['groupName'] ?? selectedGroup!['id'],
        "taskDescription": taskDescription,
        "taskTitle": milestoneTitle
      };

      debugPrint("--> [Primary Schooler] Assigning Task: $url with body $body");

      final response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: json.encode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        // Refresh all groups to get updated task description from backend
        final int prevGroupId = selectedGroup!['groupName'] ?? selectedGroup!['id'];
        await fetchGroups();

        // Re-select the group we were just working on so it remains highlighted
        for (var g in groups) {
          final id = g['groupName'] ?? g['id'];
          if (id == prevGroupId) {
            selectGroup(g);
            break;
          }
        }
        isSaving = false;
        return true;
      }
    } catch (e) {
      debugPrint("!!! [Primary Schooler VM Error] assignTask failed: $e");
    }
    isSaving = false;
    return false;
  }
}

// -------------------------------------------------------------
// EXTENSION helper to support map copying / merging in old dart
// -------------------------------------------------------------
extension MapEnrichment on Map<String, dynamic> {
  Map<String, dynamic> enrich(Map<String, dynamic> other) {
    var copy = Map<String, dynamic>.from(this);
    other.forEach((k, v) => copy[k] = v);
    return copy;
  }
}
