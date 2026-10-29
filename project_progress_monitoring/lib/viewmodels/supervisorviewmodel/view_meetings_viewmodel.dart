import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../api_config.dart';

// --- VIEWMODEL ---
// PRIMARY SCHOOLER NOTE: This is the Brain for the Supervisor's "All Meetings" screen.
// It handles fetching, searching, and deleting meetings.
class ViewMeetingsViewModel {

  /// ──────────────────────────────────────────────────────────────────────────
  /// WHAT IT DOES: Fetches all meetings for the supervisor from the server.
  /// HOW IT WORKS: It uses the Supervisor ID and the FYP type (FYP-1 or FYP-2).
  /// ──────────────────────────────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> fetchMeetings(String supervisorId, String fypType) async {
    try {
      // PRIMARY SCHOOLER NOTE: We use the specific endpoint from the React code!
      final url = Uri.parse("${ApiConfig.baseUrl}/supervisor/getSupervisorMeetings/$supervisorId/$fypType");
      debugPrint("--> [Primary Schooler Info] Visiting web address: $url");
      
      final response = await http.get(url);
      debugPrint("<-- [Primary Schooler Info] Server responded with Status Code: ${response.statusCode}");
      debugPrint("<-- [Primary Schooler Info] Raw JSON data received: ${response.body}");

      if (response.statusCode == 200) {
        // We turn the server's text (JSON) into a List of Maps.
        List<dynamic> data = jsonDecode(response.body);
        return data.map((m) => m as Map<String, dynamic>).toList();
      }
    } catch (e) {
      debugPrint("Error fetching meetings: $e");
    }
    return [];
  }

  /// ──────────────────────────────────────────────────────────────────────────
  /// WHAT IT DOES: Deletes a meeting from the system.
  /// ──────────────────────────────────────────────────────────────────────────
  Future<bool> deleteMeeting(int meetingId) async {
    try {
      // NOTE: Adjusting the URL to match the server's delete endpoint if needed.
      // For now, using the common pattern.
      final url = Uri.parse("${ApiConfig.baseUrl}/supervisor/delete-meeting/$meetingId");
      debugPrint("--> [Primary Schooler Info] Visiting web address: $url");
      final response = await http.delete(url);
      debugPrint("<-- [Primary Schooler Info] Server responded with Status Code: ${response.statusCode}");
      debugPrint("<-- [Primary Schooler Info] Raw JSON data received: ${response.body}");
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// ──────────────────────────────────────────────────────────────────────────
  /// WHAT IT DOES: Updates an existing meeting's details.
  /// ──────────────────────────────────────────────────────────────────────────
  Future<bool> updateMeeting(int meetingId, Map<String, dynamic> body) async {
    try {
      final url = Uri.parse("${ApiConfig.baseUrl}/supervisor/update-meeting/$meetingId");
      debugPrint("--> [Primary Schooler Info] Visiting web address: $url");
      final response = await http.put(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );
      debugPrint("<-- [Primary Schooler Info] Server responded with Status Code: ${response.statusCode}");
      debugPrint("<-- [Primary Schooler Info] Raw JSON data received: ${response.body}");
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
} // End of ViewMeetingsViewModel class