import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../api_config.dart';

class SupervisorAllocationViewModel {
  List<dynamic> groups = [];
  List<dynamic> supervisors = [];
  List<int> selectedGroupIds = [];
  String allocationMode = "Auto Balanced (Algorithm)";
  bool isLoading = false;

  Future<void> fetchData() async {
    isLoading = true;
    try {
      // Replace with your actual endpoints
      final groupRes = await http.get(Uri.parse("${ApiConfig.baseUrl}/committee-meetings/unassigned-groups"));
      if (groupRes.statusCode == 200) {
        groups = jsonDecode(groupRes.body);
      }

      final superRes = await http.get(Uri.parse("${ApiConfig.baseUrl}/users/supervisors"));
      if (superRes.statusCode == 200) {
        supervisors = jsonDecode(superRes.body);
      }
    } catch (e) {
      print("Error fetching allocation data: $e");
    }
    isLoading = false;
  }

  void toggleGroupSelection(int groupId) {
    if (selectedGroupIds.contains(groupId)) {
      selectedGroupIds.remove(groupId);
    } else {
      selectedGroupIds.add(groupId);
    }
  }
}