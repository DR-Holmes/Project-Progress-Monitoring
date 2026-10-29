import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import '../../api_config.dart';

class StudentSelectionViewModel {
  // 🏫 SCHOOL LESSON: We use a List of Maps to store our student data!
  // This is easier for beginners than creating complex Model classes.
  List<Map<String, dynamic>> allStudents = [];
  bool isLoading = false;

  /// 🏫 SCHOOL LESSON: This function fetches all students with their group status!
  /// It uses the 'type' (FYP-1/FYP-2) to get the right list from the backend.
  Future<List<Map<String, dynamic>>> fetchStudents(String type) async {
    isLoading = true;
    try {
      // Endpoint: /committee-meetings/all-students-with-group/{type}
      final url = Uri.parse("${ApiConfig.baseUrl}/committee-meetings/all-students-with-group/$type");
      debugPrint("--> [Primary Schooler Info] Visiting web address: $url");
      final response = await http.get(url);
      debugPrint("<-- [Primary Schooler Info] Server responded with Status Code: ${response.statusCode}");
      debugPrint("<-- [Primary Schooler Info] Raw JSON data received: ${response.body}");

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        allStudents = data.map((s) => s as Map<String, dynamic>).toList();
        return allStudents;
      }
      return [];
    } catch (e) {
      debugPrint("🏫 Oops! Error fetching students: $e");
      return [];
    } finally {
      isLoading = false;
    }
  }

  // 🏫 SCHOOL LESSON: We don't need a separate search function here anymore 
  // because we will handle filtering directly in the View's UI logic 
  // using basic Dart .where() and .contains()!
}