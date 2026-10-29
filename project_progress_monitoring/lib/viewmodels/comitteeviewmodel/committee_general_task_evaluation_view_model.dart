import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../api_config.dart';

// ============================================================================
// WHAT IS THIS FILE?
// This is the "Brain" or "ViewModel" for the Committee Member's General Task Evaluation screen.
// It handles fetching active sessions, matching criteria rubrics, loading approved groups,
// and submitting subparameter marks + evaluation remarks.
//
// WHY DOES IT EXIST?
// To keep our view clean and separate business logic from UI widgets. This version is
// tailored specifically for regular Committee Members, omitting Director final grading features.
// ============================================================================

class CommitteeGeneralTaskEvaluationViewModel {
  // --- Dashboard Loading States ---
  // Tells the UI whether we are currently fetching data from the server
  bool isLoading = false;
  
  // Lists for holding raw & filtered groups
  // groups: holds all approved groups fetched from backend
  // filteredGroups: holds groups matching the active filter (unassigned, assigned, evaluated) and search query
  List<Map<String, dynamic>> groups = [];
  List<Map<String, dynamic>> filteredGroups = [];
  
  // Criteria-related States
  // sessionId: active academic session ID (e.g. 13)
  // sessionCriteria: list of all available parameter rubrics for this session
  // activeParameter: the specific parameter rubric matching the active milestone (MidTask vs Final Task)
  int sessionId = 1;
  List<Map<String, dynamic>> sessionCriteria = [];
  Map<String, dynamic>? activeParameter;

  // Selected Group Specifics
  // selectedGroup: the group currently selected by the user
  // selectedGroupMembers: list of student enrollment cards belonging to the selected group
  Map<String, dynamic>? selectedGroup;
  List<Map<String, dynamic>> selectedGroupMembers = [];

  // Inputs mapped by studentEnrollID / studentID
  // marksInput structure: { studentID: { subParamID: scoreText } }
  // remarksInput structure: { studentID: remarksText }
  Map<String, Map<String, String>> marksInput = {};
  Map<String, String> remarksInput = {};

  // Loading indicator map for saving individual student grades
  // Tracks saving state per student ID so only that student's button shows a loading spinner
  Map<String, bool> savingIndividualMap = {};

