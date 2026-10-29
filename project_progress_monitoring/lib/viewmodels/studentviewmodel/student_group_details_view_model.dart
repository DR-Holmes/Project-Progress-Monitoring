import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../api_config.dart';

// --- VIEWMODEL ---
// This class handles the logic for fetching group details.
// It uses simple Maps and Lists to make it easy for beginners.
class StudentGroupDetailsViewModel {
  
  // Base URL for the users controller
  final String _baseUrl = "${ApiConfig.baseUrl}/users";

  // Fetches the group details for a specific student.
  // The "Map" Cheat Sheet:
  // The returned Map contains:
  // - 'groupId': The unique ID of the group.
  // - 'members': A List of Maps, each containing:
  //    - 'regNum': Student's registration number.
  //    - 'name': Student's full name.
  //    - 'Cgpa': Student's CGPA.
  //    - 'technology': Student's selected technology.
  //    - 'isAdmin': 1 if the student is the group leader, 0 otherwise.
  Future<Map<String, dynamic>?> fetchGroupDetails(String regNum) async {
    try {
      // FYP TALKING POINT: "We fetch the group details using the logged-in student's ID. This allows the backend to find which group the student belongs to and return all its members."
      final url = Uri.parse("$_baseUrl/GetMyGroup/$regNum");
      debugPrint("--> [Primary Schooler Info] Visiting web address: $url");
      final response = await http.get(url);
      debugPrint("<-- [Primary Schooler Info] Server responded with Status Code: ${response.statusCode}");
      debugPrint("<-- [Primary Schooler Info] Raw JSON data received: ${response.body}");

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        // We decode the JSON string into a Map
        return jsonDecode(response.body) as Map<String, dynamic>;
      } // End of if (response.statusCode == 200)
    } catch (e) {
      debugPrint("Error fetching group details: $e");
    } // End of catch (e)
    
    return null; // Return null if something went wrong or no group exists.
  } // End of fetchGroupDetails method
} // End of StudentGroupDetailsViewModel class