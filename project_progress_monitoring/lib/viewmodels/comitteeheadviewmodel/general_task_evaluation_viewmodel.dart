import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../api_config.dart';

// ============================================================================
// WHAT IS THIS FILE?
// This is the "Brain" or "ViewModel" of our General Task Evaluation Dashboard.
// It handles all the network requests, data loading, sorting, filtering,
// individual student grading, and Director final score calculations.
// It keeps our view extremely clean and maintains strict separation of concerns.
// ============================================================================

class GeneralTaskEvaluationViewModel {
  // --- Dashboard States ---
  bool isLoading = false;
  bool isSaving = false;
  
  // Lists for holding raw & filtered groups
  List<Map<String, dynamic>> groups = [];
  List<Map<String, dynamic>> filteredGroups = [];
  
  // Criteria-related States
  int sessionId = 1;
  List<Map<String, dynamic>> sessionCriteria = [];
  Map<String, dynamic>? activeParameter;

  // Selected Group Specifics
  Map<String, dynamic>? selectedGroup;
  List<Map<String, dynamic>> selectedGroupMembers = [];

  // Inputs mapped by studentEnrollID / studentID
  // Marks map structure: { studentID: { subParamID: scoreText } }
  Map<String, Map<String, String>> marksInput = {};
  // Remarks map structure: { studentID: remarksText }
  Map<String, String> remarksInput = {};

  // Loading indicator for saving individual student grades
  Map<String, bool> savingIndividualMap = {};

  // --- Director Grading Suite States ---
  bool includeSupervisorScore = false;
  Map<String, Map<String, dynamic>> calculatedScores = {}; // studentID: { score, grade }
  Map<String, Map<String, dynamic>> finalGrades = {};       // studentID: { score, grade }
  Map<String, bool> calculatingIndividualMap = {};
  Map<String, bool> savingGradeIndividualMap = {};

  // Student Evaluation History States
  Map<String, List<dynamic>> historyData = {}; // enrollmentID: list of remarks
  Map<String, bool> loadingHistoryMap = {};
  Map<String, bool> expandedHistoryMap = {};

