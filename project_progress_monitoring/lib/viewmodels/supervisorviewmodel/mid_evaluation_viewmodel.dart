import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../api_config.dart';

// ============================================================================
// WHAT IS THIS FILE?
// This is the "Brain" or "ViewModel" for the Supervisor's Mid Task Evaluation screen (FYP-2).
// It handles fetching active academic sessions, loading approved FYP-2 groups for this supervisor,
// enriching groups with task assignment / evaluation status (Unassigned, Assigned, Evaluated),
// loading student members with registration details, and submitting mid evaluation marks & remarks.
//
// WHY DOES IT EXIST?
// To keep our view clean, separate business logic from UI widgets, and provide a beautiful,
// rich General Task Evaluation workflow tailored specifically for Supervisor Mid Evaluation (FYP-2).
// ============================================================================

class MidEvaluationViewModel {
  // --- Dashboard Loading States ---
  // Tells the UI whether we are currently fetching data from the server
  bool isLoading = false;
  
  // Lists for holding raw & filtered groups
  // groups: holds all approved FYP-2 groups fetched from backend
  // filteredGroups: holds groups matching the active filter (unassigned, assigned, evaluated) and search query
  List<Map<String, dynamic>> groups = [];
  List<Map<String, dynamic>> filteredGroups = [];
  
  // Criteria & Session States
  // sessionId: active academic session ID (defaults to 13)
  int sessionId = 13;

  // Selected Group Specifics
  // selectedGroup: the group currently selected by the supervisor
  // selectedGroupMembers: list of student enrollment cards belonging to the selected group
  Map<String, dynamic>? selectedGroup;
  List<Map<String, dynamic>> selectedGroupMembers = [];

  // Inputs mapped by studentName / studentID
  // marksInput structure: { studentName: marksText }
  // remarksInput structure: { studentName: remarksText }
  Map<String, String> marksInput = {};
  Map<String, String> remarksInput = {};

  // Loading indicator map for saving individual student grades
  // Tracks saving state per student name so only that student's button shows a loading spinner
  Map<String, bool> savingIndividualMap = {};
  bool isSavingAll = false;

  // -------------------------------------------------------------
  // METHOD: fetchSupervisorGroups
  // Fetches active session, pulls approved FYP-2 groups for this supervisor,
  // and enriches them with mid task descriptions & evaluation status.
  // -------------------------------------------------------------
  Future<void> fetchSupervisorGroups({
    required String supervisorId,
    required String activeFilter,
    required String searchQuery,
  }) async {
    isLoading = true;
    groups.clear();
    filteredGroups.clear();
    
    try {
      // 1. Fetch current academic session ID
      final sessionUrl = Uri.parse("${ApiConfig.baseUrl}/users/CurrentSession");
      debugPrint("--> [Supervisor VVM] Loading Current Session: $sessionUrl");
      final sessionRes = await http.get(sessionUrl);
      if (sessionRes.statusCode == 200) {
        final sessionData = jsonDecode(sessionResResBody(sessionRes.body));
        sessionId = sessionData['id'] ?? 13;
      }

      // 2. Fetch approved FYP-2 groups for this supervisor
      final approvedUrl = Uri.parse("${ApiConfig.baseUrl}/supervisor/approved/FYP-2");
      debugPrint("--> [Supervisor VVM] Loading Approved FYP-2 Groups: $approvedUrl");
      final approvedRes = await http.get(approvedUrl);
      
      if (approvedRes.statusCode == 200) {
        final rawGroups = jsonDecode(approvedRes.body) as List;
        List<Map<String, dynamic>> matchedGroups = rawGroups.map((g) => Map<String, dynamic>.from(g)).toList();

        // 3. Enrich groups with active mid task & evaluation status
        for (var g in matchedGroups) {
          final groupNameStr = g['groupName']?.toString() ?? '';
          if (groupNameStr.isEmpty) continue;

          try {
            // Fetch group task details to check if MidTask is assigned
            final detailUrl = Uri.parse("${ApiConfig.baseUrl}/fyp2-scores/groups/$groupNameStr");
            final detailRes = await http.get(detailUrl);
            
            String midTaskDesc = '';
            bool isAssigned = false;
            String evaluationStatus = "unassigned";
            int membersCount = (g['members'] as List?)?.length ?? 0;
            int membersEvaluatedCount = 0;

            if (detailRes.statusCode == 200) {
              final detail = jsonDecode(detailRes.body) as Map<String, dynamic>;
              midTaskDesc = detail['midTask']?.toString() ?? '';
              isAssigned = midTaskDesc.trim().isNotEmpty;
            }

            // Check if marks were already submitted by checking progress or existing marks
            final int progressVal = g['progress'] ?? g['Progress'] ?? 0;
            if (progressVal > 0) {
              membersEvaluatedCount = membersCount;
              evaluationStatus = "evaluated";
            } else if (isAssigned) {
              evaluationStatus = "assigned";
            } else {
              evaluationStatus = "unassigned";
            }

            groups.add({
              ...g,
              'projectTitle': g['projectTitle'] ?? 'No Project Assigned',
              'midTaskDescription': midTaskDesc,
              'isAssigned': isAssigned,
              'evaluationStatus': evaluationStatus,
              'membersCount': membersCount,
              'membersEvaluatedCount': membersEvaluatedCount,
            });
          } catch (e) {
            debugPrint("Error enriching group $groupNameStr: $e");
            groups.add({
              ...g,
              'isAssigned': false,
              'evaluationStatus': 'unassigned',
              'membersCount': (g['members'] as List?)?.length ?? 0,
              'membersEvaluatedCount': 0,
            });
          }
        }
      }
      
      applyFilters(activeFilter, searchQuery);
    } catch (e) {
      debugPrint("Fatal error loading supervisor mid evaluation groups: $e");
    } finally {
      isLoading = false;
    }
  }

