import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import '../../api_config.dart';

class ApprovedGroupsViewModel {
  // 🏫 SCHOOL LESSON: isLoading tells the UI when to show a spinner!
  bool isLoading = false;

  // 🏫 SCHOOL LESSON: We use a List of Maps to store our groups!
  List<Map<String, dynamic>> allGroups = [];

  /// 🏫 SCHOOL LESSON: Fetch groups based on the active FYP type (FYP-1 or FYP-2).
  /// Endpoint: /committee-meetings/groups/approved/{activeFyp}
  Future<List<Map<String, dynamic>>> fetchApprovedGroups(String activeFyp) async {
    isLoading = true;
    try {
      final url = Uri.parse("${ApiConfig.baseUrl}/committee-meetings/groups/approved/$activeFyp");
      debugPrint("--> [Primary Schooler Info] Visiting web address: $url");
      final response = await http.get(url);
      debugPrint("<-- [Primary Schooler Info] Server responded with Status Code: ${response.statusCode}");
      debugPrint("<-- [Primary Schooler Info] Raw JSON data received: ${response.body}");

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        allGroups = data.map((g) => g as Map<String, dynamic>).toList();
        return allGroups;
      }
      return [];
    } catch (e) {
      debugPrint("🏫 Error fetching approved groups: $e");
      return [];
    } finally {
      isLoading = false;
    }
  }
}