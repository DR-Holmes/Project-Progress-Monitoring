import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../api_config.dart';
import '../../view/login_view.dart';
import '../../view/supervisorui/supervisor_dashboard_view.dart';

class CommitteeMemberProfileViewModel {
  Future<bool> updatePassword(String id, String newPassword) async {
    try {
      final url = Uri.parse("${ApiConfig.baseUrl}/students/updatePassword?id=$id&password=${Uri.encodeComponent(newPassword)}");
      debugPrint("--> [Primary Schooler Info] Visiting web address: $url");
      final response = await http.post(url);
      debugPrint("<-- [Primary Schooler Info] Server responded with Status Code: ${response.statusCode}");
      debugPrint("<-- [Primary Schooler Info] Raw JSON data received: ${response.body}");
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      debugPrint("Error updating password: $e");
      return false;
    }
  }

  void logout(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginView()),
      (route) => false,
    );
  }

  void switchToSupervisor(BuildContext context, Map<String, dynamic> userMap) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => SupervisorDashboardView(userData: [userMap])),
      (route) => false
    );
  }
}