  // Helper to safely decode json body
  dynamic jsonDecode(String body) => json.decode(body);
  String sessionResResBody(String body) => body;

  // -------------------------------------------------------------
  // METHOD: applyFilters
  // Local query search and evaluationStatus filtering
  // -------------------------------------------------------------
  void applyFilters(String activeFilter, String query) {
    List<Map<String, dynamic>> temp = groups.where((g) => g['evaluationStatus'] == activeFilter).toList();
    
    if (query.trim().isNotEmpty) {
      final q = query.toLowerCase().trim();
      temp = temp.where((g) {
        final gName = (g['groupName'] ?? '').toString().toLowerCase();
        final pTitle = (g['projectTitle'] ?? '').toString().toLowerCase();
        return gName.contains(q) || pTitle.contains(q);
      }).toList();
    }
    
    filteredGroups = temp;
  }

  // -------------------------------------------------------------
  // METHOD: selectGroupAndLoadMembers
  // Fetches member enrollment cards from backend with fallback to basic members list
  // -------------------------------------------------------------
  Future<void> selectGroupAndLoadMembers(Map<String, dynamic> group, String supervisorId) async {
    selectedGroup = group;
    selectedGroupMembers.clear();
    marksInput.clear();
    remarksInput.clear();
    
    final groupNameStr = group['groupName']?.toString() ?? '';
    if (groupNameStr.isEmpty) return;

    try {
      // Try fetching rich student enrollment data
      final membersUrl = Uri.parse("${ApiConfig.baseUrl}/fyp2-scores/getDataForUpdateMarks/$groupNameStr");
      final response = await http.get(membersUrl);
      
      if (response.statusCode == 200) {
        final list = json.decode(response.body) as List;
        if (list.isNotEmpty) {
          selectedGroupMembers = list.map((m) => Map<String, dynamic>.from(m)).toList();
        }
      }

      // Fallback if rich data is empty: use the members string list from the group object
      if (selectedGroupMembers.isEmpty) {
        final rawMembers = group['members'] as List? ?? [];
        for (var mName in rawMembers) {
          selectedGroupMembers.add({
            'StudentID': 'N/A',
            'StudentName': mName.toString(),
            'currentCGPA': 'N/A',
            'EnrollmentID': 0,
            'Tech': 'FYP-2'
          });
        }
      }

      // Initialize default inputs
      for (var student in selectedGroupMembers) {
        final sName = student['StudentName']?.toString() ?? '';
        if (sName.isNotEmpty) {
          marksInput[sName] = '';
          remarksInput[sName] = '';
        }
      }

    } catch (e) {
      debugPrint("Error loading group member details: $e");
    }
  }

