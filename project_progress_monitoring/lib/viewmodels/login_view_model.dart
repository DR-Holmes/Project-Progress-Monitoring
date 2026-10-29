import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../api_config.dart';

// PRIMARY SCHOOLER NOTE: This class handles all the "Data/Logic" for the Login Screen (ViewModel).
// It acts as the brain that talks to the server to check username/password and direct the user to the right dashboard.
class LoginViewModel {

  /// Main login function that handles all logic and redirection checks.
  /// It takes an ID and a password, and returns a Future (a promise that it will finish later).
  /// The result is a Map containing either an 'error' or a 'route' (where to go next).
  Future<Map<String, dynamic>> login(String id, String password) async {
    try {
      // 1. Fetch User Data by ID from our backend API
      final userUrl = Uri.parse("${ApiConfig.baseUrl}/users/$id");
      debugPrint("--> [Primary Schooler Info] Visiting login credentials url: $userUrl");
      
      // We 'await' the response because fetching from the internet takes time
      final response = await http.get(userUrl);
      debugPrint("<-- [Primary Schooler Info] Server responded with Status Code: ${response.statusCode}");
      debugPrint("<-- [Primary Schooler Info] Raw JSON data received: ${response.body}");

      // 200 means the request was successful
      if (response.statusCode == 200 && response.body.isNotEmpty && response.body != "null") {
        // We decode the JSON text from the server into a simple Map
        Map<String, dynamic> userData = jsonDecode(response.body);

        // 2. Verify Password
        // Check if the password from the database matches what the user typed
        if (userData['password'] != password) {
          debugPrint("!!! [Primary Schooler Info] Warning: Incorrect password typed by the user!");
          // If it doesn't match, we return an error map
          return {'error': 'Invalid username or password'};
        } // End of password check

        // Safely extract the role, defaulting to an empty string if it's missing
        String role = userData['role'] ?? "";
        debugPrint("--> [Primary Schooler Info] Logged in successfully! User role is: $role");

        // ================= STUDENT FLOW =================
        // Students have a special login flow, so we send them to a separate helper function
        if (role == "Student") {
          return await _handleStudentLogic(id, userData);
        } // End of student check

        // ================= OTHER ROLES =================
        // For other roles (Supervisor, Committee, etc.), we simply get their route
        userData['route'] = _getRouteForRole(role);
        debugPrint("--> [Primary Schooler Info] Redirecting user to screen route: ${userData['route']}");
        return userData; // Return the user data along with where they should navigate to

      } else {
        debugPrint("!!! [Primary Schooler Info] Warning: Could not find user on the server.");
        // If the status code isn't 200, the user wasn't found
        return {'error': 'Unable to connect to server or user not found.'};
      } // End of response status check
    } catch (e) {
      // If something crashes (like no internet connection), we catch the error here
      debugPrint("!!! [Primary Schooler Error] Something went wrong in login method: $e");
      return {'error': 'Unable to connect to server.'};
    } // End of catch
  } // End of login method

