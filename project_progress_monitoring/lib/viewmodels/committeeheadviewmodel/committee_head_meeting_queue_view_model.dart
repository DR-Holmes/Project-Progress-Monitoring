import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../api_config.dart';

class CommitteeHeadMeetingQueueViewModel {
  final String _baseUrl = ApiConfig.baseUrl;

  // 1. Fetch meetings based on FYP-1 or FYP-2
  Future<List<Map<String, dynamic>>> fetchMeetings(String activeFYP) async {
    try {
      final response = await http.get(Uri.parse("$_baseUrl/committee-meetings/today-meetings/$activeFYP"));
      debugPrint("<-- [Primary Schooler Info] Server responded with Status Code: ${response.statusCode}");
      debugPrint("<-- [Primary Schooler Info] Raw JSON data received: ${response.body}");

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        return data.map((e) => e as Map<String, dynamic>).toList();
      }
    } catch (e) {
      debugPrint("Error fetching meetings: $e");
    }
    return [];
  }

  // 2. Fetch Meeting Details and the Group Queue
  Future<Map<String, dynamic>> fetchMeetingDetails(Map<String, dynamic> meeting) async {
    try {
      int meetingId = meeting['id'] ?? meeting['meetingId'];
      int groupId = meeting['GroupIDs'] ?? meeting['groupId'];

      // Fetch specific meeting data
      final meetingResp = await http.get(Uri.parse("$_baseUrl/committee-meetings/meetings/$meetingId"));
      
      // Fetch group members
      final groupResp = await http.get(Uri.parse("$_baseUrl/committee-meetings/getSpecificGroup/$groupId"));
      
      Map<String, dynamic> details = {};
      if (meetingResp.statusCode == 200) {
        List<dynamic> data = jsonDecode(meetingResp.body);
        if (data.isNotEmpty) details = data[0];
      }

      List<dynamic> members = [];
      if (groupResp.statusCode == 200) {
        members = jsonDecode(groupResp.body);
      }

      return {
        "meetingDetails": details,
        "groupDetails": members,
      };
    } catch (e) {
      debugPrint("Error fetching queue details: $e");
    }

    return {
      "meetingDetails": meeting,
      "groupDetails": [],
    };
  }

  // 3. Calculate Final Score
  Future<Map<String, dynamic>?> calculateFinalScore(int studentId, int meetingId, int sessionId) async {
    try {
      final response = await http.get(Uri.parse("$_baseUrl/fyp1-scores/final-score/$studentId/$meetingId/$sessionId"));
      debugPrint("<-- [Primary Schooler Info] Server responded with Status Code: ${response.statusCode}");
      debugPrint("<-- [Primary Schooler Info] Raw JSON data received: ${response.body}");
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      debugPrint("Error calculating score: $e");
    }
    return null;
  }
}