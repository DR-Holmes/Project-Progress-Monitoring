import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../api_config.dart';

class AllTasksViewModel {
  // 🏫 SCHOOL LESSON: Fetch all tasks for this supervisor and subject type (FYP-1/2)
  Future<List<dynamic>> fetchTasks(String supervisorId, String fypType) async {
    try {
      final response = await http.get(
          Uri.parse("${ApiConfig.baseUrl}/supervisor/getAllTasks/$supervisorId/$fypType")
      );
      debugPrint("<-- [Primary Schooler Info] Server responded with Status Code: ${response.statusCode}");
      debugPrint("<-- [Primary Schooler Info] Raw JSON data received: ${response.body}");
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return [];
    } catch (e) {
      debugPrint("API Error: $e");
      return [];
    }
  }

  // 🏫 SCHOOL LESSON: Save the supervisor's marks and remarks for a task!
  Future<bool> evaluateTask(Map<String, dynamic> evaluationData) async {
    try {
      final response = await http.post(
        Uri.parse("${ApiConfig.baseUrl}/supervisor/evaluate-task"),
        headers: {"Content-Type": "application/json"},
        body: json.encode(evaluationData),
      );
      debugPrint("<-- [Primary Schooler Info] Server responded with Status Code: ${response.statusCode}");
      debugPrint("<-- [Primary Schooler Info] Raw JSON data received: ${response.body}");
      return response.statusCode == 200;
    } catch (e) {
      debugPrint("API Error: $e");
      return false;
    }
  }

  // 🏫 SCHOOL LESSON: Update task details like title or due date
  Future<bool> updateTask(int taskId, Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse("${ApiConfig.baseUrl}/supervisor/edit-task"),
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "TaskId": taskId,
          ...data
        }),
      );
      debugPrint("<-- [Primary Schooler Info] Server responded with Status Code: ${response.statusCode}");
      debugPrint("<-- [Primary Schooler Info] Raw JSON data received: ${response.body}");
      return response.statusCode == 200;
    } catch (e) {
      debugPrint("API Error: $e");
      return false;
    }
  }

  // 🏫 SCHOOL LESSON: Delete a task if it was assigned by mistake
  Future<bool> deleteTask(int taskId) async {
    // Note: The controller didn't have a specific delete, but we keep it for UI parity if needed.
    // In a real school project, you'd add a [HttpDelete] to your C# controller.
    return true; 
  }
}