  // -------------------------------------------------------------
  // METHOD: fetchSessionAndGroups
  // Fetches active session, matches rubrics, pulls all approved groups
  // and enriches them with milestones & status.
  // -------------------------------------------------------------
  Future<void> fetchSessionAndGroups({
    required String activeMilestone,
    required String activeFilter,
    required String searchQuery,
    required String userRole,
    required String userName,
    required String userId,
    required String fypType, // Add fypType parameter
  }) async {
    isLoading = true;
    groups.clear();
    filteredGroups.clear();
    
    final String scoreApi = fypType.toLowerCase() == "fyp-2" ? "fyp2-scores" : "fyp1-scores";
    
    try {
      // 1. Fetch current academic session ID
      final sessionUrl = Uri.parse("${ApiConfig.baseUrl}/users/CurrentSession");
      debugPrint("--> [VVM Fetch] Loading Current Session: $sessionUrl");
      final sessionRes = await http.get(sessionUrl);
      if (sessionRes.statusCode == 200) {
        final sessionData = jsonDecode(sessionRes.body);
        sessionId = sessionData['id'] ?? 1;
      }

      // 2. Fetch all criteria parameters for this session
      final criteriaUrl = Uri.parse("${ApiConfig.baseUrl}/$scoreApi/available-criteria/$sessionId");
      debugPrint("--> [VVM Fetch] Loading Criteria Rubrics: $criteriaUrl");
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
      debugPrint("--> [VVM Fetch] Loading Approved $fypType Groups: $approvedUrl");
      final approvedRes = await http.get(approvedUrl);
      if (approvedRes.statusCode == 200) {
        final rawGroups = jsonDecode(approvedRes.body) as List;
        List<Map<String, dynamic>> matchedGroups = [];
        
        // If supervisor, only show groups they supervise
        if (userRole.toLowerCase() == "supervisor") {
          for (var g in rawGroups) {
            final superName = (g['supervisor'] ?? '').toString().toLowerCase().trim();
            if (superName == userName.toLowerCase().trim()) {
              matchedGroups.add(Map<String, dynamic>.from(g));
            }
          }
        } else {
          matchedGroups = rawGroups.map((g) => Map<String, dynamic>.from(g)).toList();
        }

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
                          
                          // Match evaluator role rules from React code
                          final itemEvaluatorId = item['evaluatorID']?.toString();
                          if (itemEvaluatorId == userId) return true;
                          
                          final role = userRole.toLowerCase();
                          final savedRole = (item['evaluatorRole'] ?? '').toString().toLowerCase();
                          if (role == "director" || role == "committeehead") {
                            return savedRole == "director" || savedRole == "committeehead";
                          } else {
                            return savedRole != "director" && savedRole != "committeehead";
                          }
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
      debugPrint("Fatal error loading general task evaluation: $e");
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
      debugPrint("--> [VVM Post] Updating Evaluation Marks: $updateMarksUrl");
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
        if (userRole.toLowerCase() == "supervisor") {
          final supervisorRemarksUrl = Uri.parse("${ApiConfig.baseUrl}/supervisor/save-supervisor-remarks");
          await http.post(
            supervisorRemarksUrl,
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({
              "MeetingID": 0,
              "GroupID": selectedGroup!['groupName'],
              "StudentEnrollID": enrollmentId,
              "SupervisorID": userId,
              "Remarks": remarkText
            }),
          );
        } else {
          final String scoreApi = fypType.toLowerCase() == "fyp-2" ? "fyp2-scores" : "fyp1-scores";
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
      }

      savingIndividualMap[studentId] = false;
      return null; // Represents Success!
    } catch (e) {
      savingIndividualMap[studentId] = false;
      return "An unexpected network error occurred: $e";
    }
  }

  // ==========================================================================
  // DIRECTOR GRADING SUITE METHODS
  // ==========================================================================

  // -------------------------------------------------------------
  // METHOD: toggleHistory
  // Expands/collapses evaluation logs & pulls historical notes
  // -------------------------------------------------------------
  Future<void> toggleHistory(Map<String, dynamic> student, String fypType) async {
    final enrollmentId = student['EnrollmentID']?.toString() ?? '';
    final regNumId = student['StudentID']?.toString() ?? '';
    if (enrollmentId.isEmpty || regNumId.isEmpty) return;

    if (expandedHistoryMap[enrollmentId] == true) {
      expandedHistoryMap[enrollmentId] = false;
      return;
    }
    
    expandedHistoryMap[enrollmentId] = true;
    if (historyData.containsKey(enrollmentId)) return; // Don't reload if cached

    loadingHistoryMap[enrollmentId] = true;
    try {
      final String scoreApi = fypType.toLowerCase() == "fyp-2" ? "fyp2-scores" : "fyp1-scores";
      final progressUrl = Uri.parse("${ApiConfig.baseUrl}/$scoreApi/student-progress/$regNumId/${fypType.toUpperCase()}");
      debugPrint("--> [VVM Fetch] Student Progress logs: $progressUrl");
      final response = await http.get(progressUrl);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Merge various logs: supervisor remarks, supervisor group remarks, committee head remarks, and committee remarks
        List<dynamic> logs = [];
        if (data['committeeHeadRemarks'] != null) logs.addAll(data['committeeHeadRemarks']);
        if (data['supervisorRemarks'] != null) logs.addAll(data['supervisorRemarks']);
        if (data['supervisorGroupRemarks'] != null) logs.addAll(data['supervisorGroupRemarks']);
        if (data['committeeRemarks'] != null) logs.addAll(data['committeeRemarks']);
        
        // Sort logs descending by date
        logs.sort((a, b) {
          final dateA = DateTime.tryParse(a['Date']?.toString() ?? '') ?? DateTime(1970);
          final dateB = DateTime.tryParse(b['Date']?.toString() ?? '') ?? DateTime(1970);
          return dateB.compareTo(dateA);
        });

        historyData[enrollmentId] = logs;
      }
    } catch (e) {
      debugPrint("Error loading history logs for enrollment $enrollmentId: $e");
    } finally {
      loadingHistoryMap[enrollmentId] = false;
    }
  }

