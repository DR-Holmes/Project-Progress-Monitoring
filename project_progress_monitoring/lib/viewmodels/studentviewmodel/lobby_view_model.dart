import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../api_config.dart';

// --- VIEWMODEL ---
// PRIMARY SCHOOLER NOTE: This class handles all the "Data Work" for the Group Lobby.
// It deals with group members, invitations, and finalization.
class LobbyViewModel {

  /// 1. Fetch My Group Details
  // The "Map" Cheat Sheet:
  // Expected return: { 'groupId': int, 'studentId': String, 'members': List<Map> }
  // Each member Map has: 'regNum', 'name', 'Cgpa', 'technology', 'isAdmin'.
  Future<Map<String, dynamic>?> getMyGroup(String regNum) async {
    try {
      // FYP TALKING POINT: "We fetch the group details based on the student's registration number. This ensures that every member sees the same consistent team information."
      final url = Uri.parse("${ApiConfig.baseUrl}/users/GetMyGroup/$regNum");
      debugPrint("--> [Primary Schooler Info] Visiting web address: $url");
      
      final response = await http.get(url);
      debugPrint("<-- [Primary Schooler Info] Server responded with Status Code: ${response.statusCode}");
      debugPrint("<-- [Primary Schooler Info] Raw JSON data received: ${response.body}");

      if (response.statusCode == 200 && response.body.isNotEmpty && response.body != "null") {
        return jsonDecode(response.body);
      } // End of if (response.statusCode == 200)
      return null;
    } catch (e) {
      debugPrint("Error fetching group: $e");
      return null;
    } // End of catch (e)
  } // End of getMyGroup method

  /// 2. Check if student is Admin
  Future<bool> checkIsAdmin(String regNum) async {
    try {
      // FYP TALKING POINT: "We have a dedicated API check for Admin status. Only the student who created the group is an Admin and has the power to manage members."
      final url = Uri.parse("${ApiConfig.baseUrl}/users/IsAdmin/$regNum");
      debugPrint("--> [Primary Schooler Info] Visiting web address: $url");
      
      final response = await http.get(url);
      debugPrint("<-- [Primary Schooler Info] Server responded with Status Code: ${response.statusCode}");
      debugPrint("<-- [Primary Schooler Info] Raw JSON data received: ${response.body}");
      
      if (response.statusCode == 200) {
        return response.body.toLowerCase() == 'true';
      } // End of if (response.statusCode == 200)
      return false;
    } catch (e) {
      debugPrint("Error checking admin: $e");
      return false;
    } // End of catch (e)
  } // End of checkIsAdmin method

