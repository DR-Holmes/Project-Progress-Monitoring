import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../api_config.dart';

// ============================================================================
//                       --- STUDENT JOIN GROUP BRAIN (VIEW MODEL) ---
// ============================================================================
// PRIMARY SCHOOLER NOTE: 
// What is a "ViewModel"? Think of it like a brain in a jar! 
// This file does NOT draw any colorful buttons or text on your phone screen. 
// Instead, it handles all the "secret calculations" and "server-talking". 
// The View (the screen you see) asks this Brain file to get data or send messages 
// across the internet to the big computer (the server) in the sky!
// ============================================================================
class JoinExistingGroupViewModel {

  // --------------------------------------------------------------------------
  // FUNCTION 1: Fetch Eligible Groups
  // --------------------------------------------------------------------------
  // WHAT IT DOES: 
  // It fetches a list of group groups from the server that this student is allowed to join!
  //
  // WHY IT EXISTS: 
  // We can't let a student join just any random group. They must only see groups that 
  // match their technology level and FYP type, otherwise, it would cause grading errors!
  //
  // HOW IT WORKS:
  // 1. It takes the student's registration number (e.g. '2018-ARID-0996').
  // 2. It opens a virtual highway to the server's endpoint: /students/eligible-groups/{studentId}.
  // 3. It asks the server: "Hey, what groups can this student join?"
  // 4. The server sends back a list of maps, which we return to the screen to draw!
  //
  // VARIABLES:
  // - regNum: The student's unique Arid registration code.
  // - url: The website address where the server is waiting for our question.
  // - response: The packet of data the server sends back containing the status code and text.
  // --------------------------------------------------------------------------
  Future<List<Map<String, dynamic>>> getEligibleGroups(String regNum) async {
    // 1. Prepare the web link to ask the server
    final url = Uri.parse("${ApiConfig.baseUrl}/students/eligible-groups/$regNum");
    debugPrint("--> [Primary Schooler Info] Visiting web address to fetch eligible groups: $url");

    try {
      // 2. Actually call the website and wait for the response packet
      final response = await http.get(url);
      
      // 3. Print out what happened so we can see it in our debug logs
      debugPrint("<-- [Primary Schooler Info] Server responded with Status Code: ${response.statusCode}");
      debugPrint("<-- [Primary Schooler Info] Raw JSON data received: ${response.body}");

      // 4. If the server says "OK" (200), we decode the text into a readable Dart List of Maps!
      if (response.statusCode == 200 && response.body.isNotEmpty) {
        var decodedData = jsonDecode(response.body);

        // EXTRA ROBUST CHECK (Matching React): If the server returns a double-encoded string, decode it again!
        if (decodedData is String) {
          decodedData = jsonDecode(decodedData);
        }

        if (decodedData is List) {
          return decodedData.map((item) => Map<String, dynamic>.from(item)).toList();
        }
      }
    } catch (e) {
      // If something broke (like no internet connection), we print the error here!
      debugPrint("!!! [Primary Schooler Error] Failed to fetch eligible groups: $e");
    }
    
    // Return an empty list if there was an error or nothing was found
    return [];
  } // End of getEligibleGroups method

  // --------------------------------------------------------------------------
  // FUNCTION 2: Join a Group
  // --------------------------------------------------------------------------
  // WHAT IT DOES: 
  // It sends a command to the server asking to put this student inside a specific group!
  //
  // WHY IT EXISTS: 
  // When a student clicks the "Join Group" button on the screen, this function actually 
  // registers them in that group on the central database so their name is linked.
  //
  // HOW IT WORKS:
  // 1. It takes the selected Group's ID number (like 3 or 15).
  // 2. It takes the student's registration number.
  // 3. It makes a POST request to: /committee-meetings/AddStudentToGroup with the query params.
  // 4. If the server says "Success" (200), it returns true. Otherwise, it returns false.
  //
  // VARIABLES:
  // - groupId: The unique number identifying the project group.
  // - regNum: The student's unique Arid registration code.
  // --------------------------------------------------------------------------
  Future<bool> joinGroup(int groupId, String regNum) async {
    // 1. Prepare the API link with the query variables embedded in it
    final url = Uri.parse("${ApiConfig.baseUrl}/committee-meetings/AddStudentToGroup?groupId=$groupId&regNum=$regNum");
    debugPrint("--> [Primary Schooler Info] Visiting web address to join group: $url");

    try {
      // 2. Send the post request to the server with a body payload
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "studentId": regNum,
          "groupId": groupId
        }),
      );
      
      // 3. Print out the response details for developers to read
      debugPrint("<-- [Primary Schooler Info] Server responded with Status Code: ${response.statusCode}");
      debugPrint("<-- [Primary Schooler Info] Raw JSON data received: ${response.body}");

      // 4. Return true if successful, otherwise false
      return response.statusCode == 200;
    } catch (e) {
      // If we couldn't connect, print the error details!
      debugPrint("!!! [Primary Schooler Error] Failed to join group: $e");
      return false;
    }
  } // End of joinGroup method
} // End of JoinExistingGroupViewModel class
