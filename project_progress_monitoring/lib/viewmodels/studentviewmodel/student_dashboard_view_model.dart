import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../api_config.dart';

// --- VIEWMODEL ---
// This class contains the logic and API calls for the Student Dashboard.
// It separates the data-fetching from the UI drawing (VVM pattern).
class StudentDashboardViewModel {

  /// Fetches all the data needed for the student dashboard in one go.
  /// 
  /// The "Map" Cheat Sheet:
  /// We return a Map containing these keys:
  /// - 'groupName' (String)
  /// - 'groupId' (int or null)
  /// - 'projectTitle' (String)
  /// - 'supervisorName' (String)
  /// - 'tasks' (List of Maps)
  /// - 'meetings' (List of Maps)
  /// - 'notifications' (List of Maps)
  Future<Map<String, dynamic>> getDashboardData(String studentId) async {
    // We set up a default structure first, just in case some APIs fail.
    Map<String, dynamic> dashboardData = {
      "groupName": "No Group",
      "groupId": null,
      "projectTitle": "Not Assigned",
      "supervisorName": "Pending...",
      "tasks": [],
      "meetings": [],
      "supervisorMeetings": [], // Added to match React
      "notifications": []
    }; // End of Map

    try {
      // 1. Get student profile info
      final studentUrl = Uri.parse("${ApiConfig.baseUrl}/students/$studentId");
      debugPrint("--> [Primary Schooler Info] Visiting Student Profile address: $studentUrl");
      
      final studentRes = await http.get(studentUrl);
      debugPrint("<-- [Primary Schooler Info] Server enrollment responded Status Code: ${studentRes.statusCode}");
      debugPrint("<-- [Primary Schooler Info] Raw student profile data: ${studentRes.body}");
      
      int? groupId;
      String? fypType;

      if (studentRes.statusCode == 200 && studentRes.body.isNotEmpty) {
        final student = jsonDecode(studentRes.body);
        
        groupId = student['GroupId'] ?? student['groupId'];
        fypType = student['FypType'] ?? student['fypType'];
        
        dashboardData['groupName'] = groupId != null ? "Group $groupId" : "No Group";
        dashboardData['groupId'] = groupId;
        
        if (student['Supervisor'] != null) {
          dashboardData['supervisorName'] = student['Supervisor'];
        }
        
        if (student['Project'] != null) {
          dashboardData['projectTitle'] = student['Project'];
        }
      }

      // 2. Get Notifications
      final notifUrl = Uri.parse("${ApiConfig.baseUrl}/students/getNotifications/$studentId");
      debugPrint("--> [Primary Schooler Info] Fetching Student Notifications at: $notifUrl");
      
      final notifRes = await http.get(notifUrl);
      debugPrint("<-- [Primary Schooler Info] Notifications list responded Status Code: ${notifRes.statusCode}");
      debugPrint("<-- [Primary Schooler Info] Raw notifications data: ${notifRes.body}");
      
      if (notifRes.statusCode == 200 && notifRes.body.isNotEmpty) {
        List<dynamic> rawNotif = jsonDecode(notifRes.body);
        dashboardData['notifications'] = rawNotif.map((n) => n as Map<String, dynamic>).toList();
      }

      // 3. Get Upcoming Meetings and Tasks
      if (groupId != null && fypType != null) {
        // A. Upcoming Committee Meetings
        final meetingUrl = Uri.parse("${ApiConfig.baseUrl}/committee-meetings/meetings?type=$fypType&groupId=$groupId&filter=upcoming");
        debugPrint("--> [Primary Schooler Info] Fetching Committee Meetings at: $meetingUrl");
        
        final meetingRes = await http.get(meetingUrl);
        debugPrint("<-- [Primary Schooler Info] Committee Meetings responded Status Code: ${meetingRes.statusCode}");
        debugPrint("<-- [Primary Schooler Info] Raw committee meetings data: ${meetingRes.body}");

        if (meetingRes.statusCode == 200 && meetingRes.body.isNotEmpty) {
          List<dynamic> rawMeetings = jsonDecode(meetingRes.body);
          dashboardData['meetings'] = rawMeetings.map((m) => m as Map<String, dynamic>).toList();
        }

        // B. Upcoming Supervisor Meetings
        final supMeetingUrl = Uri.parse("${ApiConfig.baseUrl}/supervisor/group-meetings/$groupId");
        debugPrint("--> [Primary Schooler Info] Fetching Supervisor Meetings at: $supMeetingUrl");
        
        final supMeetingRes = await http.get(supMeetingUrl);
        debugPrint("<-- [Primary Schooler Info] Supervisor Meetings responded Status Code: ${supMeetingRes.statusCode}");
        debugPrint("<-- [Primary Schooler Info] Raw supervisor meetings data: ${supMeetingRes.body}");

        if (supMeetingRes.statusCode == 200 && supMeetingRes.body.isNotEmpty) {
          List<dynamic> rawSupMeetings = jsonDecode(supMeetingRes.body);
          
          // Filter out past meetings to only show upcoming ones (matching React logic)
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          
          dashboardData['supervisorMeetings'] = rawSupMeetings.where((m) {
            if (m['Date'] == null) return false;
            try {
              final mDate = DateTime.parse(m['Date']);
              // Reset hours to compare purely by date day
              final mDateOnly = DateTime(mDate.year, mDate.month, mDate.day);
              return mDateOnly.isAtSameMomentAs(today) || mDateOnly.isAfter(today);
            } catch (e) {
              debugPrint("!!! [Primary Schooler Error] Something went wrong parsing date: $e");
              return false;
            }
          }).toList();
        }

        // C. Tasks
        final taskUrl = Uri.parse("${ApiConfig.baseUrl}/supervisor/StudentTasks/$groupId/$studentId");
        debugPrint("--> [Primary Schooler Info] Fetching Student Tasks at: $taskUrl");
        
        final taskRes = await http.get(taskUrl);
        debugPrint("<-- [Primary Schooler Info] Student Tasks responded Status Code: ${taskRes.statusCode}");
        debugPrint("<-- [Primary Schooler Info] Raw student tasks data: ${taskRes.body}");

        if (taskRes.statusCode == 200 && taskRes.body.isNotEmpty) {
          List<dynamic> rawTasks = jsonDecode(taskRes.body);
          
          var formattedTasks = rawTasks
              .where((t) => t['taskStatus']?.toString().toLowerCase() != "completed")
              .map((t) {
            return {
              'id': t['id'],
              'title': t['title'] ?? "Untitled Task",
              'dueDate': t['dueDate'] ?? "No due date",
              'status': 'pending',
              'priority': 'medium'
            };
          }).toList();
          
          dashboardData['tasks'] = formattedTasks.take(3).toList();
        } // End of if (groupId != null)
      }

    } catch (e) {
      debugPrint("!!! [Primary Schooler Error] Error loading dashboard: $e");
    } // End of catch

    return dashboardData;
  } // End of getDashboardData method

