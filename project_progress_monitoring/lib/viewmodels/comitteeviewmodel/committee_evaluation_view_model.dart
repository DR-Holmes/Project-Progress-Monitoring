import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import '../../api_config.dart';

/// 🏫 SCHOOL LESSON: This ViewModel handles the logic for evaluating students.
/// It works for both FYP-1 and FYP-2 by changing the API endpoint dynamically.
class CommitteeEvaluationViewModel {
  bool isLoading = false;
  bool isSubmitting = false;
  bool isSavingRemark = false;

  // 📝 Data storage
  List<Map<String, dynamic>> students = [];
  Map<String, dynamic>? parameter;
  List<Map<String, dynamic>> subParameters = [];
  
  // 📝 Store scores: { "studentKey": { "subParamID": score } }
  Map<String, Map<int, dynamic>> marks = {};
  
  // 📝 Store remarks: { "studentKey": "remark text" }
  Map<String, String> remarks = {};
  
  // 📝 Store remark metadata (like last updated time)
  Map<String, Map<String, dynamic>?> remarkMeta = {};

  /// 🏫 SCHOOL LESSON: A helper to get a unique key for each student.
  /// Uses EnrollmentID if available, otherwise fallback to studentID.
  String getStudentKey(Map<String, dynamic> s) {
    if (s['EnrollmentID'] != null && s['EnrollmentID'] != 0) {
      return "E-${s['EnrollmentID']}";
    }
    final sId = s['studentID'] ?? s['StudentID'];
    return "S-$sId";
  }

  /// 🏫 SCHOOL LESSON: Fetches all data needed for the evaluation screen.
  Future<void> fetchData(int meetingId, int groupId, int parameterId, String fypType, String userId) async {
    isLoading = true;
    
    // Determine which API to use based on FYP type
    final String scoreApi = fypType.toLowerCase() == "fyp-2" ? "fyp2-scores" : "fyp1-scores";
    
    try {
      // 1. Fetch Students in the group
      final gRes = await http.get(Uri.parse("${ApiConfig.baseUrl}/$scoreApi/getDataForUpdateMarks/$groupId"));
      if (gRes.statusCode == 200) {
        students = List<Map<String, dynamic>>.from(json.decode(gRes.body));
      }

      // 2. Fetch Evaluation Panel (Parameters & Sub-parameters)
      final pRes = await http.get(Uri.parse("${ApiConfig.baseUrl}/$scoreApi/evaluation-panel/$meetingId"));
      if (pRes.statusCode == 200) {
        final panelData = json.decode(pRes.body);
        final List allParams = panelData['parameters'] ?? [];
        
        // Find the specific parameter we are evaluating
        parameter = allParams.firstWhere((p) => p['id'] == parameterId, orElse: () => null);
        if (parameter != null) {
          subParameters = List<Map<String, dynamic>>.from(parameter!['subParameters'] ?? []);
        }
      }

      // 3. Initialize marks map for each student
      for (var s in students) {
        final key = getStudentKey(s);
        marks[key] = {};
        for (var sp in subParameters) {
          marks[key]![sp['id']] = ""; // Empty initially
        }
      }

    } catch (e) {
      debugPrint("🏫 Error fetching evaluation data: $e");
    } finally {
      isLoading = false;
    }
  }

