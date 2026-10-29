import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../api_config.dart';

class QueueHandlerDashboardViewModel {
  // This is the base URL for our API. We use this to talk to the server.
  // It connects to the "committee-m
  // eetings" section of the backend.
  final String _baseUrl = "${ApiConfig.baseUrl}/committee-meetings";

  /// -------------------------------------------------------------------------
  /// WHAT IT DOES: Fetches all meetings happening today.
  /// WHY IT EXISTS: To show the queue handler what is scheduled for today.
  /// HOW IT WORKS: It sends a GET request to the server with the type of project (FYP-1 or FYP-2).
  /// It receives a list of JSON data, decodes it, and returns a List of Maps.
  /// -------------------------------------------------------------------------
  Future<List<Map<String, dynamic>>> fetchTodayMeetings(String type, {int? meetingId}) async {
    try {
      // Create the URL. If meetingId is provided, we add it to the end.
      String url = "$_baseUrl/today-meetings/$type";
      if (meetingId != null) {
        url += "/$meetingId";
      }

      // Send the request to the backend
      final response = await http.get(Uri.parse(url));
      debugPrint("<-- [Primary Schooler Info] Server responded with Status Code: ${response.statusCode}");
      debugPrint("<-- [Primary Schooler Info] Raw JSON data received: ${response.body}");
      
      // If the server says "OK" (status code 200), we decode the data.
      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        
        // Convert the dynamic list into a List<Map<String, dynamic>> so it's easy to use in Flutter.
        return data.map((e) => e as Map<String, dynamic>).toList();
      }
    } catch (e) {
      // If there is an error (like no internet), we print it here.
      debugPrint("Error fetching meetings: $e");
    }
    // Return an empty list if something went wrong
    return [];
  }

  /// -------------------------------------------------------------------------
  /// WHAT IT DOES: Saves the new order of the queue after drag-and-drop.
  /// WHY IT EXISTS: To let the server know that the queue order has changed.
  /// HOW IT WORKS: It loops through the new list, assigns a new estimated time,
  /// and sends this data back to the server.
  /// -------------------------------------------------------------------------
  Future<bool> updateQueueOrder(List<Map<String, dynamic>> queueList) async {
    try {
      final now = DateTime.now(); // Get the current time
      List<Map<String, dynamic>> payload = []; // Prepare the data to send
      
      // Loop through each item in the reordered list
      for (int i = 0; i < queueList.length; i++) {
        final item = queueList[i];
        
        // Give each group a new time, spaced out by 15 minutes
        final newTime = now.add(Duration(minutes: i * 15)); 
        
        // Add the group's updated information to our payload
        payload.add({
          "ComiteeMeetingID": item['id'], 
          "GroupID": item['groupID'],
          "EstimatedTime": "${newTime.hour.toString().padLeft(2, '0')}:${newTime.minute.toString().padLeft(2, '0')}:00"
        });
      }

      // Send the payload to the server
      final response = await http.post(
        Uri.parse("$_baseUrl/update-meeting-times"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(payload),
      );
      debugPrint("<-- [Primary Schooler Info] Server responded with Status Code: ${response.statusCode}");
      debugPrint("<-- [Primary Schooler Info] Raw JSON data received: ${response.body}");
      
      // Return true if the server accepted it successfully
      return response.statusCode == 200;
    } catch (e) {
      debugPrint("Error updating order: $e");
      return false; // Return false if it failed
    }
  }

  /// -------------------------------------------------------------------------
  /// WHAT IT DOES: Asks the server to prioritize female members in the queue.
  /// WHY IT EXISTS: To push groups with female members to the top of the line.
  /// -------------------------------------------------------------------------
  Future<List<Map<String, dynamic>>> prioritizeFemaleMembers(int meetingId) async {
    try {
      final response = await http.get(Uri.parse("$_baseUrl/today-meetings-priority/$meetingId"));
      debugPrint("<-- [Primary Schooler Info] Server responded with Status Code: ${response.statusCode}");
      debugPrint("<-- [Primary Schooler Info] Raw JSON data received: ${response.body}");
      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        return data.map((e) => e as Map<String, dynamic>).toList(); // Convert to standard map list
      }
    } catch (e) {
      debugPrint("Error prioritizing by gender: $e");
    }
    return [];
  }

  /// -------------------------------------------------------------------------
  /// WHAT IT DOES: Asks the server to group the queue by supervisors.
  /// WHY IT EXISTS: So supervisors don't have to wait scattered times.
  /// -------------------------------------------------------------------------
  Future<List<Map<String, dynamic>>> prioritizeSupervisorMembers(int meetingId) async {
    try {
      final response = await http.get(Uri.parse("$_baseUrl/today-meetings-supervisor-priority/$meetingId"));
      debugPrint("<-- [Primary Schooler Info] Server responded with Status Code: ${response.statusCode}");
      debugPrint("<-- [Primary Schooler Info] Raw JSON data received: ${response.body}");
      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        return data.map((e) => e as Map<String, dynamic>).toList();
      }
    } catch (e) {
      debugPrint("Error prioritizing by supervisor: $e");
    }
    return [];
  }

  /// -------------------------------------------------------------------------
  /// WHAT IT DOES: Synchronizes the queue order globally on the server.
  /// WHY IT EXISTS: After pressing priority sort buttons, we need to save the new order.
  /// HOW IT WORKS: Sends a list of schedule IDs to the backend.
  /// -------------------------------------------------------------------------
  Future<bool> updateQueueOrderGlobally(List<int> scheduleIds) async {
    try {
      final response = await http.post(
        Uri.parse("$_baseUrl/update-queue-order"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(scheduleIds),
      );
      debugPrint("<-- [Primary Schooler Info] Server responded with Status Code: ${response.statusCode}");
      debugPrint("<-- [Primary Schooler Info] Raw JSON data received: ${response.body}");
      return response.statusCode == 200; // true if successful
    } catch (e) {
      debugPrint("Error syncing queue order: $e");
      return false;
    }
  }

  /// -------------------------------------------------------------------------
  /// WHAT IT DOES: Updates the status of a group (Waiting, In-Progress, Completed).
  /// WHY IT EXISTS: So the queue handler can move groups through the meeting stages.
  /// -------------------------------------------------------------------------
  Future<bool> updateGroupStatus(int groupId, int meetingId, String status) async {
    try {
      final response = await http.post(
        Uri.parse("$_baseUrl/update-group-status"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "GroupId": groupId,
          "MeetingId": meetingId,
          "Status": status
        }),
      );
      debugPrint("<-- [Primary Schooler Info] Server responded with Status Code: ${response.statusCode}");
      debugPrint("<-- [Primary Schooler Info] Raw JSON data received: ${response.body}");
      return response.statusCode == 200;
    } catch (e) {
      debugPrint("Error updating status: $e");
      return false;
    }
  }

  /// -------------------------------------------------------------------------
  /// WHAT IT DOES: Sends a "Present" or "Absent" status for one student to the server.
  /// -------------------------------------------------------------------------
  Future<bool> updateStudentAttendance(int scheduleId, dynamic studentId, bool isAttended) async {
    try {
      // We convert the ID to a string because that's what the DTO expects.
      // But we also log it so we can see if it's a RegNum (like 2021-CS-1) or a Number (like 105).
      String idToSend = studentId.toString();

      final response = await http.post(
        Uri.parse("$_baseUrl/update-student-attendance"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "scheduleId": scheduleId,
          "studentId": idToSend,
          "isAttended": isAttended
        }),
      );
      debugPrint("<-- [Primary Schooler Info] Server responded with Status Code: ${response.statusCode}");
      debugPrint("<-- [Primary Schooler Info] Raw JSON data received: ${response.body}");
      
      if (response.statusCode == 200) {
        return true;
      } else {
        // If the server says "Meeting Schedule Not Found", it means the backend
        // needs to be updated to CREATE the record if it doesn't exist.
        debugPrint("Attendance Failed! ID: $idToSend, Code: ${response.statusCode}, Msg: ${response.body}");
        return false;
      }
    } catch (e) {
      debugPrint("Error updating student attendance: $e");
      return false;
    }
  }

  /// -------------------------------------------------------------------------
  /// WHAT IT DOES: Marks the entire group as having arrived at the meeting.
  /// -------------------------------------------------------------------------
  Future<bool> updateGroupAttendance(int groupId, int meetingId, bool isAttended) async {
    try {
      final response = await http.post(
        Uri.parse("$_baseUrl/update-group-attendance"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "GroupId": groupId,
          "MeetingId": meetingId,
          "IsAttended": isAttended
        }),
      );
      debugPrint("<-- [Primary Schooler Info] Server responded with Status Code: ${response.statusCode}");
      debugPrint("<-- [Primary Schooler Info] Raw JSON data received: ${response.body}");
      
      if (response.statusCode == 200) {
        return true;
      } else {
        debugPrint("Group Attendance Failed! Code: ${response.statusCode}, Msg: ${response.body}");
        return false;
      }
    } catch (e) {
      debugPrint("Error updating group attendance: $e");
      return false;
    }
  }

  /// -------------------------------------------------------------------------
  /// WHAT IT DOES: Triggers the server to recalculate the estimated start times for everyone.
  /// WHY IT EXISTS: To keep the live queue self-healing (if someone is late, times adjust automatically).
  /// -------------------------------------------------------------------------
  Future<bool> updateMeetingTimesDynamic() async {
    try {
      final response = await http.post(Uri.parse("$_baseUrl/update-meeting-times-dynamic"));
      debugPrint("<-- [Primary Schooler Info] Server responded with Status Code: ${response.statusCode}");
      debugPrint("<-- [Primary Schooler Info] Raw JSON data received: ${response.body}");
      return response.statusCode == 200;
    } catch (e) {
      debugPrint("Error auto-updating times: $e");
      return false;
    }
  }

  /// -------------------------------------------------------------------------
  /// WHAT IT DOES: Gets the current attendance status of a group.
  /// WHY IT EXISTS: To show the checkbox checked or unchecked in the app.
  /// -------------------------------------------------------------------------
  Future<bool> fetchGroupAttendance(int groupId, int meetingId) async {
    try {
      // We ask the server: "Has this whole group arrived?"
      final response = await http.get(Uri.parse("$_baseUrl/get-group-attendance?groupId=$groupId&meetingId=$meetingId"));
      debugPrint("<-- [Primary Schooler Info] Server responded with Status Code: ${response.statusCode}");
      debugPrint("<-- [Primary Schooler Info] Raw JSON data received: ${response.body}");
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // The server tells us true or false
        return data['IsAttend'] == true; 
      }
    } catch (e) {
      debugPrint("Error fetching group attendance: $e");
    }
    // If something goes wrong, we assume they aren't here yet.
    return false;
  }

  /// -------------------------------------------------------------------------
  /// WHAT IT DOES: Gets the attendance status for one specific student.
  /// WHY IT EXISTS: To show if "Student A" is present even if the whole group hasn't started.
  /// -------------------------------------------------------------------------
  Future<bool> fetchStudentAttendance(int scheduleId, String studentId) async {
    try {
      // We ask the server about this specific student
      final response = await http.get(Uri.parse("$_baseUrl/get-student-attendance?scheduleId=$scheduleId&studentId=$studentId"));
      debugPrint("<-- [Primary Schooler Info] Server responded with Status Code: ${response.statusCode}");
      debugPrint("<-- [Primary Schooler Info] Raw JSON data received: ${response.body}");
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['IsAttend'] == true;
      }
    } catch (e) {
      // Note: If the server returns 400 because the record doesn't exist, it's fine.
      // It just means they haven't been marked yet.
      debugPrint("Info: Student attendance record not found or error: $e");
    }
    return false;
  }
  
  /// -------------------------------------------------------------------------
  /// WHAT IT DOES: Filters the 'today meetings' list to find a specific meeting.
  /// WHY IT EXISTS: To quickly grab the queue for the meeting the user selected.
  /// -------------------------------------------------------------------------
  Future<List<Map<String, dynamic>>> fetchMeetingQueue(int meetingId, String type) async {
    // We now pass the meetingId directly to the API for better performance.
    return await fetchTodayMeetings(type, meetingId: meetingId);
  }
  
  /// -------------------------------------------------------------------------
  /// WHAT IT DOES: Gets the list of students inside a specific group.
  /// WHY IT EXISTS: To show the individual students when a group is tapped.
  /// -------------------------------------------------------------------------
  Future<List<Map<String, dynamic>>> fetchGroupDetails(int groupId) async {
    try {
      // We use the new endpoint from the CommitteeMeetingsController
      final response = await http.get(Uri.parse("$_baseUrl/groups-details/$groupId"));
      debugPrint("<-- [Primary Schooler Info] Server responded with Status Code: ${response.statusCode}");
      debugPrint("<-- [Primary Schooler Info] Raw JSON data received: ${response.body}");
      if (response.statusCode == 200) {
        // The backend returns an object with a "members" list
        Map<String, dynamic> data = jsonDecode(response.body);
        List<dynamic> members = data['members'] ?? [];
        
        return members.map((e) => e as Map<String, dynamic>).toList();
      }
    } catch (e) {
      debugPrint("Error fetching group details: $e");
    }
    return [];
  }

  /// -------------------------------------------------------------------------
  /// WHAT IT DOES: Fetches the current active session ID from the backend.
  /// WHY IT EXISTS: To ensure meetings are created/managed for the right year/term.
  /// -------------------------------------------------------------------------
  Future<int?> getCurrentSessionId() async {
    try {
      final response = await http.get(Uri.parse("${ApiConfig.baseUrl}/users/CurrentSession"));
      debugPrint("<-- [Primary Schooler Info] Server responded with Status Code: ${response.statusCode}");
      debugPrint("<-- [Primary Schooler Info] Raw JSON data received: ${response.body}");
      if (response.statusCode == 200) {
        return jsonDecode(response.body)['id'];
      }
    } catch (e) {
      debugPrint("Error fetching current session: $e");
    }
    return null;
  }



  /// -------------------------------------------------------------------------
  /// WHAT IT DOES: Handles big delays, like "Merge into Next" or "Create New".
  /// WHY IT EXISTS: If a whole session is running extremely late.
  /// RETURNS: A Map with {'success': bool, 'message': String}
  /// -------------------------------------------------------------------------
  Future<Map<String, dynamic>> handleDelay(Map<String, dynamic> payload) async {
    try {
      final response = await http.post(
        Uri.parse("$_baseUrl/handle-delay"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(payload),
      );
      debugPrint("<-- [Primary Schooler Info] Server responded with Status Code: ${response.statusCode}");
      debugPrint("<-- [Primary Schooler Info] Raw JSON data received: ${response.body}");
      
      if (response.statusCode == 200) {
        return {"success": true, "message": "Success"};
      } else {
        // Try to get the error message from the server response
        String errorMsg = "Server Error";
        try {
          final data = jsonDecode(response.body);
          errorMsg = data['Message'] ?? data['message'] ?? response.body;
        } catch (_) {}
        return {"success": false, "message": errorMsg};
      }
    } catch (e) {
      debugPrint("Error handling delay: $e");
      return {"success": false, "message": "Network Error"};
    }
  }
}