import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../api_config.dart';

// --- VIEWMODEL ---
// PRIMARY SCHOOLER NOTE: This is the "Brain" of our My Meetings screen.
// It handles all the fetching of data from the internet (API calls).
class CommitteeMyMeetingsViewModel {

  /// ──────────────────────────────────────────────────────────────────────────
  /// WHAT IT DOES: Fetches the list of meetings scheduled for a specific member.
  /// WHY IT EXISTS: To show the member only their own evaluation sessions.
  /// HOW IT WORKS: It sends the Member ID and FYP Type to the server.
  /// ──────────────────────────────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> fetchMyMeetings(String userId, String fypType) async {
    try {
      // PRIMARY SCHOOLER NOTE: This is the address we are visiting to get data.
      final url = Uri.parse("${ApiConfig.baseUrl}/committee-meetings/my-meetings/$userId/$fypType");
      debugPrint("--> [Primary Schooler Info] Visiting web address: $url");
      
      // We wait for the server to reply.
      final response = await http.get(url);
      debugPrint("<-- [Primary Schooler Info] Server responded with Status Code: ${response.statusCode}");
      debugPrint("<-- [Primary Schooler Info] Raw JSON data received: ${response.body}");

      if (response.statusCode == 200) {
        // If the server says "OK" (200), we read the data.
        List<dynamic> data = jsonDecode(response.body);
        
        // We turn the data into a list of maps (key-value pairs).
        return data.map((m) => m as Map<String, dynamic>).toList();
      } else {
        // If the server is grumpy, we return an empty list.
        debugPrint("Server responded with error: ${response.statusCode}");
        return [];
      }
    } catch (e) {
      // If something goes wrong (like no internet), we catch the error here.
      debugPrint("Oops! Something went wrong while fetching meetings: $e");
      return [];
    }
  } // End of fetchMyMeetings
} // End of CommitteeMyMeetingsViewModel class