  /// 🏫 SCHOOL LESSON: Fetches the latest remarks for a specific student.
  Future<String> fetchStudentRemarks(Map<String, dynamic> student, String userId, String fypType, int meetingId) async {
    final key = getStudentKey(student);
    final bool isFyp2 = fypType.toLowerCase() == "fyp-2";
    final String scoreApi = isFyp2 ? "fyp2-scores" : "fyp1-scores";
    
    try {
      // 🏫 SCHOOL LESSON: FYP-2 uses a different route format than FYP-1
      // For FYP-2, the second URL parameter maps to 'taskID' in the controller
      final String url = isFyp2 
          ? "${ApiConfig.baseUrl}/$scoreApi/get/${student['EnrollmentID']}/${student['TaskId'] ?? 0}/$userId/${student['sessionID']}"
          : "${ApiConfig.baseUrl}/$scoreApi/get-remarks/${student['EnrollmentID']}/$userId/${student['sessionID']}";

      final res = await http.get(Uri.parse(url));
      
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        
        if (isFyp2) {
          // FYP-2 returns a single object { exists, remarks, ... }
          remarks[key] = data['remarks'] ?? "";
          remarkMeta[key] = {
            "createdAt": data['createdAt'],
          };
          return remarks[key]!;
        } else {
          // FYP-1 returns a list of remarks
          final List list = data;
          var selectedRemark = list.firstWhere((r) => r['meetingID'] == meetingId, orElse: () => null);
          if (selectedRemark == null && list.isNotEmpty) selectedRemark = list[0];

          if (selectedRemark != null) {
            remarks[key] = selectedRemark['remarks'] ?? "";
            remarkMeta[key] = {
              "createdAt": selectedRemark['createdAt'],
              "updatedAt": selectedRemark['updatedAt'],
            };
            return remarks[key]!;
          }
        }
      }
    } catch (e) {
      debugPrint("🏫 Error fetching remarks: $e");
    }
    return "";
  }

  /// 🏫 SCHOOL LESSON: Saves or updates a remark for a student.
  Future<bool> saveRemark(Map<String, dynamic> student, int meetingId, String evaluatorId, String fypType, String remarkText) async {
    isSavingRemark = true;
    final bool isFyp2 = fypType.toLowerCase() == "fyp-2";
    final String scoreApi = isFyp2 ? "fyp2-scores" : "fyp1-scores";
    final String endpoint = isFyp2 ? "save" : "save-or-update";

    try {
      // 🏫 SCHOOL LESSON: Matching keys EXACTLY to the C# DTOs provided
      final Map<String, dynamic> body = {
        "StudentEnrollID": student['EnrollmentID'],
        "EvaluatorID": evaluatorId,
        "SessionID": student['sessionID'],
        "Remarks": remarkText,
      };

      if (isFyp2) {
        body["taskID"] = student['TaskId'] ?? 0;
      } else {
        body["meetingID"] = meetingId;
      }

      final res = await http.post(
        Uri.parse("${ApiConfig.baseUrl}/$scoreApi/$endpoint"),
        headers: {"Content-Type": "application/json"},
        body: json.encode(body),
      );
      
      debugPrint("🏫 Save Remark Response: ${res.statusCode} - ${res.body}");
      return res.statusCode == 200;
    } catch (e) {
      debugPrint("🏫 Error saving remark: $e");
      return false;
    } finally {
      isSavingRemark = false;
    }
  }

  /// 🏫 SCHOOL LESSON: Submits all marks for all students in one go.
  Future<bool> submitAllMarks(int meetingId, int parameterId, String evaluatorId, String fypType) async {
    isSubmitting = true;
    final String scoreApi = fypType.toLowerCase() == "fyp-2" ? "fyp2-scores" : "fyp1-scores";
    final bool isFyp2 = fypType.toLowerCase() == "fyp-2";

    try {
      List<Map<String, dynamic>> payload = [];
      
      for (var s in students) {
        final key = getStudentKey(s);
        for (var sp in subParameters) {
          final val = marks[key]?[sp['id']];
          
          final Map<String, dynamic> item = {
            "EnrollmentID": s['EnrollmentID'],
            "ParameterID": parameterId,
            "SubParameterID": sp['id'],
            "EvaluatorID": evaluatorId,
            "ObtainedMarks": (val == null || val == "") ? 0 : double.tryParse(val.toString()) ?? 0,
            "MaxMarks": sp['percentage'], // Usually max marks is the weightage percentage
            "SessionID": s['sessionID'],
          };

          // 🏫 SCHOOL LESSON: FYP-1 uses MeetingID, FYP-2 uses taskID
          if (isFyp2) {
            item["taskID"] = s['TaskId'] ?? 0;
          } else {
            item["MeetingID"] = meetingId;
          }

          payload.add(item);
        }
      }

      final res = await http.post(
        Uri.parse("${ApiConfig.baseUrl}/$scoreApi/update-evaluation-marks"),
        headers: {"Content-Type": "application/json"},
        body: json.encode(payload),
      );
      
      debugPrint("🏫 Submit Marks Payload: ${json.encode(payload)}");
      debugPrint("🏫 Submit Marks Response: ${res.statusCode} - ${res.body}");
      
      return res.statusCode == 200;
    } catch (e) {
      debugPrint("🏫 Error submitting marks: $e");
      return false;
    } finally {
      isSubmitting = false;
    }
  }
}