  /// -------------------------------------------------------------------------
  /// WHAT IT DOES: Tells the server that the student has seen a specific alert.
  /// HOW IT WORKS: We send the unique ID of the alert to the "markNotificationRead" box.
  /// -------------------------------------------------------------------------
  Future<bool> markAsRead(int notificationId) async {
    try {
      // We use 'put' because we are updating an existing alert status.
      final url = Uri.parse("${ApiConfig.baseUrl}/students/markNotificationRead/$notificationId");
      debugPrint("--> [Primary Schooler Info] Visiting web address: $url");
      debugPrint("--> [Primary Schooler Info] Marking notification read: $url");
      
      final res = await http.put(url);
      debugPrint("<-- [Primary Schooler Info] Server responded: ${res.statusCode}");
      
      // If the server says "OK" (200), it worked!
      return res.statusCode == 200;
    } catch (e) {
      debugPrint("!!! [Primary Schooler Error] Oops! Couldn't mark alert as read: $e");
      return false;
    } // End of catch
  } // End of markAsRead method

  /// -------------------------------------------------------------------------
  /// WHAT IT DOES: Tells the server that the student has seen ALL their alerts.
  /// HOW IT WORKS: We send the Student's ID to the "markAllNotificationsRead" box.
  /// -------------------------------------------------------------------------
  Future<bool> markAllAsRead(String studentId) async {
    try {
      // Again, we use 'put' to update the status of many items at once.
      final url = Uri.parse("${ApiConfig.baseUrl}/students/markAllNotificationsRead/$studentId");
      debugPrint("--> [Primary Schooler Info] Visiting web address: $url");
      debugPrint("--> [Primary Schooler Info] Marking all notifications read: $url");
      
      final res = await http.put(url);
      debugPrint("<-- [Primary Schooler Info] Server responded: ${res.statusCode}");
      
      return res.statusCode == 200;
    } catch (e) {
      debugPrint("!!! [Primary Schooler Error] Oops! Couldn't mark all alerts as read: $e");
      return false;
    } // End of catch
  } // End of markAllAsRead method

