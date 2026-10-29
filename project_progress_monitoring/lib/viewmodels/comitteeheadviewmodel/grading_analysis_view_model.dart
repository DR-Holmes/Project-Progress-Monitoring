import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../api_config.dart';

// ---------------------------------------------------------
// WHAT IS THIS FILE?
// This is the "Brain" or "ViewModel" for the Grading Analysis screen.
// It handles all the data (information) and talks to the 
// internet (our backend database) to get grades.
// It doesn't draw any buttons, it just knows "what" information to show.
// ---------------------------------------------------------

class GradingAnalysisViewModel {
  
  // ---------------------------------------------------------
  // 1. FETCH SESSION GRADES
  // This function asks the internet: "Give me the grades sorted by Session (like 2021, 2022)."
  // ---------------------------------------------------------
  Future<List<Map<String, dynamic>>> fetchSessionData(String fypType) async {
    try {
      // 1. Create the web address (URL)
      final url = Uri.parse("${ApiConfig.baseUrl}/grading-analysis/session-wise?fyp=$fypType");
      debugPrint("--> [Primary Schooler] Asking for Session Data: $url");

      // 2. Wait for the server to reply
      final response = await http.get(url);

      // 3. Check if the server said "OK" (200)
      if (response.statusCode == 200 && response.body.isNotEmpty) {
        // Translate JSON string into a List of Maps
        List<dynamic> rawData = jsonDecode(response.body);
        return rawData.map((item) => item as Map<String, dynamic>).toList();
      }
    } catch (e) {
      debugPrint("!!! [Primary Schooler Error] Failed to fetch session data: $e");
    }
    // Return empty list if it fails
    return [];
  }

  // ---------------------------------------------------------
  // 2. FETCH SUPERVISOR GRADES
  // This function asks the internet: "Give me the grades given by each Supervisor."
  // ---------------------------------------------------------
  Future<List<Map<String, dynamic>>> fetchSupervisorData(String fypType) async {
    try {
      // 1. Create the web address (URL)
      final url = Uri.parse("${ApiConfig.baseUrl}/grading-analysis/supervisor-wise?fyp=$fypType");
      debugPrint("--> [Primary Schooler] Asking for Supervisor Data: $url");

      // 2. Wait for the server to reply
      final response = await http.get(url);

      // 3. Check if the server said "OK" (200)
      if (response.statusCode == 200 && response.body.isNotEmpty) {
        // Translate JSON string into a List of Maps
        List<dynamic> rawData = jsonDecode(response.body);
        debugPrint("--> ${rawData}");
        return rawData.map((item) => item as Map<String, dynamic>).toList();

      }
    } catch (e) {
      debugPrint("!!! [Primary Schooler Error] Failed to fetch supervisor data: $e");
    }
    // Return empty list if it fails
    return [];
  }

  // ---------------------------------------------------------
  // 3. FETCH GROUP DETAILS
  // This function asks the internet: "Give me every group and the grades of their students."
  // Note: Groups have both FYP-1 and FYP-2 grades at the same time, so we don't need to pass the fypType.
  // ---------------------------------------------------------
  Future<List<Map<String, dynamic>>> fetchGroupData() async {
    try {
      // 1. Create the web address (URL)
      final url = Uri.parse("${ApiConfig.baseUrl}/grading-analysis/group-wise");
      debugPrint("--> [Primary Schooler] Asking for Group Data: $url");

      // 2. Wait for the server to reply
      final response = await http.get(url);

      // 3. Check if the server said "OK" (200)
      if (response.statusCode == 200 && response.body.isNotEmpty) {
        // Translate JSON string into a List of Maps
        List<dynamic> rawData = jsonDecode(response.body);
        return rawData.map((item) => item as Map<String, dynamic>).toList();
      }
    } catch (e) {
      debugPrint("!!! [Primary Schooler Error] Failed to fetch group data: $e");
    }
    // Return empty list if it fails
    return [];
  }






  Future<List<Map<String, dynamic>>> fetchSupervisorDatas(String fypType) async {
    try {
      // 1. Create the web address (URL)
      final url = Uri.parse("${ApiConfig.baseUrl}/grading-analysis/getSortedSUpervisorGrades?fyp=$fypType");
      debugPrint("--> [Primary Schooler] Asking for Supervisor Data: $url");

      // 2. Wait for the server to reply
      final response = await http.get(url);

      // 3. Check if the server said "OK" (200)
      if (response.statusCode == 200 && response.body.isNotEmpty) {
        // Translate JSON string into a List of Maps
        List<dynamic> rawData = jsonDecode(response.body);
        return rawData.map((item) => item as Map<String, dynamic>).toList();
      }
    } catch (e) {
      debugPrint("!!! [Primary Schooler Error] Failed to fetch supervisor data: $e");
    }
    // Return empty list if it fails
    return [];
  }

}
