import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../api_config.dart';

// This is the ViewModel for Student Login.
// It separates the "Data/Logic" from the "View/UI" (which is the VVM pattern).
class StudentLoginViewmodel {

  // 1. Get Student Details
  // This method fetches the student's data from the backend using their ID.
  // It returns a Future containing a Map<String, dynamic> representing the student data,
  // or null if the fetch fails. This is much simpler than using complex Models.
  Future<Map<String, dynamic>?> getStudentDetails(String id) async {
    // Creating the URL to hit the C# [HttpGet] Route("{id}") endpoint
    final url = Uri.parse("${ApiConfig.baseUrl}/users/$id");
    debugPrint("--> [Primary Schooler Info] Visiting web address: $url");

    try {
      // Send the GET request to the server
      final response = await http.get(url);
      debugPrint("<-- [Primary Schooler Info] Server responded with Status Code: ${response.statusCode}");
      debugPrint("<-- [Primary Schooler Info] Raw JSON data received: ${response.body}");

      // Check if the server responded with a success status code (200 OK)
      if (response.statusCode == 200) {
        // We decode the JSON response string into a simple Map
        final data = jsonDecode(response.body);
        return data as Map<String, dynamic>; // Return the simple map!
      } // End of if (response.statusCode == 200)
    } catch (e) {
      // If there's an error (like no internet), we catch it here and print it
      debugPrint("Error fetching student details: $e");
    } // End of catch

    // Return null if something went wrong
    return null;
  } // End of getStudentDetails method

  // 2. Check if Student is in a Group
  // This method asks the backend if a student belongs to a group already.
  // It returns a Future<bool> which will be true or false.
  Future<bool> isStudentInGroup(String regNum) async {
    // Creating the URL to hit the C# [HttpGet] Route("IsInGroup/{regNum}") endpoint
    final url = Uri.parse("${ApiConfig.baseUrl}/users/IsInGroup/$regNum");
    debugPrint("--> [Primary Schooler Info] Visiting web address: $url");

    try {
      // Send the GET request to the server
      final response = await http.get(url);
      debugPrint("<-- [Primary Schooler Info] Server responded with Status Code: ${response.statusCode}");
      debugPrint("<-- [Primary Schooler Info] Raw JSON data received: ${response.body}");

      // Check if the server responded with a success status code (200 OK)
      if (response.statusCode == 200) {
        // The API returns the string 'true' or 'false', so we check if it matches 'true'
        return response.body.toLowerCase() == 'true';
      } // End of if (response.statusCode == 200)
    } catch (e) {
      // Catch any errors during the request
      debugPrint("Error checking group status: $e");
    } // End of catch

    // Default to returning false if there was an error
    return false; 
  } // End of isStudentInGroup method

} // End of StudentLoginViewmodel class