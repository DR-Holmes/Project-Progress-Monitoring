import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../api_config.dart';

class SupervisorDashboardViewModel {
  // Use List<Map<String, dynamic>> to store group data directly
  // This follows the VVM pattern without requiring custom model classes
  List<Map<String, dynamic>> myGroups = [];
  bool isLoading = false;

  /// Fetches groups assigned to the supervisor for the selected FYP type.
  /// 
  /// [supervisorId] is the unique ID of the supervisor.
  /// [fypType] should be "FYP-1" or "FYP-2".
  Future<void> fetchDashboardData(String supervisorId, String fypType) async {
    isLoading = true;
    myGroups = []; // Clear previous data before loading

    try {
      // Using the correct endpoint provided in the controller: /supervisor/getAllGroups/{selectedFYP}/{supervisorId}
      final url = Uri.parse(
          "${ApiConfig.baseUrl}/supervisor/getAllGroups/$fypType/$supervisorId"
      );
      debugPrint("--> [Primary Schooler Info] Visiting web address: $url");

      debugPrint("Fetching: $url");
      final response = await http.get(url);
      debugPrint("<-- [Primary Schooler Info] Server responded with Status Code: ${response.statusCode}");
      debugPrint("<-- [Primary Schooler Info] Raw JSON data received: ${response.body}");

      if (response.statusCode == 200) {
        // Parse the body as a list of dynamic objects
        final List<dynamic> data = jsonDecode(response.body);
        
        // Convert to a List of Maps for easier consumption in the View
        myGroups = data.map((item) => item as Map<String, dynamic>).toList();
        
        debugPrint("Successfully loaded ${myGroups.length} groups.");
      } else {
        debugPrint("Error fetching groups: Status Code ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("API Error during dashboard fetch: $e");
    } finally {
      // Ensure loading state is turned off regardless of success or failure
      isLoading = false;
    }
  }
}