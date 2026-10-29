import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../api_config.dart';

// ---------------------------------------------------------
// WHAT IS THIS FILE?
// This is the "Brain" of our Set Criteria screen.
// It handles the "Internet Work" (talking to the server).
// It doesn't draw anything; it just fetches and sends data.
// ---------------------------------------------------------

class Fyp1SetupCriteriaViewModel {
  // 1. A variable to check if we are busy (loading)
  bool isLoading = false;

  // ---------------------------------------------------------
  // FUNCTION: fetchCommitteeMembers
  // This goes to the internet to get a list of committee people.
  // ---------------------------------------------------------
  Future<List<Map<String, dynamic>>> fetchCommitteeMembers() async {
    try {
      // Use our base URL from config
      final response = await http.get(
        Uri.parse("${ApiConfig.baseUrl}/committee-meetings/GetComitteeMembers"),
      );
      debugPrint("<-- [Primary Schooler Info] Server responded with Status Code: ${response.statusCode}");
      debugPrint("<-- [Primary Schooler Info] Raw JSON data received: ${response.body}");

      if (response.statusCode == 200) {
        // Translate the JSON text into a List of Maps (folders of info)
        List<dynamic> data = json.decode(response.body);
        return data.map((e) => e as Map<String, dynamic>).toList();
      } else {
        return [];
      }
    } catch (e) {
      // If there's an error, return an empty list
      return [];
    }
  }

  // ---------------------------------------------------------
  // FUNCTION: saveCriteria
  // This sends our finished list of parameters to the server.
  // ---------------------------------------------------------
  Future<Map<String, dynamic>> saveCriteria(Map<String, dynamic> payload) async {
    try {
      final response = await http.post(
        Uri.parse("${ApiConfig.baseUrl}/committee-meetings/save-criteria"),
        headers: {"Content-Type": "application/json"},
        body: json.encode(payload),
      );
      debugPrint("<-- [Primary Schooler Info] Server responded with Status Code: ${response.statusCode}");
      debugPrint("<-- [Primary Schooler Info] Raw JSON data received: ${response.body}");

      if (response.statusCode == 200) {
        return {"success": true, "message": "Saved Successfully ✅"};
      } else {
        // Try to get the error message from the server
        String error = "Error saving ❌";
        try {
          var errorData = json.decode(response.body);
          error = errorData['Message'] ?? errorData['message'] ?? error;
        } catch (_) {}
        return {"success": false, "message": error};
      }
    } catch (e) {
      return {"success": false, "message": "Connection Error: $e"};
    }
  }
}