  // -------------------------------------------------------------
  // METHOD: fetchSessionAndGroups
  // Fetches active session, matches rubrics, pulls all approved groups
  // and enriches them with milestones & evaluation status.
  // -------------------------------------------------------------
  Future<void> fetchSessionAndGroups({
    required String activeMilestone,
    required String activeFilter,
    required String searchQuery,
    required String userRole,
    required String userName,
    required String userId,
    required String fypType,
  }) async {
    isLoading = true;
    groups.clear();
    filteredGroups.clear();
    
    // Determine which API controller to call based on FYP type (fyp2-scores vs fyp1-scores)
    final String scoreApi = fypType.toLowerCase() == "fyp-2" ? "fyp2-scores" : "fyp1-scores";
    
    try {
      // 1. Fetch current academic session ID
      final sessionUrl = Uri.parse("${ApiConfig.baseUrl}/users/CurrentSession");
      debugPrint("--> [Committee VVM] Loading Current Session: $sessionUrl");
      final sessionRes = await http.get(sessionUrl);
      if (sessionRes.statusCode == 200) {
        final sessionData = jsonDecode(sessionRes.body);
        sessionId = sessionData['id'] ?? 1;
      }

      // 2. Fetch all criteria parameters for this session
      final criteriaUrl = Uri.parse("${ApiConfig.baseUrl}/$scoreApi/available-criteria/$sessionId");
      debugPrint("--> [Committee VVM] Loading Criteria Rubrics: $criteriaUrl");
      final criteriaRes = await http.get(criteriaUrl);
      if (criteriaRes.statusCode == 200) {
        final rawCriteria = jsonDecode(criteriaRes.body) as List;
        sessionCriteria = rawCriteria.map((c) => Map<String, dynamic>.from(c)).toList();
        
        // Match appropriate parameter (MidTask vs Final Task)
        final cleanMilestone = activeMilestone.toLowerCase().replaceAll(" ", "").trim();
        activeParameter = null;
        for (var param in sessionCriteria) {
          final cleanParamName = (param['name'] ?? '').toString().toLowerCase().replaceAll(" ", "").trim();
          if (cleanParamName.contains(cleanMilestone) || cleanMilestone.contains(cleanParamName)) {
            activeParameter = param;
            break;
          }
        }
      }

      // 3. Fetch all approved groups for this FYP Type
      final approvedUrl = Uri.parse("${ApiConfig.baseUrl}/committee-meetings/groups/approved/${fypType.toUpperCase()}");
      debugPrint("--> [Committee VVM] Loading Approved $fypType Groups: $approvedUrl");
      final approvedRes = await http.get(approvedUrl);
      if (approvedRes.statusCode == 200) {
        final rawGroups = jsonDecode(approvedRes.body) as List;
        List<Map<String, dynamic>> matchedGroups = rawGroups.map((g) => Map<String, dynamic>.from(g)).toList();

        // 4. Enrich groups with active tasks & evaluation status
        for (var g in matchedGroups) {
          final groupNameStr = g['groupName']?.toString() ?? '';
          if (groupNameStr.isEmpty) continue;

          try {
            // Fetch group task details (MidTask / Final Task descriptions)
            final detailUrl = Uri.parse("${ApiConfig.baseUrl}/$scoreApi/groups/$groupNameStr");
            final detailRes = await http.get(detailUrl);
            
            if (detailRes.statusCode == 200) {
              final detail = jsonDecode(detailRes.body) as Map<String, dynamic>;
              
              final isMid = activeMilestone == "MidTask";
              final taskDesc = (isMid ? detail['midTask'] : detail['finalTask'])?.toString() ?? '';
              final isAssigned = taskDesc.trim().isNotEmpty;
              
              String evaluationStatus = "unassigned";
              int membersEvaluatedCount = 0;
              int membersTotalCount = 0;

              if (isAssigned) {
                // Fetch group members details with enrollment ids
                final membersUrl = Uri.parse("${ApiConfig.baseUrl}/$scoreApi/getDataForUpdateMarks/$groupNameStr");
                final membersRes = await http.get(membersUrl);
                
                if (membersRes.statusCode == 200) {
                  final studentDataList = jsonDecode(membersRes.body) as List;
                  membersTotalCount = studentDataList.length;

                  if (activeParameter != null && membersTotalCount > 0) {
                    // Fetch ALL saved marks for this parameter
                    final paramId = activeParameter!['id'];
                    final savedMarksUrl = Uri.parse("${ApiConfig.baseUrl}/$scoreApi/get-all-saved-marks/$paramId");
                    final savedMarksRes = await http.get(savedMarksUrl);
                    
                    if (savedMarksRes.statusCode == 200) {
                      final savedList = jsonDecode(savedMarksRes.body) as List;
                      
                      for (var s in studentDataList) {
                        final enrollId = s['EnrollmentID']?.toString();
                        
                        bool hasMarks = savedList.any((item) {
                          if (item['studentEnrollID']?.toString() != enrollId) return false;
                          
                          // Match evaluator role rules: Committee members check their own marks
                          final itemEvaluatorId = item['evaluatorID']?.toString();
                          if (itemEvaluatorId == userId) return true;
                          
                          final savedRole = (item['evaluatorRole'] ?? '').toString().toLowerCase();
                          return savedRole != "director" && savedRole != "committeehead";
                        });
                        
                        if (hasMarks) membersEvaluatedCount++;
                      }
                    }
                  }
                }
                
                if (membersTotalCount > 0 && membersEvaluatedCount == membersTotalCount) {
                  evaluationStatus = "evaluated";
                } else {
                  evaluationStatus = "assigned";
                }
              }

              groups.add({
                ...g,
                'projectTitle': detail['projectName'] ?? g['projectTitle'] ?? 'No Project Assigned',
                'midTaskDescription': detail['midTask'] ?? '',
                'finalTaskDescription': detail['finalTask'] ?? '',
                'isAssigned': isAssigned,
                'evaluationStatus': evaluationStatus,
                'membersCount': membersTotalCount > 0 ? membersTotalCount : (g['members'] as List?)?.length ?? 0,
                'membersEvaluatedCount': membersEvaluatedCount,
              });
            } else {
              groups.add({
                ...g,
                'isAssigned': false,
                'evaluationStatus': 'unassigned',
                'membersCount': (g['members'] as List?)?.length ?? 0,
                'membersEvaluatedCount': 0,
              });
            }
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
      debugPrint("Fatal error loading committee general task evaluation: $e");
    } finally {
      isLoading = false;
    }
  }

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
        final superv = (g['supervisor'] ?? '').toString().toLowerCase();
        return gName.contains(q) || pTitle.contains(q) || superv.contains(q);
      }).toList();
    }
    
