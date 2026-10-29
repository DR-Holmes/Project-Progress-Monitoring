import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../api_config.dart';

class CommitteeDashboardViewModel {
  // MATCHING EXACT SPELLING FROM YOUR C# CONTROLLER: "api/comitee"
  final String _comiteeRoute = "${ApiConfig.baseUrl}/comitee";
  final String _groupsRoute = "${ApiConfig.baseUrl}/committee-meetings/groups/approved";

  final List<String> filters = ['All', 'Active', 'Pending', 'Allocated'];

  // 1. Fetch Groups List
  Future<List<Map<String, dynamic>>> fetchGroupsList(String fypType, String searchQuery, String filter) async {
    try {
      // Assuming a standard endpoint to fetch all groups.
      // If your backend uses a different route for getting all groups, change this URL.
      final url = Uri.parse("$_groupsRoute/$fypType");
      debugPrint("--> [Primary Schooler Info] Visiting web address: $url");
      final response = await http.get(url);
      debugPrint("<-- [Primary Schooler Info] Server responded with Status Code: ${response.statusCode}");
      debugPrint("<-- [Primary Schooler Info] Raw JSON data received: ${response.body}");

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        List<Map<String, dynamic>> groups = data.map((g) => g as Map<String, dynamic>).toList();

        // 1. Apply Search Query locally
        if (searchQuery.isNotEmpty) {
          groups = groups.where((g) {
            final groupName = (g['groupName'] ?? g['title'] ?? 'Group ${g['id']}').toString().toLowerCase();
            return groupName.contains(searchQuery.toLowerCase());
          }).toList();
        }

        // 2. Apply Dropdown Filter locally
        if (filter != 'All') {
          groups = groups.where((g) => g['status'] == filter || g['requestStatus'] == filter).toList();
        }

        return groups;
      } else {
        debugPrint("Failed to load groups. Status Code: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Error fetching groups list: $e");
    }
    return [];
  }

  // 2. Get Today's Meetings (Matches your C# endpoint exactly)
  Future<List<dynamic>> getTodayMeetings(String type) async {
    // Route: api/comitee/today-meetings/{fypType}
    final url = Uri.parse("$_comiteeRoute/today-meetings/$type");
    debugPrint("--> [Primary Schooler Info] Visiting web address: $url");
    try {
      final response = await http.get(url);
      debugPrint("<-- [Primary Schooler Info] Server responded with Status Code: ${response.statusCode}");
      debugPrint("<-- [Primary Schooler Info] Raw JSON data received: ${response.body}");
      if (response.statusCode == 200) return jsonDecode(response.body);
    } catch (e) {
      debugPrint("Error fetching meetings: $e");
    }
    return [];
  }

  // 3. Allocate Project (Matches your C# endpoint exactly)
  Future<bool> allocateProject(int groupId, int projectId) async {
    // Route: api/comitee/allocateProject
    final url = Uri.parse("$_comiteeRoute/allocateProject");
    debugPrint("--> [Primary Schooler Info] Visiting web address: $url");
    try {
      final response = await http.put(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "groupId": groupId,
          "projectId": projectId
        }),
      );
      debugPrint("<-- [Primary Schooler Info] Server responded with Status Code: ${response.statusCode}");
      debugPrint("<-- [Primary Schooler Info] Raw JSON data received: ${response.body}");
      return response.statusCode == 200;
    } catch (e) {
      debugPrint("Error allocating project: $e");
      return false;
    }
  }
}