import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../api_config.dart';

class MeetingNotesViewModel {
  bool isLoading = false;
  String? notes;

  Future<void> fetchMeetingNotes(int meetingId) async {
    isLoading = true;
    try {
      final url = Uri.parse("${ApiConfig.baseUrl}/supervisor/meeting-details/$meetingId");
      debugPrint("--> [Primary Schooler Info] Visiting web address: $url");
      final response = await http.get(url);
      debugPrint("<-- [Primary Schooler Info] Server responded with Status Code: ${response.statusCode}");
      debugPrint("<-- [Primary Schooler Info] Raw JSON data received: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        notes = data['meetingNotes'];
      }
    } catch (e) {
      debugPrint("Error fetching meeting notes: $e");
    }
    isLoading = false;
  }

  Future<bool> saveMeetingNotes(int meetingId, String updatedNotes) async {
    isLoading = true;
    try {
      final url = Uri.parse("${ApiConfig.baseUrl}/supervisor/update-meeting-notes/$meetingId");
      debugPrint("--> [Primary Schooler Info] Visiting web address: $url");
      final response = await http.put(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"meetingNotes": updatedNotes}),
      );
      debugPrint("<-- [Primary Schooler Info] Server responded with Status Code: ${response.statusCode}");
      debugPrint("<-- [Primary Schooler Info] Raw JSON data received: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 204) {
        notes = updatedNotes;
        isLoading = false;
        return true;
      }
    } catch (e) {
      debugPrint("Error saving meeting notes: $e");
    }
    isLoading = false;
    return false;
  }
}