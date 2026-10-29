import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../api_config.dart';

// ---------------------------------------------------------
// WHAT IS THIS FILE?
// This is the "Brain" or "ViewModel" of our Dashboard.
// It handles all the data (information) and talks to the 
// internet to get updates. It doesn't draw any buttons, 
// it just knows "what" information to show.
// ---------------------------------------------------------

class CommitteeHeadDashboardViewModel {
  
  // This is the "Secret Address" on the internet where our data lives.
  // We use ApiConfig to find the main address.
  final String _groupsBase = "${ApiConfig.baseUrl}/committee-meetings/groups/approved";

  // ---------------------------------------------------------
  // FUNCTION: fetchAllGroups
  // This function goes to the internet and asks for a list of
  // groups (students working together) for either FYP-1 or FYP-2.
  // ---------------------------------------------------------
  Future<List<Map<String, dynamic>>> fetchAllGroups(String fypType) async {
    try {
      // 1. Create the full address for the internet request
      final url = Uri.parse("$_groupsBase/$fypType");
      debugPrint("--> [Primary Schooler Info] Visiting web address: $url");

      // 2. Actually send the request (like sending a letter)
      final response = await http.get(url);
      debugPrint("<-- [Primary Schooler Info] Server responded with Status Code: ${response.statusCode}");
      debugPrint("<-- [Primary Schooler Info] Raw JSON data received: ${response.body}");

      // 3. If the internet says "OK" (code 200)
      if (response.statusCode == 200) {
        // 4. Translate the "Computer Language" (JSON) into a List we can read
        List<dynamic> data = jsonDecode(response.body);
        
        // 5. Return the list of maps (key-value pairs)
        return data.map((g) => g as Map<String, dynamic>).toList();
      } else {
        // If something went wrong, print a message in the debug box
        debugPrint("Oh no! Could not load groups. Status: ${response.statusCode}");
      }
    } catch (e) {
      // If the internet is down or there's an error, show it here
      debugPrint("Error fetching groups: $e");
    }
    
    // If we fail, we just return an empty list []
    return [];
  }

  // ---------------------------------------------------------
  // FUNCTION: loadNotifications
  // This is a placeholder. Right now it just returns an empty list,
  // but in the future, you can add code here to get notifications.
  // ---------------------------------------------------------
  Future<List<Map<String, dynamic>>> loadNotifications() async {
    // For now, we have no notifications, so we return an empty list.
    return [];
  }
}