  /// -------------------------------------------------------------------------
  /// WHAT IT DOES: Fetches student details (GroupId, FypType)
  /// -------------------------------------------------------------------------
  Future<Map<String, dynamic>?> getStudentDetails(String studentId) async {
    try {
      final url = Uri.parse("${ApiConfig.baseUrl}/students/$studentId");
      debugPrint("--> [Primary Schooler Info] Visiting web address: $url");
      debugPrint("--> [Primary Schooler Info] Fetching student details: $url");
      
      final response = await http.get(url);
      debugPrint("<-- [Primary Schooler Info] Server responded with Status Code: ${response.statusCode}");
      debugPrint("<-- [Primary Schooler Info] Raw JSON data received: ${response.body}");
      debugPrint("<-- [Primary Schooler Info] Server responded status: ${response.statusCode}");
      
      if (response.statusCode == 200) return jsonDecode(response.body);
    } catch (e) { debugPrint("!!! [Primary Schooler Error] Error fetching student details: $e"); }
    return null;
  }

  /// -------------------------------------------------------------------------
  /// WHAT IT DOES: Fetches Committee Meetings for a specific filter
  /// -------------------------------------------------------------------------
  Future<List<Map<String, dynamic>>> fetchMeetings(int groupId, String type, String filter) async {
    try {
      final url = Uri.parse("${ApiConfig.baseUrl}/committee-meetings/meetings?type=$type&groupId=$groupId&filter=$filter");
      debugPrint("--> [Primary Schooler Info] Visiting web address: $url");
      debugPrint("--> [Primary Schooler Info] Fetching filtered committee meetings: $url");
      
      final response = await http.get(url);
      debugPrint("<-- [Primary Schooler Info] Server responded with Status Code: ${response.statusCode}");
      debugPrint("<-- [Primary Schooler Info] Raw JSON data received: ${response.body}");
      debugPrint("<-- [Primary Schooler Info] Server responded status: ${response.statusCode}");
      
      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        return data.map((m) => m as Map<String, dynamic>).toList();
      }
    } catch (e) { debugPrint("!!! [Primary Schooler Error] Error fetching committee meetings ($filter): $e"); }
    return [];
  }

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
      final url = Uri.parse("${ApiConfig.baseUrl}/supervisor/group-meetings/$groupId");
      debugPrint("--> [Primary Schooler Info] Visiting web address: $url");
      debugPrint("--> [Primary Schooler Info] Fetching group supervisor meetings: $url");
      
      final response = await http.get(url);
      debugPrint("<-- [Primary Schooler Info] Server responded with Status Code: ${response.statusCode}");
      debugPrint("<-- [Primary Schooler Info] Raw JSON data received: ${response.body}");
      debugPrint("<-- [Primary Schooler Info] Server responded status: ${response.statusCode}");
      
      if (response.statusCode == 200) {
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
    } catch (e) { debugPrint("!!! [Primary Schooler Error] Error fetching supervisor meetings: $e"); }
    
    return results;
  }
} // End of StudentDashboardViewModel class