  /// 3. Fetch Pending Requests Sent by the Group (Invites)
  // The "List" Cheat Sheet:
  // Each request in the list has: 'RequestID', 'MemberRegNum', 'Status'.
  Future<List<dynamic>> getGroupRequests(String regNum) async {
    try {
      // FYP TALKING POINT: "The Admin needs to see who they have already invited so they don't send duplicate requests to the same student."
      final url = Uri.parse("${ApiConfig.baseUrl}/users/GetGroupRequests/$regNum");
      debugPrint("--> [Primary Schooler Info] Visiting web address: $url");
      
      final response = await http.get(url);
      debugPrint("<-- [Primary Schooler Info] Server responded with Status Code: ${response.statusCode}");
      debugPrint("<-- [Primary Schooler Info] Raw JSON data received: ${response.body}");
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } // End of if (response.statusCode == 200)
      return [];
    } catch (e) {
      debugPrint("Error fetching group requests: $e");
      return [];
    } // End of catch (e)
  } // End of getGroupRequests method

  /// 4. Fetch Available Students for Invitation
  // This finds students from DIFFERENT technologies for interdisciplinary projects.
  Future<List<dynamic>> getAvailableStudents(String regNum) async {
    try {
      // Step A: Get My Details to find My Technology Name
      final meUrl = Uri.parse("${ApiConfig.baseUrl}/users/StudentDetails/$regNum");
      final meResponse = await http.get(meUrl);

      if (meResponse.statusCode != 200) return [];

      final meDataList = jsonDecode(meResponse.body);
      if (meDataList is List && meDataList.isNotEmpty) {
        String myTechName = meDataList[0]['TechnologyName'];

        // Step B: Get Students from DIFFERENT Technologies
        // FYP TALKING POINT: "To encourage interdisciplinary projects, our system specifically filters for students who are in a different technology than the current group admin."
        final searchUrl = Uri.parse("${ApiConfig.baseUrl}/users/StudentByTech/${Uri.encodeComponent(myTechName)}/$regNum");
        final searchResponse = await http.get(searchUrl);

        if (searchResponse.statusCode == 200) {
          return jsonDecode(searchResponse.body);
        } // End of if (searchResponse.statusCode == 200)
      } // End of if (meDataList is List)
      return [];
    } catch (e) {
      debugPrint("Error fetching students: $e");
      return [];
    } // End of catch (e)
  } // End of getAvailableStudents method

  /// 5. Send Group Invites (CreateGroupRequest)
  Future<bool> sendInvites(String fromRegNum, List<String> selectedStudents) async {
    try {
      // 1. Get Current Session
      final sessionUrl = Uri.parse("${ApiConfig.baseUrl}/users/CurrentSession");
      final sessionRes = await http.get(sessionUrl);
      int sessionId = 0;
      if (sessionRes.statusCode == 200) {
        sessionId = jsonDecode(sessionRes.body)['id'];
      } else {
        return false;
      } // End of if (sessionRes.statusCode == 200)

      // 2. Create/Ensure Group Exists
      // FYP TALKING POINT: "Before sending invites, we ensure a group record exists in the database. If it doesn't, we create one automatically."
      final createGroupUrl = Uri.parse("${ApiConfig.baseUrl}/users/CreateGroup");
      await http.post(
        createGroupUrl,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "createdBy": fromRegNum,
          "isFinalized": 0,
          "createdSession": sessionId,
        }),
      ); // End of http.post

      // 3. Now send the actual invites
      final url = Uri.parse("${ApiConfig.baseUrl}/users/CreateGroupRequest");
      debugPrint("--> [Primary Schooler Info] Visiting web address: $url");
      final body = jsonEncode({
        "fromRegNum": fromRegNum,
        "sessionId": sessionId,
        "members": selectedStudents
      }); // End of jsonEncode

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: body,
      ); // End of http.post

      debugPrint("<-- [Primary Schooler Info] Server responded with Status Code: ${response.statusCode}");
      debugPrint("<-- [Primary Schooler Info] Raw JSON data received: ${response.body}");
      return response.statusCode == 200;
    } catch (e) {
      debugPrint("Error sending invites: $e");
      return false;
    } // End of catch (e)
  } // End of sendInvites method

  /// 6. Finalize Group
  Future<bool> finalizeGroup(int groupId) async {
    try {
      // FYP TALKING POINT: "Finalization is a critical step. Once a group is finalized, the team is 'locked' and they can officially begin their project work."
      final url = Uri.parse("${ApiConfig.baseUrl}/users/FinalizeGroup");
      debugPrint("--> [Primary Schooler Info] Visiting web address: $url");
      final body = jsonEncode({ "GroupId": groupId });

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: body,
      ); // End of http.post

      debugPrint("<-- [Primary Schooler Info] Server responded with Status Code: ${response.statusCode}");
      debugPrint("<-- [Primary Schooler Info] Raw JSON data received: ${response.body}");
      return response.statusCode == 200;
    } catch (e) {
      debugPrint("Error finalizing: $e");
      return false;
    } // End of catch (e)
  } // End of finalizeGroup method

  /// 7. Remove Member
  Future<bool> removeMember(int groupId, String memberRegNum) async {
    try {
      // FYP TALKING POINT: "The Admin can remove members if they choose to change their team before finalization. This provides flexibility during the group formation phase."
      final url = Uri.parse("${ApiConfig.baseUrl}/users/RemoveGroupMember");
      debugPrint("--> [Primary Schooler Info] Visiting web address: $url");
      final body = jsonEncode({
        "GroupId": groupId,
        "MemberRegNum": memberRegNum
      }); // End of jsonEncode

      final request = http.Request('DELETE', url);
      request.headers.addAll({"Content-Type": "application/json"});
      request.body = body;

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      debugPrint("<-- [Primary Schooler Info] Server responded with Status Code: ${response.statusCode}");
      debugPrint("<-- [Primary Schooler Info] Raw JSON data received: $responseBody");
      return response.statusCode == 200;
    } catch (e) {
      debugPrint("Error removing member: $e");
      return false;
    } // End of catch (e)
  } // End of removeMember method

  /// 8. Fetch All Departments dynamically from the database
  Future<List<dynamic>> getDepartments() async {
    try {
      final url = Uri.parse("${ApiConfig.baseUrl}/users/getAllDepartments");
      debugPrint("--> [Primary Schooler Info] Visiting departments web address: $url");
      final response = await http.get(url);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return [];
    } catch (e) {
      debugPrint("Error fetching departments: $e");
      return [];
    }
  }

  /// 9. Fetch All Sections dynamically from the database
  Future<List<dynamic>> getSections() async {
    try {
      final url = Uri.parse("${ApiConfig.baseUrl}/users/getAllSections");
      debugPrint("--> [Primary Schooler Info] Visiting sections web address: $url");
      final response = await http.get(url);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return [];
    } catch (e) {
      debugPrint("Error fetching sections: $e");
      return [];
    }
  }
} // End of LobbyViewModel class