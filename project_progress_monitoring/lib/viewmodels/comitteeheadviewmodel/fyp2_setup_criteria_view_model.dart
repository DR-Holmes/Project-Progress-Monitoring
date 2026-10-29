import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../api_config.dart';

// ---------------------------------------------------------
// WHAT IS THIS FILE?
// This is the "Brain" of our FYP-2 Setup Criteria screen.
// It handles talking to the server to fetch existing 
// criteria and saving new ones.
// ---------------------------------------------------------

class Fyp2SetupCriteriaViewModel {
  // A variable to check if we are busy
  bool isLoading = false;

  // ---------------------------------------------------------
  // FUNCTION: fetchCriteria
  // This goes to the internet to get existing criteria if any.
  // ---------------------------------------------------------
  Future<List<Map<String, dynamic>>> fetchCriteria(int sessionId) async {
    try {
      final response = await http.get(
        Uri.parse("${ApiConfig.baseUrl}/fyp2-scores/Getcriteria/$sessionId"),
      );
      debugPrint("<-- [Primary Schooler Info] Server responded with Status Code: ${response.statusCode}");
      debugPrint("<-- [Primary Schooler Info] Raw JSON data received: ${response.body}");

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data.map((e) => e as Map<String, dynamic>).toList();
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  // ---------------------------------------------------------
  // FUNCTION: saveCriteria
  // Sends our list of parameters to the server.
  // ---------------------------------------------------------
  Future<Map<String, dynamic>> saveCriteria(Map<String, dynamic> payload) async {
    try {
      final response = await http.post(
        Uri.parse("${ApiConfig.baseUrl}/fyp2-scores/save-criteria"),
        headers: {"Content-Type": "application/json"},
        body: json.encode(payload),
      );
      debugPrint("<-- [Primary Schooler Info] Server responded with Status Code: ${response.statusCode}");
      debugPrint("<-- [Primary Schooler Info] Raw JSON data received: ${response.body}");

      if (response.statusCode == 200) {
        return {"success": true, "message": "Criteria Saved Successfully ✅"};
      } else {
        String error = "Error saving ❌";
        try {
          var errorData = json.decode(response.body);
          error = errorData['Message'] ?? errorData['ExceptionMessage'] ?? error;
        } catch (_) {}
        return {"success": false, "message": error};
      }
    } catch (e) {
      return {"success": false, "message": "Connection Error: $e"};
    }
  }
}