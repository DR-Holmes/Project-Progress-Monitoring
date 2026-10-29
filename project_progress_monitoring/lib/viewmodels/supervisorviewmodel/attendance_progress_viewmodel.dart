import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../api_config.dart';

class AttendanceProgressViewModel {
  // 🏫 SCHOOL LESSON: We use a List of Maps to store our group data!
  // This is easier for beginners than creating complex Model classes.
  List<Map<String, dynamic>> groups = [];
  bool isLoading = false;

  /// 🏫 SCHOOL LESSON: This function fetches groups and then fetches attendance for each group!
  /// It's like going to the market to get a list of fruits, and then checking the price of each one.
  Future<void> loadAttendanceData(String supervisorId, String fypType) async {
    isLoading = true;
    groups = [];

    try {
      // 1️⃣ Step 1: Get all groups for this supervisor
      // Endpoint: /supervisor/getAllGroups/{fypType}/{supervisorId}
      final groupsUrl = Uri.parse("${ApiConfig.baseUrl}/supervisor/getAllGroups/$fypType/$supervisorId");
      final groupsResponse = await http.get(groupsUrl);

      if (groupsResponse.statusCode == 200) {
        List<dynamic> groupsData = json.decode(groupsResponse.body);

        // 2️⃣ Step 2: For each group, get the attendance percentages of its members
        // This is like a "Loop" where we ask for details group by group.
        for (var group in groupsData) {
          int groupId = group['groupName']; // Backend uses groupName as the ID in this endpoint
          
          final attendanceUrl = Uri.parse("${ApiConfig.baseUrl}/supervisor/get-group-members-attendance/$groupId");
          final attendanceResponse = await http.get(attendanceUrl);

          if (attendanceResponse.statusCode == 200) {
            List<dynamic> attendanceList = json.decode(attendanceResponse.body);

            // 3️⃣ Step 3: Match the attendance data with the students in the group
            List<dynamic> members = group['members'] ?? [];
            List<Map<String, dynamic>> updatedMembers = [];

            for (var member in members) {
              // Find the attendance percentage for this specific student name
              final found = attendanceList.firstWhere(
                (a) => a['name'] == member['studentName'],
                orElse: () => null,
              );

              // 🏫 SCHOOL LESSON: We use "..." spread style logic to add a new field!
              updatedMembers.add({
                'studentName': member['studentName'],
                'studentRegNum': member['studentRegNum'],
                'Cgpa': member['Cgpa'],
                'attendancePercentage': found != null ? found['attendancePercentage'] : 0,
              });
            }

            // Add the final group package to our list
            groups.add({
              'groupName': group['groupName'],
              'projectTitle': group['projectTitle'],
              'members': updatedMembers,
            });
          }
        }
      }
    } catch (e) {
    } finally {
      isLoading = false;
    }
  }
}