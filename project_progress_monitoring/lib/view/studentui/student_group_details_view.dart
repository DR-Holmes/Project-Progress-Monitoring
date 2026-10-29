import 'package:flutter/material.dart';
import '../../viewmodels/studentviewmodel/student_group_details_view_model.dart';

// --- VIEW ---
// Newbie Note: This screen shows the list of members in the student's group.
// It is a StatefulWidget because it needs to fetch data from the internet when it opens.
class StudentGroupDetailsView extends StatefulWidget {
  // We pass the logged-in student's info as a Map.
  final Map<String, dynamic> userMap;
  
  const StudentGroupDetailsView({super.key, required this.userMap});

  @override
  State<StudentGroupDetailsView> createState() => _StudentGroupDetailsViewState();
} // End of StudentGroupDetailsView class

class _StudentGroupDetailsViewState extends State<StudentGroupDetailsView> {
  // Connecting to the ViewModel for data logic.
  final StudentGroupDetailsViewModel _viewModel = StudentGroupDetailsViewModel();
  
  // Local state to store group data.
  // This is a Map that will hold the 'groupId' and the list of 'members'.
  Map<String, dynamic>? _group;
  
  // Loading state to show a spinner.
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // FYP TALKING POINT: "As soon as the screen loads, we call _loadData to fetch the group information from the API."
    _loadData();
  } // End of initState method

  // --- LOGIC SECTION ---

  // Fetches group data from the ViewModel.
  Future<void> _loadData() async {
    // 1. Show the loading spinner.
    // This tells the UI to display a progress indicator.
    setState(() => _isLoading = true);

    // 2. Ask the ViewModel for the group details.
    // We use the 'id' from the userMap (which is the registration number).
    final data = await _viewModel.fetchGroupDetails(widget.userMap['id'] ?? "");

    // 3. Update the local state with the result.
    if (mounted) {
      // _group will now hold the data from the server.
      // _isLoading becomes false to hide the spinner.
      setState(() {
        _group = data;
        _isLoading = false;
      }); // End of setState
    } // End of if (mounted)
  } // End of _loadData method

  // --- UI SECTION ---

  @override
  Widget build(BuildContext context) {
    // Newbie Note: Scaffold is the basic structure of the page.
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("My Group Details", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ), // End of AppBar
      
      // If we are loading, show a center spinner.
      // If we have no group, show a message.
      // Otherwise, show the list of members.
      body: _isLoading
          ? const Center(child: CircularProgressIndicator()) // End of Center
          : _group == null
              ? _buildEmptyState()
              : _buildGroupContent(),
    ); // End of Scaffold
  } // End of build method

  // Helper function to build the "No Group" message.
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.group_off_outlined, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 20),
          const Text(
            "You are not assigned to any group.",
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ), // End of Text
        ], // End of Column children
      ), // End of Column
    ); // End of Center
  } // End of _buildEmptyState method

  // Helper function to build the actual group list content.
  Widget _buildGroupContent() {
    // Extract the list of members from our data Map.
    final List members = _group!['members'] ?? [];
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Group Header Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(25),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF4A65FF), Color(0xFF6E85FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ), // End of LinearGradient
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(color: const Color(0xFF4A65FF).withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5)),
              ], // End of boxShadow
            ), // End of BoxDecoration
            child: Column(
              children: [
                const Icon(Icons.groups_rounded, color: Colors.white, size: 50),
                const SizedBox(height: 15),
                Text(
                  "Group ID: ${_group!['groupId']}",
                  style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                ), // End of Text
                const SizedBox(height: 5),
                const Text(
                  "Final Year Project Group",
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ), // End of Text
              ], // End of Column children
            ), // End of Column
          ), // End of Container

          const SizedBox(height: 30),

          // Members Title
          const Text(
            "Group Members",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
          ), // End of Text
          const SizedBox(height: 15),

          // List of members
          // FYP TALKING POINT: "We use a spread operator (...) with map() to dynamically build a list of cards for each member in the group."
          ...members.map((m) => _buildMemberCard(m)).toList(),
        ], // End of Column children
      ), // End of Column
    ); // End of SingleChildScrollView
  } // End of _buildGroupContent method

  // Helper function to build a card for a single member.
  Widget _buildMemberCard(Map<String, dynamic> member) {
    // Check if this member is the logged-in student.
    bool isMe = member['regNum'] == widget.userMap['id'];
    // Check if this member is the group admin/leader.
    bool isAdmin = member['isAdmin'] == 1 || member['isAdmin'] == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isMe ? const Color(0xFF4A65FF).withOpacity(0.3) : Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.grey.shade100, blurRadius: 8, offset: const Offset(0, 4)),
        ], // End of boxShadow
      ), // End of BoxDecoration
      child: Row(
        children: [
          // Member Profile Icon
          CircleAvatar(
            backgroundColor: isMe ? const Color(0xFF4A65FF) : Colors.grey.shade200,
            radius: 25,
            child: Icon(Icons.person, color: isMe ? Colors.white : Colors.grey.shade600),
          ), // End of CircleAvatar
          const SizedBox(width: 15),
          
          // Member Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      member['name'] ?? "Unknown",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ), // End of Text
                    if (isMe) ...[
                      const SizedBox(width: 8),
                      const Text("(You)", style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold)),
                    ], // End of if (isMe)
                  ], // End of Row children
                ), // End of Row
                const SizedBox(height: 4),
                Text(
                  "Reg No: ${member['regNum']}",
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ), // End of Text
                const SizedBox(height: 4),
                Text(
                  "Technology: ${member['technology'] ?? 'N/A'}",
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ), // End of Text
              ], // End of Column children
            ), // End of Column
          ), // End of Expanded

          // Admin Badge and CGPA
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (isAdmin)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
                  child: const Text("ADMIN", style: TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold)),
                ), // End of Container
              const SizedBox(height: 8),
              Text(
                "CGPA: ${member['Cgpa']}",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF4A65FF)),
              ), // End of Text
            ], // End of Column children
          ), // End of Column
        ], // End of Row children
      ), // End of Row
    ); // End of Container
  } // End of _buildMemberCard method
} // End of _StudentGroupDetailsViewState class
