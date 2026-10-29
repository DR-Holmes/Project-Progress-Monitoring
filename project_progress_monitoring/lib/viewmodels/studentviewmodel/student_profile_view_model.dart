import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../api_config.dart';
import '../../view/login_view.dart';

// --- VIEWMODEL ---
// This class handles the profile-related logic for students.
// It allows fetching detailed info, updating passwords, and logging out.
class StudentProfileViewModel {
  
  // 1. Fetch Student Details
  // FYP TALKING POINT: "We fetch the full profile of the student to show their CGPA, Department, and other academic details that aren't available on the basic login map."
  Future<Map<String, dynamic>> getStudentDetails(String regNum) async {
    try {
      final url = Uri.parse("${ApiConfig.baseUrl}/students/details/$regNum");
      debugPrint("--> [Primary Schooler Info] Visiting web address: $url");
      final response = await http.get(url);
      debugPrint("<-- [Primary Schooler Info] Server responded with Status Code: ${response.statusCode}");
      debugPrint("<-- [Primary Schooler Info] Raw JSON data received: ${response.body}");
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } // End of if (response.statusCode == 200)
    } catch (e) {
      debugPrint("Error fetching student details: $e");
    } // End of catch (e)
    return {};
  } // End of getStudentDetails method

  // 2. Update Password
  // FYP TALKING POINT: "Security is vital. We allow students to update their password at any time via a POST request to the server."
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
    } // End of catch (e)
  } // End of updatePassword method

  // 3. Logout
  // Newbie Note: This function clears the navigation stack so the user cannot press "Back" to return to the dashboard after logging out.
  void logout(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginView()),
      (route) => false,
    ); // End of Navigator
  } // End of logout method
} // End of StudentProfileViewModel class