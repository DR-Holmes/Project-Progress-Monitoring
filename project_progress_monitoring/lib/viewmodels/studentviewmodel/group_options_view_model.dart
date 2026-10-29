import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../api_config.dart';

// --- VIEWMODEL ---
// This class handles the logic for students who are not in a group yet.
// It allows them to create a group or respond to invitations from others.
class GroupOptionsViewModel {

  /// 1. Fetch the current active session ID (Required to create a group)
  Future<int?> getCurrentSessionId() async {
    try {
      // FYP TALKING POINT: "We need the current session ID to ensure that group formation is tied to the correct academic term."
      final url = Uri.parse("${ApiConfig.baseUrl}/users/CurrentSession");
      debugPrint("--> [Primary Schooler Info] Visiting web address: $url");
      final response = await http.get(url);
      debugPrint("<-- [Primary Schooler Info] Server responded with Status Code: ${response.statusCode}");
      debugPrint("<-- [Primary Schooler Info] Raw JSON data received: ${response.body}");

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final data = jsonDecode(response.body);
        return data['id'];
      } // End of if (response.statusCode == 200)
      return null;
    } catch (e) {
      debugPrint("Error fetching session: $e");
      return null;
    } // End of catch (e)
  } // End of getCurrentSessionId method

  /// 2. Get Pending Requests (Invites) for this student
  // The "List" Cheat Sheet:
  // Each invite Map in the list has:
  // - 'RequestID': The unique ID of the invitation.
  // - 'FromRegNum': The student who sent the invite.
  // - 'Status': Usually "Pending".
  Future<List<dynamic>> getPendingInvites(String regNum) async {
    try {
      // FYP TALKING POINT: "This fetches all group invitations that have been sent TO the current student. They can then choose to accept or reject them."
      final url = Uri.parse("${ApiConfig.baseUrl}/users/GetMemberRequests/$regNum");
      debugPrint("--> [Primary Schooler Info] Visiting web address: $url");
      final response = await http.get(url);
      debugPrint("<-- [Primary Schooler Info] Server responded with Status Code: ${response.statusCode}");
      debugPrint("<-- [Primary Schooler Info] Raw JSON data received: ${response.body}");

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return [];
      } // End of if/else
    } catch (e) {
      debugPrint("Error fetching requests: $e");
      return [];
    } // End of catch (e)
  } // End of getPendingInvites method

  /// 3. Respond to a Group Request (Accept/Reject)
  Future<bool> respondToRequest(int requestId, String status) async {
    try {
      // FYP TALKING POINT: "When a student accepts an invite, our backend logic automatically adds them to the corresponding project group and updates their status."
      final url = Uri.parse("${ApiConfig.baseUrl}/users/UpdateGroupRequestStatus");
      debugPrint("--> [Primary Schooler Info] Visiting web address: $url");
      final body = jsonEncode({
        "RequestId": requestId,
        "Status": status // "Accepted" or "Rejected"
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
      debugPrint("Error responding to request: $e");
      return false;
    } // End of catch (e)
  } // End of respondToRequest method

  /// 4. Create a New Group (User becomes Admin)
  Future<bool> createGroup(String regNum) async {
    try {
      // First get the session ID
      int? sessionId = await getCurrentSessionId();
      if (sessionId == null) return false;

      // FYP TALKING POINT: "Creating a group makes the current student the 'Admin'. This gives them the responsibility to invite other members and eventually finalize the team."
      final url = Uri.parse("${ApiConfig.baseUrl}/users/CreateGroup");
      debugPrint("--> [Primary Schooler Info] Visiting web address: $url");

      // Matching C# ProjectGroup model structure
      final body = jsonEncode({
        "createdBy": regNum,
        "supervisorID": null,
        "projectID": null,
        "isFinalized": 0,
        "createdSession": sessionId
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
      debugPrint("Error creating group: $e");
      return false;
    } // End of catch (e)
  } // End of createGroup method
} // End of GroupOptionsViewModel class