  // -------------------------------------------------------------
  // METHOD: saveIndividualEvaluation
  // Validates marks & submits evaluation for a single student or the whole group
  // using the dedicated supervisor controller endpoint: /supervisor/submit-mid-evaluation
  // -------------------------------------------------------------
  Future<String?> saveIndividualEvaluation({
    required Map<String, dynamic> member,
    required String supervisorId,
  }) async {
    final sName = member['StudentName']?.toString() ?? '';
    if (sName.isEmpty) return "Invalid student name!";

    final valStr = marksInput[sName] ?? '';
    final numericVal = int.tryParse(valStr) ?? -1;

    if (numericVal < 0 || numericVal > 100) {
      return "Marks for $sName ($valStr) must be a valid integer between 0 and 100!";
    }

    savingIndividualMap[sName] = true;

    try {
      // Prepare payload matching C# SupervisorController.SubmitMidEvaluation exactly
      List<Map<String, dynamic>> studentData = [];
      for (var std in selectedGroupMembers) {
        final name = std['StudentName']?.toString() ?? '';
        final mStr = marksInput[name] ?? '0';
        final rStr = remarksInput[name] ?? '';
        
        studentData.add({
          "StudentName": name,
          "Marks": int.tryParse(mStr) ?? 0,
          "Remarks": rStr,
        });
      }

      Map<String, dynamic> payload = {
        "SupervisorId": int.tryParse(supervisorId) ?? 0,
        "GroupId": selectedGroup!['groupName'],
        "SessionId": sessionId,
        "Students": studentData,
      };

      final url = Uri.parse("${ApiConfig.baseUrl}/supervisor/submit-mid-evaluation");
      debugPrint("--> [Supervisor VVM Post] Submitting Mid Evaluation: $url");
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: json.encode(payload),
      );

      savingIndividualMap[sName] = false;

      if (response.statusCode == 200) {
        return null; // Success!
      } else {
        return "Failed to submit evaluation! Server replied with code: ${response.statusCode}";
      }
    } catch (e) {
      savingIndividualMap[sName] = false;
      return "An unexpected network error occurred: $e";
    }
  }

  // -------------------------------------------------------------
  // METHOD: submitAllEvaluations
  // Submits evaluations for all students in the selected group at once
  // -------------------------------------------------------------
  Future<String?> submitAllEvaluations({required String supervisorId}) async {
    if (selectedGroup == null) return "No group selected!";

    // Validate all students
    for (var std in selectedGroupMembers) {
      final name = std['StudentName']?.toString() ?? '';
      final valStr = marksInput[name] ?? '';
      final numericVal = int.tryParse(valStr) ?? -1;

      if (numericVal < 0 || numericVal > 100) {
        return "Marks for $name ($valStr) must be a valid integer between 0 and 100!";
      }
    }

    isSavingAll = true;

    try {
      List<Map<String, dynamic>> studentData = [];
      for (var std in selectedGroupMembers) {
        final name = std['StudentName']?.toString() ?? '';
        final mStr = marksInput[name] ?? '0';
        final rStr = remarksInput[name] ?? '';
        
        studentData.add({
          "StudentName": name,
          "Marks": int.tryParse(mStr) ?? 0,
          "Remarks": rStr,
        });
      }

      Map<String, dynamic> payload = {
        "SupervisorId": int.tryParse(supervisorId) ?? 0,
        "GroupId": selectedGroup!['groupName'],
        "SessionId": sessionId,
        "Students": studentData,
      };

      final url = Uri.parse("${ApiConfig.baseUrl}/supervisor/submit-mid-evaluation");
      debugPrint("--> [Supervisor VVM Post] Submitting All Mid Evaluations: $url");
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: json.encode(payload),
      );

      isSavingAll = false;

      if (response.statusCode == 200) {
        return null; // Success!
      } else {
        return "Failed to submit all evaluations! Server replied with code: ${response.statusCode}";
      }
    } catch (e) {
      isSavingAll = false;
      return "An unexpected network error occurred: $e";
    }
  }
}