    filteredGroups = temp;
  }

  // -------------------------------------------------------------
  // METHOD: selectGroupAndLoadMembers
  // Fetches member enrollment cards, saved scores, and active remarks
  // -------------------------------------------------------------
  Future<void> selectGroupAndLoadMembers(Map<String, dynamic> group, String userId, String userRole, String fypType) async {
    selectedGroup = group;
    selectedGroupMembers.clear();
    marksInput.clear();
    remarksInput.clear();
    
    final groupNameStr = group['groupName']?.toString() ?? '';
    if (groupNameStr.isEmpty) return;
    
    final String scoreApi = fypType.toLowerCase() == "fyp-2" ? "fyp2-scores" : "fyp1-scores";

    try {
      final membersUrl = Uri.parse("${ApiConfig.baseUrl}/$scoreApi/getDataForUpdateMarks/$groupNameStr");
      final response = await http.get(membersUrl);
      
      if (response.statusCode == 200) {
        final list = jsonDecode(response.body) as List;
        selectedGroupMembers = list.map((m) => Map<String, dynamic>.from(m)).toList();
        
        // Prefill current marks
        if (activeParameter != null) {
          final paramId = activeParameter!['id'];
          final savedMarksUrl = Uri.parse("${ApiConfig.baseUrl}/$scoreApi/get-saved-marks/$paramId/$userId");
          final savedRes = await http.get(savedMarksUrl);
          
          if (savedRes.statusCode == 200) {
            final savedMarks = jsonDecode(savedRes.body) as List;
            for (var student in selectedGroupMembers) {
              final studentId = student['StudentID']?.toString() ?? '';
              final enrollId = student['EnrollmentID']?.toString();
              
              if (studentId.isEmpty) continue;
              marksInput[studentId] = {};
              
              // Prefill marks
              for (var scoreItem in savedMarks) {
                if (scoreItem['studentEnrollID']?.toString() == enrollId) {
                  final subParamId = scoreItem['subParameterID']?.toString() ?? '';
                  final obtainedVal = scoreItem['obtainedMarks']?.toString() ?? '0';
                  marksInput[studentId]![subParamId] = obtainedVal;
                }
              }

              // Load active remarks by calling get-remarks
              final remarksUrl = Uri.parse("${ApiConfig.baseUrl}/$scoreApi/get-remarks/$enrollId/$userId/$sessionId");
              final remarksRes = await http.get(remarksUrl);
              if (remarksRes.statusCode == 200) {
                final remarksList = jsonDecode(remarksRes.body) as List;
                if (remarksList.isNotEmpty) {
                  remarksInput[studentId] = remarksList[0]['remarks']?.toString() ?? '';
                }
              }
            }
          }
        }
      }
    } catch (e) {
      debugPrint("Error loading group member marks: $e");
    }
  }

  // -------------------------------------------------------------
  // METHOD: saveIndividualEvaluation
  // Validates weights & submits standard evaluation marks + remarks
  // -------------------------------------------------------------
  Future<String?> saveIndividualEvaluation({
    required Map<String, dynamic> member,
    required String userId,
    required String userRole,
    required String activeMilestone,
    required String fypType,
  }) async {
    if (activeParameter == null) {
      return "No criteria rubric matched for this milestone in academic session!";
    }

    final studentId = member['StudentID']?.toString() ?? '';
    final enrollmentId = member['EnrollmentID'];
    final taskId = member['TaskId'] ?? 0;

    // 1. Validation Checks
    final subParams = activeParameter!['subParameters'] as List? ?? [];
    for (var sp in subParams) {
      final spId = sp['id']?.toString() ?? '';
      final valStr = marksInput[studentId]?[spId] ?? '';
      final numericVal = double.tryParse(valStr) ?? 0.0;
      final maxMarks = double.tryParse(sp['percentage']?.toString() ?? '') ?? 0.0;

      if (numericVal < 0.0 || numericVal > maxMarks) {
        return "Obtained marks for '${sp['name']}' ($numericVal) cannot exceed maximum weightage limit ($maxMarks) for ${member['StudentName']}!";
      }
    }

    savingIndividualMap[studentId] = true;

    try {
      // 2. Prepare subparameter DTO payloads
      final List<Map<String, dynamic>> payload = [];
      for (var sp in subParams) {
        final spId = sp['id'];
        final valStr = marksInput[studentId]?[spId?.toString()] ?? '';
        final numericVal = double.tryParse(valStr) ?? 0.0;
        final maxMarks = double.tryParse(sp['percentage']?.toString() ?? '') ?? 0.0;

        payload.add({
          "EnrollmentID": enrollmentId,
          "taskID": taskId,
          "ParameterID": activeParameter!['id'],
          "SubParameterID": spId,
          "EvaluatorID": userId,
          "ObtainedMarks": numericVal,
          "MaxMarks": maxMarks,
          "SessionID": sessionId
        });
      }

      // 3. Post marks payload
      final String scoreApi = fypType.toLowerCase() == "fyp-2" ? "fyp2-scores" : "fyp1-scores";
      final updateMarksUrl = Uri.parse("${ApiConfig.baseUrl}/$scoreApi/update-evaluation-marks");
      debugPrint("--> [Committee VVM Post] Updating Evaluation Marks: $updateMarksUrl");
      final updateRes = await http.post(
        updateMarksUrl,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(payload),
      );

      if (updateRes.statusCode != 200) {
        savingIndividualMap[studentId] = false;
        return "Failed to save marks! Server replied with code: ${updateRes.statusCode}";
      }

      // 4. Save Remarks (If Typed)
      final remarkText = remarksInput[studentId]?.trim() ?? '';
      if (remarkText.isNotEmpty) {
        final saveOrUpdateRemarksUrl = Uri.parse("${ApiConfig.baseUrl}/$scoreApi/save-or-update");
        await http.post(
          saveOrUpdateRemarksUrl,
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({
            "StudentEnrollID": enrollmentId,
            "MeetingID": 0,
            "EvaluatorID": userId,
            "SessionID": sessionId,
            "Remarks": remarkText
          }),
        );
      }

      savingIndividualMap[studentId] = false;
      return null; // Represents Success!
    } catch (e) {
      savingIndividualMap[studentId] = false;
      return "An unexpected network error occurred: $e";
    }
  }
}
