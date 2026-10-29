import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../api_config.dart';

class GroupDetailsViewModel {
  // We use Map<String, dynamic> to store the entire response
  // This includes groupName, projectTitle, supervisor, and members list
  Map<String, dynamic>? groupData;
  bool isLoading = false;

  // Helper to get members list safely
  List<dynamic> get members => groupData?['members'] ?? [];

  /// Fetches detailed information about a group, including members and their individual progress.
  /// 
  /// [groupId] is the unique ID of the group.
  Future<void> fetchGroupDetails(int groupId) async {
    isLoading = true;
    try {
      // Using the endpoint provided in the CommitteeMeetings controller: /api/committee-meetings/groups-details/{groupId}
      final url = Uri.parse("${ApiConfig.baseUrl}/committee-meetings/groups-details/$groupId");
      debugPrint("--> [Primary Schooler Info] Visiting web address: $url");
      
      debugPrint("Fetching Group Details: $url");
      final response = await http.get(url);
      debugPrint("<-- [Primary Schooler Info] Server responded with Status Code: ${response.statusCode}");
      debugPrint("<-- [Primary Schooler Info] Raw JSON data received: ${response.body}");

      if (response.statusCode == 200) {
        // The backend returns a single object with group info and a members list
        final Map<String, dynamic> data = jsonDecode(response.body);
        
        // Ensure ID is normalized for calculations
        if (data['groupName'] != null) {
           data['GroupId'] = data['groupName']; 
        }
        
        groupData = data;
        debugPrint("Group details loaded. Members found: ${members.length}");
      } else {
        debugPrint("Error: Server returned status ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("API Error in fetchGroupDetails: $e");
    } finally {
      isLoading = false;
    }
  }

  /// Calculates the average progress of all members in the group.
  int calculateOverallProgress() {
    final memberList = members;
    if (memberList.isEmpty) return 0;
    
    double totalProgress = 0;
    for (var member in memberList) {
      // Progress is returned by the backend CalculateStudentProgress_InMemory method
      totalProgress += (member['progress'] ?? 0).toDouble();
    }
    
    return (totalProgress / memberList.length).round();
  }
}