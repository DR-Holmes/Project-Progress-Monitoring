import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../api_config.dart';

// ---------------------------------------------------------
// WHAT IS THIS FILE?
// This is the "Brain" for our View/Edit Criteria screen.
// It talks to the server to get and save marking rules.
// ---------------------------------------------------------

class Fyp1ViewEditCriteriaViewModel {
  
  // 1. Get the list of committee members (the evaluators)
  Future<List<Map<String, dynamic>>> fetchCommitteeMembers() async {
    try {
      final response = await http.get(
        Uri.parse("${ApiConfig.baseUrl}/committee-meetings/GetComitteeMembers"),
      );
      debugPrint("<-- [Primary Schooler Info] Server responded with Status Code: ${response.statusCode}");
      debugPrint("<-- [Primary Schooler Info] Raw JSON data received: ${response.body}");
      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data.map((e) => e as Map<String, dynamic>).toList();
      }
    } catch (e) {}
    return [];
  }

  // 2. Get the marking rules for a specific session (e.g. Session 7)
  Future<List<Map<String, dynamic>>> fetchCriteria(int sessionId) async {
    try {
      final response = await http.get(
        Uri.parse("${ApiConfig.baseUrl}/committee-meetings/GetCriteriaFyp1/$sessionId"),
      );
      debugPrint("<-- [Primary Schooler Info] Server responded with Status Code: ${response.statusCode}");
      debugPrint("<-- [Primary Schooler Info] Raw JSON data received: ${response.body}");
      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        int fakeId = 0; // Used to give sub-parameters an ID if the backend didn't send one
        
        // We need to make sure 'selectedMembers' exists for each rule
        return data.map((p) {
          Map<String, dynamic> map = Map<String, dynamic>.from(p);
          map['selectedMembers'] = map['evaluators'] ?? [];
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

  // 3. Save the updated criteria back to the server
  Future<Map<String, dynamic>> updateCriteria(int sessionId, List<Map<String, dynamic>> criteria) async {
    try {
      // Prepare the data to match what the server expects (the Payload)
      final payload = criteria.map((p) {
        return {
          "id": p['id'],
          "name": p['name'],
          "percentage": int.tryParse(p['percentage'].toString()) ?? 0,
          "allowEvaluation": p['allowEvaluation'] ?? false,
          "evaluators": p['selectedMembers'],
          "subParameters": (p['subParameters'] as List).map((s) {
            return {
              "id": s['id'],
              "name": s['name'],
              "percentage": int.tryParse(s['percentage'].toString()) ?? 0
            };
          }).toList()
        };
      }).toList();

      final response = await http.post(
        Uri.parse("${ApiConfig.baseUrl}/committee-meetings/EditCriteriaFyp1/$sessionId"),
        headers: {"Content-Type": "application/json"},
        body: json.encode(payload),
      );
      debugPrint("<-- [Primary Schooler Info] Server responded with Status Code: ${response.statusCode}");
      debugPrint("<-- [Primary Schooler Info] Raw JSON data received: ${response.body}");

      if (response.statusCode == 200) {
        return {"success": true, "message": "Updated Successfully ✅"};
      } else {
        return {"success": false, "message": "Update failed: ${response.body}"};
      }
    } catch (e) {
      return {"success": false, "message": "Error connecting to server ❌"};
    }
  }
}