  /// Handles specific checks for Students: Technology -> Group -> Finalized
  /// This is private (starts with underscore _) so it can only be used inside this file.
  Future<Map<String, dynamic>> _handleStudentLogic(String regNum, Map<String, dynamic> userData) async {
    try {
      // 1. Check Technology Selection
      // If the student hasn't selected a technology yet, send them to the SelectTech screen
      if (userData['selectedTech'] == null) {
        debugPrint("--> [Primary Schooler Info] Student has no Selected Tech. Redirecting to: SelectTech");
        userData['route'] = 'SelectTech';
        return userData;
      } // End of tech check

      // 2. Fetch Enrollment Data
      // We check if the student is actually enrolled in the FYP subject
      final enrollUrl = Uri.parse("${ApiConfig.baseUrl}/users/by-student/$regNum");
      debugPrint("--> [Primary Schooler Info] Verifying student enrollment status at: $enrollUrl");
      
      final enrollResponse = await http.get(enrollUrl);
      debugPrint("<-- [Primary Schooler Info] Server enrollment check answered: ${enrollResponse.statusCode}");

      // If the status is not 200, they aren't enrolled
      if (enrollResponse.statusCode != 200) {
        debugPrint("!!! [Primary Schooler Info] Warning: Student is not enrolled in FYP!");
        return {'error': 'YOU ARE NOT ENROLLED IN FYP. Please contact administration.'};
      } // End of enrollment check

      // 3. Check Group Membership
      // Now we ask the server if this student is already in a group
      final groupUrl = Uri.parse("${ApiConfig.baseUrl}/users/IsInGroup/$regNum");
      debugPrint("--> [Primary Schooler Info] Checking if student belongs to a group at: $groupUrl");
      
      final groupResponse = await http.get(groupUrl);
      debugPrint("<-- [Primary Schooler Info] Server answered group status check: ${groupResponse.body}");

      bool isInGroup = false; // Default to false
      if (groupResponse.statusCode == 200) {
        // The server returns the word 'true' or 'false', we check if it's 'true'
        isInGroup = groupResponse.body.toLowerCase() == 'true';
      } // End of group response check

      if (!isInGroup) {
        debugPrint("--> [Primary Schooler Info] Student is not in a group. Redirecting to: GroupOptions");
        // If they are not in a group, send them to the GroupOptions screen to create or join one
        userData['route'] = 'GroupOptions';
        return userData;
      } // End of if (!isInGroup)

      // 4. Check Group Finalization
      // If they are in a group, we check if the group is finalized (locked in)
      final finalizedUrl = Uri.parse("${ApiConfig.baseUrl}/users/IsFinalized/$regNum");
      debugPrint("--> [Primary Schooler Info] Checking if student's group is finalized at: $finalizedUrl");
      
      final finalizedResponse = await http.get(finalizedUrl);
      debugPrint("<-- [Primary Schooler Info] Server finalized check responded: ${finalizedResponse.body}");

      int isFinalized = 0; // Default to 0 (not finalized)
      if (finalizedResponse.statusCode == 200 && finalizedResponse.body != "null") {
        var finalizedData = jsonDecode(finalizedResponse.body);
        isFinalized = finalizedData['isFinalized'] ?? 0;
      } // End of finalization response check

      // Navigation Logic for Students with a Tech and a Group
      if (isFinalized == 1) {
        debugPrint("--> [Primary Schooler Info] Group is finalized! Redirecting to: StudentDashboard");
        // If the group is finalized, they go straight to their Dashboard
        userData['route'] = 'StudentDashboard';
      } else {
        debugPrint("--> [Primary Schooler Info] Group is NOT finalized yet. Redirecting to: Lobby");
        // If it's not finalized yet, they go to the Lobby to wait or manage their group
        userData['route'] = 'Lobby';
      } // End of finalization check

      return userData; // Return the final map containing the correct route

    } catch (e) {
      debugPrint("!!! [Primary Schooler Error] Something went wrong in student login checks: $e");
      // Catch any errors that happen during the student checks
      return {'error': 'Error in student checks: $e'};
    } // End of catch
  } // End of _handleStudentLogic method

  /// This helper function matches a user's role to the correct Dashboard screen name.
  String _getRouteForRole(String role) {
    // switch statement is like multiple if/else if statements
    switch (role) {
      case "Committee": 
        return "CommitteeDashboard";
      case "Supervisor": 
        return "SupervisorDashboard";
      case "CommitteeHead":
      case "Committee Head": // Checking both with and without space just in case
        return "CommitteeHeadDashboard";
      case "QueueHandler": 
      case "Queue Handler":
        return "QueueHandlerDashboard";
      case "DataCell":
      case "Data Cell":
        return "DataCellDashboard";
      default: 
        return "Unknown"; // If the role doesn't match any of the above
    } // End of switch
  } // End of _getRouteForRole method

} // End of LoginViewModel class