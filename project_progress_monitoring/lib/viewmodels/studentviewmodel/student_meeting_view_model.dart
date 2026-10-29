import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../api_config.dart';

// --- VIEWMODEL ---
// This class is the "Brain" of the Meeting screen.
// It handles all the fetching of data from the internet (API calls).
// It does not contain any UI code, making it easy to test and maintain.
class StudentMeetingViewModel {
  
  // Base API URL for committee meetings
  final String _baseUrl = "${ApiConfig.baseUrl}/committee-meetings";

  // 1. Get Student Details (Group ID, FYP Type, Session, etc.)
  // The "Map" Cheat Sheet:
  // The returned map contains keys like: 'regNum', 'name', 'gender', 'admissionSession', 'currentCGPA', 'studentDepartment', 'selectedTech', 'FypType', 'GroupId', 'Project', 'Supervisor'.
  Future<Map<String, dynamic>?> getStudentDetails(String regNum) async {
    try {
      // FYP TALKING POINT: "We use the student's registration number to fetch their full profile, which includes their Group ID and FYP enrollment type."
      final res = await http.get(Uri.parse("${ApiConfig.baseUrl}/students/$regNum"));
      if (res.statusCode == 200 && res.body.isNotEmpty) {
        return jsonDecode(res.body);
      } // End of if (res.statusCode == 200)
    } catch (e) {
      debugPrint("Error fetching student details: $e");
    } // End of catch (e)
    return null;
  } // End of getStudentDetails method

  // 2. Fetch Meetings by Category (Upcoming, Today, Past)
  // This is used in the Meeting List screen.
  // The "Map" Cheat Sheet:
  // Each map in the list represents a meeting and has keys like: 'id', 'title', 'date', 'time', 'location', 'type'.
  Future<List<Map<String, dynamic>>> fetchMeetings(int groupId, String type, String filter) async {
    try {
      // FYP TALKING POINT: "This is a dynamic query. By changing the 'filter' parameter to 'upcoming', 'today', or 'past', we reuse the same API endpoint to get different sets of data."
      final url = Uri.parse("$_baseUrl/meetings?type=$type&groupId=$groupId&filter=$filter");
      debugPrint("--> [Primary Schooler Info] Visiting web address: $url");
      final res = await http.get(url);
      
      if (res.statusCode == 200) {
        List data = jsonDecode(res.body);
        // We convert the list of dynamic objects into a list of Map<String, dynamic>
        return data.map((m) => m as Map<String, dynamic>).toList();
      } // End of if (res.statusCode == 200)
    } catch (e) {
      debugPrint("Error fetching $filter meetings: $e");
    } // End of catch (e)
    return [];
  } // End of fetchMeetings method

  // 3. Fetch Today's Live Queue
  // This shows ALL groups presenting today for a specific type (e.g., FYP-1).
  // The "Map" Cheat Sheet:
  // Each map in the list contains info about a group in the queue: 'groupId', 'groupName', 'status', 'presentationTime'.
  Future<List<Map<String, dynamic>>> getTodayLiveQueue(String type) async {
    try {
      // FYP TALKING POINT: "The Live Queue is essential for real-time monitoring. It tells the students exactly where they stand in today's presentation schedule."
      // Endpoint: api/committee-meetings/today-meetings/{type}
      final res = await http.get(Uri.parse("$_baseUrl/today-meetings/$type"));
      if (res.statusCode == 200) {
        List data = jsonDecode(res.body);
        // We convert the JSON to a simple List of Maps
        return data.map((m) => m as Map<String, dynamic>).toList();
      } // End of if (res.statusCode == 200)
    } catch (e) {
      debugPrint("Live Queue error: $e");
    } // End of catch (e)
    return [];
  } // End of getTodayLiveQueue method

  /// -------------------------------------------------------------------------
  /// WHAT IT DOES: Fetches Supervisor Meetings and categorizes them
  /// -------------------------------------------------------------------------
  Future<Map<String, List<Map<String, dynamic>>>> fetchSupervisorMeetings(int groupId) async {
    Map<String, List<Map<String, dynamic>>> results = {
      "upcoming": [],
      "today": [],
      "past": []
    };

    try {
      // FYP TALKING POINT: "We distinguish between Committee Meetings (Evaluations) and Supervisor Meetings (Weekly progress checks) to keep the student's schedule organized."
      final url = Uri.parse("${ApiConfig.baseUrl}/supervisor/group-meetings/$groupId");
      debugPrint("--> [Primary Schooler Info] Visiting web address: $url");
      final response = await http.get(url);
      debugPrint("<-- [Primary Schooler Info] Server responded with Status Code: ${response.statusCode}");
      debugPrint("<-- [Primary Schooler Info] Raw JSON data received: ${response.body}");
      
      if (response.statusCode == 200 && response.body.isNotEmpty) {
        List<dynamic> allMeetings = jsonDecode(response.body);
        
        final now = DateTime.now();
        final todayDate = DateTime(now.year, now.month, now.day);

        for (var m in allMeetings) {
          if (m['Date'] == null) continue;
          
          final mDate = DateTime.parse(m['Date']);
          final mDateOnly = DateTime(mDate.year, mDate.month, mDate.day);

          final mapped = {
            'scheduleId': m['Id'],
            'title': m['Title'] ?? "Supervisor Meeting",
            'date': m['Date'],
            'time': m['Time'],
            'location': m['Venue'] ?? "TBD",
            'isSupervisor': true
          };

          if (mDateOnly.isAtSameMomentAs(todayDate)) {
            results['today']!.add(mapped);
          } else if (mDateOnly.isAfter(todayDate)) {
            results['upcoming']!.add(mapped);
          } else {
            results['past']!.add(mapped);
          }
        }
      }
    } catch (e) { debugPrint("Error fetching supervisor meetings: $e"); }
    
    return results;
  }
} // End of StudentMeetingViewModel class