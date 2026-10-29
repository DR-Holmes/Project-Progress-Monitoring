import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../api_config.dart';

// PRIMARY SCHOOLER NOTE: This is the "Brain" for the Meeting Details Screen.
// It handles fetching the meeting, group, tasks, remarks, and saving attendance.
class SupervisorMeetingDetailsViewModel {
  bool isLoading = false;
  
  Map<String, dynamic>? meeting;
  Map<String, dynamic>? group;
  List<Map<String, dynamic>> tasks = [];
  
  String groupRemark = "";
  
  // Stores attendance and remarks using the student's ID or EnrollmentID as the key
  Map<String, bool> attendance = {};
  Map<String, String> studentRemarks = {};

  /// Load everything needed for this meeting
  Future<void> loadAllData(String meetingId, String supervisorId) async {
    isLoading = true;
    try {
      // 1. Load Meeting Details
      await _loadMeeting(meetingId);
      
      if (meeting != null) {
        String groupId = meeting!['groupID']?.toString() ?? meeting!['GroupId']?.toString() ?? "";
        
        if (groupId.isNotEmpty) {
          // 2. Load Group Details & Tasks
          await _loadGroup(groupId, supervisorId, meetingId);
          await _loadTasks(groupId);
          await _loadGroupRemark(groupId, supervisorId, meetingId);
        }
      }
    } catch (e) {
      debugPrint("Error loading all data: $e");
    } finally {
      isLoading = false;
    }
  }

  // ================= INTERNAL LOADERS =================

  Future<void> _loadMeeting(String meetingId) async {
    try {
      final url = Uri.parse("${ApiConfig.baseUrl}/supervisor/meetings/$meetingId");
      final res = await http.get(url);
      
      if (res.statusCode == 200) {
        meeting = jsonDecode(res.body);
      }
    } catch (e) {
      debugPrint("Failed to load meeting: $e");
    }
  }

  Future<void> _loadGroup(String groupId, String supervisorId, String meetingId) async {
    try {
      final url = Uri.parse("${ApiConfig.baseUrl}/supervisor/groups/$groupId");
      final res = await http.get(url);
      
      if (res.statusCode == 200) {
        group = jsonDecode(res.body);
        
        // Initialize attendance and remarks dictionaries for each student
        List<dynamic> members = group!['Members'] ?? [];
        for (var m in members) {
          String studentId = m['id']?.toString() ?? "";
          String enrollId = m['EnrollmentID']?.toString() ?? m['enrollmentID']?.toString() ?? "";
          
          if (studentId.isNotEmpty) {
            attendance[studentId] = false;
            studentRemarks[studentId] = "";
            
            // Fetch existing individual remarks
            if (enrollId.isNotEmpty) {
              await _loadStudentRemark(enrollId, studentId, supervisorId, meetingId);
            }
          }
        }
      }
    } catch (e) {
      debugPrint("Failed to load group: $e");
    }
  }

  Future<void> _loadTasks(String groupId) async {
    try {
      final url = Uri.parse("${ApiConfig.baseUrl}/supervisor/GroupTasks/$groupId");
      final res = await http.get(url);
      
      if (res.statusCode == 200) {
        List<dynamic> data = jsonDecode(res.body);
        tasks = data.map((e) => e as Map<String, dynamic>).toList();
      }
    } catch (e) {
      debugPrint("Failed to load tasks: $e");
    }
  }

  Future<void> _loadGroupRemark(String groupId, String supervisorId, String meetingId) async {
    try {
      final url = Uri.parse("${ApiConfig.baseUrl}/supervisor/get-group-remarks/$groupId/$supervisorId/$meetingId");
      final res = await http.get(url);
      
      if (res.statusCode == 200 && res.body.isNotEmpty) {
        Map<String, dynamic> data = jsonDecode(res.body);
        groupRemark = data['Remarks'] ?? data['remarks'] ?? "";
      }
    } catch (e) {
      groupRemark = "";
    }
  }

  Future<void> _loadStudentRemark(String enrollId, String studentId, String supervisorId, String meetingId) async {
    try {
      final url = Uri.parse("${ApiConfig.baseUrl}/supervisor/get-supervisor-remarks/$enrollId/$supervisorId/$meetingId");
      final res = await http.get(url);
      
      if (res.statusCode == 200 && res.body.isNotEmpty) {
        Map<String, dynamic> data = jsonDecode(res.body);
        studentRemarks[studentId] = data['Remarks'] ?? data['remarks'] ?? "";
      }
    } catch (e) {
      // ignore
    }
  }

  // ================= ACTIONS =================

  /// Save all checked attendances to the server
  Future<bool> saveAttendance(String meetingId) async {
    try {
      // Build the list of attendance objects
      List<Map<String, dynamic>> attendanceList = [];
      attendance.forEach((studentId, isPresent) {
        attendanceList.add({
          "memberId": int.tryParse(studentId) ?? 0,
          "isPresent": isPresent
        });
      });

      Map<String, dynamic> payload = {
        "meetingId": meetingId,
        "attendance": attendanceList
      };

      final url = Uri.parse("${ApiConfig.baseUrl}/supervisor/studentAttendance");
      final res = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(payload),
      );

      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) {
      debugPrint("Failed to save attendance: $e");
      return false;
    }
  }

  /// Save group-level remark
  Future<bool> saveGroupRemark(String meetingId, String supervisorId) async {
    try {
      String groupId = meeting!['groupID']?.toString() ?? meeting!['GroupId']?.toString() ?? "";
      
      Map<String, dynamic> payload = {
        "MeetingID": meetingId,
        "GroupID": groupId,
        "StudentEnrollID": null, // null means it's a group remark
        "SupervisorID": supervisorId,
        "Remarks": groupRemark
      };

      final url = Uri.parse("${ApiConfig.baseUrl}/supervisor/save-supervisor-remarks");
      final res = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(payload),
      );

      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) {
      debugPrint("Failed to save group remark: $e");
      return false;
    }
  }

  /// Save individual student remark
  Future<bool> saveStudentRemark(String meetingId, String supervisorId, String studentId, String enrollId) async {
    try {
      String groupId = meeting!['groupID']?.toString() ?? meeting!['GroupId']?.toString() ?? "";
      
      Map<String, dynamic> payload = {
        "MeetingID": meetingId,
        "GroupID": groupId,
        "StudentEnrollID": enrollId, 
        "SupervisorID": supervisorId,
        "Remarks": studentRemarks[studentId] ?? ""
      };

      final url = Uri.parse("${ApiConfig.baseUrl}/supervisor/save-supervisor-remarks");
      final res = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(payload),
      );

      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) {
      debugPrint("Failed to save student remark: $e");
      return false;
    }
  }
}
