import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../api_config.dart';

// ---------------------------------------------------------
// WHAT IS THIS FILE?
// This is the "Brain" for our FYP-2 View/Edit Criteria screen.
// It talks to the server to get and save marking rules.
// ---------------------------------------------------------

class Fyp2ViewEditCriteriaViewModel {
  
  // 1. Get the marking rules for a specific session (e.g. Session 7)
  Future<List<Map<String, dynamic>>> fetchCriteria(int sessionId) async {
    try {
      final response = await http.get(
        Uri.parse("${ApiConfig.baseUrl}/committee-meetings/GetCriteriaFyp2/$sessionId"),
      );
      debugPrint("<-- [Primary Schooler Info] Server responded with Status Code: ${response.statusCode}");
      debugPrint("<-- [Primary Schooler Info] Raw JSON data received: ${response.body}");
      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        int fakeId = 0; // Used to give sub-parameters an ID if the backend didn't send one
        
        return data.map((p) {
          Map<String, dynamic> map = Map<String, dynamic>.from(p);
          List subs = map['subParameters'] ?? [];
          
          map['subParameters'] = subs.map((s) {
            Map<String, dynamic> subMap = Map<String, dynamic>.from(s);
            subMap['id'] ??= ++fakeId; // Add a temporary ID for UI tracking
            return subMap;
          }).toList();
          
          return map;
        }).toList();
      }
    } catch (e) {}
    return [];
  }

  // 2. Save the updated criteria back to the server
  Future<Map<String, dynamic>> updateCriteria(int sessionId, List<Map<String, dynamic>> criteria) async {
    try {
      // Prepare the data to match what the server expects (the Payload)
      final payload = criteria.map((p) {
        return {
          "id": p['id'],
          "name": p['name'],
          "percentage": int.tryParse(p['percentage'].toString()) ?? 0,
          "allowEvaluation": false, // not used in FYP2
          "evaluators": [],
          "subParameters": (p['subParameters'] as List).map((s) {
            return {
              "name": s['name'],
              "percentage": int.tryParse(s['percentage'].toString()) ?? 0
            };
          }).toList()
        };
      }).toList();

      final response = await http.post(
        Uri.parse("${ApiConfig.baseUrl}/committee-meetings/EditCriteriaFyp2/$sessionId"),
        headers: {"Content-Type": "application/json"},
        body: json.encode(payload),
      );
      debugPrint("<-- [Primary Schooler Info] Server responded with Status Code: ${response.statusCode}");
      debugPrint("<-- [Primary Schooler Info] Raw JSON data received: ${response.body}");

      if (response.statusCode == 200) {
        return {"success": true, "message": "Updated Successfully ✅"};
      } else {
        String error = "Update failed ❌";
        try {
          var errorData = json.decode(response.body);
          error = errorData['ExceptionMessage'] ?? errorData['Message'] ?? error;
        } catch (_) {}
        return {"success": false, "message": error};
      }
    } catch (e) {
      return {"success": false, "message": "Error connecting to server ❌"};
    }
  }
}