  // -------------------------------------------------------------
  // METHOD: calculateIndividualScore
  // Director-only method to calculate final grades & scores
  // -------------------------------------------------------------
  Future<String?> calculateIndividualScore(Map<String, dynamic> student, String fypType) async {
    final studentId = student['StudentID']?.toString() ?? '';
    final enrollmentId = student['EnrollmentID'];

    calculatingIndividualMap[studentId] = true;

    try {
      final String scoreApi = fypType.toLowerCase() == "fyp-2" ? "fyp2-scores" : "fyp1-scores";
      final String calcMethod = fypType.toLowerCase() == "fyp-2" ? "calculate-final-fyp2" : "calculate-final-fyp1";
      final calcUrl = Uri.parse("${ApiConfig.baseUrl}/$scoreApi/$calcMethod?includeSupervisorScore=$includeSupervisorScore");
      debugPrint("--> [VVM Post] Calculating Final Score: $calcUrl");
      final response = await http.post(calcUrl);

      if (response.statusCode == 200) {
        final resultList = jsonDecode(response.body) as List;
        final record = resultList.firstWhere(
          (r) => r['EnrollmentID']?.toString() == enrollmentId?.toString(),
          orElse: () => null,
        );

        if (record != null) {
          final score = record['FinalScore'];
          final grade = record['Grade'];

          calculatedScores[studentId] = {"score": score, "grade": grade};
          finalGrades[studentId] = {"score": score, "grade": grade};
          
          calculatingIndividualMap[studentId] = false;
          return "Score calculated successfully: $score (Grade: $grade)";
        } else {
          calculatingIndividualMap[studentId] = false;
          return "No calculation records matched for student ${student['StudentName']}!";
        }
      } else {
        calculatingIndividualMap[studentId] = false;
        return "Failed score calculation! Server replied with code: ${response.statusCode}";
      }
    } catch (e) {
      calculatingIndividualMap[studentId] = false;
      return "Network exception: $e";
    }
  }

  // -------------------------------------------------------------
  // METHOD: saveIndividualFinalGrade
  // Saves finalized grading info into student enrollment records
  // -------------------------------------------------------------
  Future<String?> saveIndividualFinalGrade({
    required Map<String, dynamic> student,
    required String userId,
    required String fypType,
  }) async {
    final studentId = student['StudentID']?.toString() ?? '';
    final enrollmentId = student['EnrollmentID'];

    final gradeVal = finalGrades[studentId]?['grade'] ?? calculatedScores[studentId]?['grade'];
    final scoreVal = finalGrades[studentId]?['score'] ?? calculatedScores[studentId]?['score'];

    if (gradeVal == null || scoreVal == null) {
      return "Please trigger calculation first before saving the final grade!";
    }

    savingGradeIndividualMap[studentId] = true;

    try {
      final List<Map<String, dynamic>> payload = [{
        "EnrollmentID": enrollmentId,
        "FinalGrade": gradeVal.toString(),
        "FinalScore": double.tryParse(scoreVal.toString()) ?? 0.0,
        "SessionID": sessionId,
        "EvaluatorID": userId,
      }];

      final String scoreApi = fypType.toLowerCase() == "fyp-2" ? "fyp2-scores" : "fyp1-scores";
      final saveGradesUrl = Uri.parse("${ApiConfig.baseUrl}/$scoreApi/save-final-grades");
      debugPrint("--> [VVM Post] Saving Final Grade: $saveGradesUrl");
      final response = await http.post(
        saveGradesUrl,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(payload),
      );

      savingGradeIndividualMap[studentId] = false;
      if (response.statusCode == 200) {
        return null; // Success!
      } else {
        return "Failed to save final grade! Server replied with code: ${response.statusCode}";
      }
    } catch (e) {
      savingGradeIndividualMap[studentId] = false;
      return "Network exception: $e";
    }
  }
}
