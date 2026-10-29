import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../api_config.dart';

// ---------------------------------------------------------
// WHAT IS THIS FILE?
// This is the "Brain" (ViewModel) for the Supervisor's "Suggest Project" screen.
// It handles:
// - Getting the latest active Session ID so the suggested project can be offered.
// - Inserting a new project into the 'Projects' table.
// - Auto-offering the created project for the current session.
// ---------------------------------------------------------

class SupervisorSuggestProjectViewModel {
  bool isLoading = false;
  bool isSubmitting = false;

  // ---------------------------------------------------------
  // FUNCTION: suggestNewProject
  // Calls the unified C# endpoint route: /api/supervisor/suggestProject.
  // This single call handles inserting the project and auto-offering it.
  // ---------------------------------------------------------
  Future<bool> suggestNewProject(
    String title,
    String objectives,
    String supervisorId,
    bool isActive,
  ) async {
    isSubmitting = true;
    try {
      debugPrint("--> [Primary Schooler] Suggesting project via unified supervisor endpoint...");

      final url = Uri.parse("${ApiConfig.baseUrl}/supervisor/suggest-project");
      final body = json.encode({
        "Title": title,
        "Objectives": objectives,
        "SupervisorId": supervisorId,
        "ProjectStatus": isActive,
      });

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: body,
      );

      isSubmitting = false;
      return response.statusCode == 200 || response.statusCode == 201;

    } catch (e) {
      debugPrint("!!! [Primary Schooler Error] Failed to suggest project: $e");
      isSubmitting = false;
      return false;
    }
  }
}
