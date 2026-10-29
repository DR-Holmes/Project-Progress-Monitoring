import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
//import '../../viewmodels/comitteeheadviewmodel/grading_analysis_view_model.dart';
import 'package:http/http.dart' as http;
import '../../api_config.dart';
class SupervisorSortedListView extends StatefulWidget {


  const SupervisorSortedListView({super.key });

  @override
  State<SupervisorSortedListView> createState() => _SupervisorSortedListViewState();
}

class _SupervisorSortedListViewState extends State<SupervisorSortedListView> {
  @override
  Future<void> fetchSupervisorDatas(String fypType) async {
    try {
      // 1. Create the web address (URL)
      final url = Uri.parse("${ApiConfig.baseUrl}/grading-analysis/getSortedSUpervisorGrades/fyp='FYP-1'");
      debugPrint("--> [Primary Schooler] Asking for Supervisor Data: $url");

      // 2. Wait for the server to reply
      final response = await http.get(url);

      // 3. Check if the server said "OK" (200)
      if (response.statusCode == 200 && response.body.isNotEmpty) {
        // Translate JSON string into a List of Maps
        suplist2= jsonDecode(response.body);
        setState(() {
          
        });
        // List<dynamic> rawData = jsonDecode(response.body);
        // return rawData.map((item) => item as Map<String, dynamic>).toList();
      }
    } catch (e) {
      debugPrint("!!! [Primary Schooler Error] Failed to fetch supervisor data: $e");
    }
    // Return empty list if it fa
  }
  String fypType="FYP-1";
  void initState()
  {
    fetchSupervisorDatas(fypType);
  }

List<Map<String,dynamic>> suplist=[];
dynamic suplist2;
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: Text("Supervisor Grade")),
      body:
        ListView.builder(itemCount: suplist2.length,
            itemBuilder: (context, index){
          ListTile(
            title: Text("${suplist[index]["SupervisorName"]}")
          );
            })
    );
  }
}
