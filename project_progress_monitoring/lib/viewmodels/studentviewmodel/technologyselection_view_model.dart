import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../api_config.dart';

// --- VIEWMODEL ---
// This class handles the logic for technology selection.
// In the FYP process, every student must choose a technology (e.g., Flutter, React, AI) 
// before they can form a group. This class talks to the API to fetch those options and save the choice.
class TechnologySelectionViewModel {

  /// Fetches all available technologies from the server
  // The "List" Cheat Sheet:
  // Each technology in the list has:
  // - 'id': The unique number for the tech.
  // - 'name': The display name (e.g., "Web Development").
  Future<List<dynamic>> getTechnologies() async {
    try {
      // FYP TALKING POINT: "We fetch these dynamically from the database so that if the university adds a new technology track (like Blockchain), it automatically appears in the app without an update."
      final url = Uri.parse("${ApiConfig.baseUrl}/users/allTech");
      debugPrint("--> [Primary Schooler Info] Visiting web address: $url");
      final response = await http.get(url);
      debugPrint("<-- [Primary Schooler Info] Server responded with Status Code: ${response.statusCode}");
      debugPrint("<-- [Primary Schooler Info] Raw JSON data received: ${response.body}");

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        debugPrint("Error fetching techs: ${response.statusCode}");
        return [];
      } // End of if/else status
    } catch (e) {
      debugPrint("Exception fetching techs: $e");
      return [];
    } // End of catch (e)
  } // End of getTechnologies method

  /// Updates the student's selected technology in the database
  Future<bool> updateTechnology(String regNum, int techId) async {
    try {
      // FYP TALKING POINT: "A student can only choose their technology once during the initial setup. This choice is vital because it determines which students they can partner with for their project."
      final url = Uri.parse("${ApiConfig.baseUrl}/users/UpdateSelectedTech/$regNum");
      debugPrint("--> [Primary Schooler Info] Visiting web address: $url");

      // Constructing body based on the C# model: public class UpdateSelectedTechModel { public int SelectedTech { get; set; } }
      final body = jsonEncode({
        "SelectedTech": techId
      }); // End of jsonEncode

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: body,
      ); // End of http.post

      debugPrint("Update Tech Response: ${response.statusCode} - ${response.body}");
      debugPrint("<-- [Primary Schooler Info] Server responded with Status Code: ${response.statusCode}");
      debugPrint("<-- [Primary Schooler Info] Raw JSON data received: ${response.body}");

      if (response.statusCode == 200) {
        return true;
      } else {
        return false;
      } // End of if/else status
    } catch (e) {
      debugPrint("Exception updating tech: $e");
      return false;
    } // End of catch (e)
  } // End of updateTechnology method
} // End of TechnologySelectionViewModel class