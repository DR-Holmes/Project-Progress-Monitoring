import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../../viewmodels/studentviewmodel/student_meeting_view_model.dart';

// --- VIEW ---
// Newbie Note: This screen displays the real-time "Queue" or "Line" for meetings.
// It shows which student groups are currently presenting and who is next in line.
class StudentMeetingQueueView extends StatefulWidget {
  // We receive data about the specific meeting we are tracking.
  final Map<String, dynamic> meeting;
  final bool isCommittee;

  const StudentMeetingQueueView({
    super.key,
    required this.meeting,
    required this.isCommittee,
  }); // End of constructor

  @override
  State<StudentMeetingQueueView> createState() =>
      _StudentMeetingQueueViewState();
} // End of StudentMeetingQueueView class

class _StudentMeetingQueueViewState extends State<StudentMeetingQueueView> {
  // Connecting to the ViewModel for data fetching.
  final StudentMeetingViewModel _viewModel = StudentMeetingViewModel();

  // _meetings will hold the list of all groups in the queue for today.
  List<Map<String, dynamic>> _meetings = [];
  bool _isLoading = true;
  
  // Timer is used to automatically refresh the page every few seconds.
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // 1. Load the queue data immediately when the screen opens.
    _fetchQueue();

    // 2. Set up a "Heartbeat" timer to refresh the data every 5 seconds.
    // FYP TALKING POINT: "To ensure students have real-time information without manually refreshing, we implemented a periodic Timer that fetches the latest queue status every 5 seconds."
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _fetchQueue();
    }); // End of Timer.periodic
  } // End of initState method

  @override
  void dispose() {
    // 3. IMPORTANT: Stop the timer when the user leaves the screen.
    // Newbie Note: If you don't cancel timers, they keep running in the background and can crash your app!
    _timer?.cancel();
    super.dispose();
  } // End of dispose method

  // --- LOGIC SECTION ---

  // Fetches the latest queue data from the server.
  Future<void> _fetchQueue() async {
    try {
      // Extract the FYP type (FYP-1 or FYP-2) from the meeting data.
      String type = widget.meeting['type'] ?? widget.meeting['Type'] ?? "FYP-1";

      // Request the latest live queue from the ViewModel.
      final data = await _viewModel.getTodayLiveQueue(type);

      // Log the data for debugging purposes.
      debugPrint("Queue Data Received: ${jsonEncode(data)}");

      // Update the UI with the fresh data from the server.
      if (mounted) {
        // _meetings now contains the latest group list.
        // This tells Flutter to rebuild the list on the screen.
        setState(() {
          _meetings = data;
          _isLoading = false;
        }); // End of setState
      } // End of if (mounted)
    } catch (e) {
      debugPrint("Error in _fetchQueue: $e");
      // If an error occurs, we still stop the loading spinner.
      if (mounted) {
        // Data load failed, but we stop the spinner anyway.
        setState(() => _isLoading = false);
      } // End of if (mounted)
    } // End of catch
  } // End of _fetchQueue method

  // --- UI SECTION ---

  @override
  Widget build(BuildContext context) {
    // FYP TALKING POINT: "We use client-side filtering to separate the data into 'Ongoing' and 'Waiting' categories. This provides a clear visual distinction for the user."
    
    // Filter for groups currently presenting.
    final inProgress = _meetings.where((m) {
      String status = m['Status']?.toString().toLowerCase() ?? "";
      return status == "in-progress" || status == "in meeting" || status == "presenting";
    }).toList(); // End of inProgress filter

    // Filter for groups waiting in the queue.
    final waiting = _meetings.where((m) {
      String status = m['Status']?.toString().toLowerCase() ?? "";
      return status == "waiting" || status == "queued";
    }).toList(); // End of waiting filter

    // Newbie Note: Scaffold is the basic layout structure of the page.
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          "Meeting Queue",
          style: TextStyle(fontWeight: FontWeight.bold),
        ), // End of Text
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ), // End of AppBar
      
      // Show a spinner if we are loading, otherwise show the list.
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            ) // End of Center
          : RefreshIndicator(
              // Allows the user to manually pull down to refresh.
              onRefresh: _fetchQueue,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // --- SECTION 1: ONGOING MEETINGS ---
                  _buildHeader("Ongoing Meeting"),
                  if (inProgress.isEmpty)
                    _buildEmptyBox("No ongoing meetings right now.")
                  else
                    // Map the in-progress list to individual cards.
                    ...inProgress.map((g) => _buildQueueCard(g, Colors.green)),

                  const SizedBox(height: 24),

                  // --- SECTION 2: WAITING GROUPS ---
                  _buildHeader("Waiting Groups"),
                  if (waiting.isEmpty && inProgress.isEmpty && _meetings.isNotEmpty)
                    // Edge case: if filters fail, show everything as waiting.
                    ..._meetings.map((g) => _buildQueueCard(g, Colors.blueGrey))
                  else if (waiting.isEmpty)
                    _buildEmptyBox("No groups are waiting.")
                  else
                    // Map the waiting list to individual cards.
                    ...waiting.map((g) => _buildQueueCard(g, Colors.orange)),

                  const SizedBox(height: 30),

                  // --- NAVIGATION BUTTONS ---
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4A65FF),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ), // End of RoundedRectangleBorder
                      ), // End of styleFrom
                      // FYP TALKING POINT: "popUntil ensures that we clear the navigation stack and return directly to the main dashboard."
                      onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                      child: const Text(
                        "Back to Home",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ), // End of TextStyle
                      ), // End of Text
                    ), // End of ElevatedButton
                  ), // End of SizedBox
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Back to List", style: TextStyle(color: Colors.grey)),
                  ), // End of TextButton
                ], // End of ListView children
              ), // End of ListView
            ), // End of RefreshIndicator
    ); // End of Scaffold
  } // End of build method

  // Helper function to build section titles.
  Widget _buildHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ), // End of TextStyle
      ), // End of Text
    ); // End of Padding
  } // End of _buildHeader method

  // Helper function for empty state boxes.
  Widget _buildEmptyBox(String text) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ), // End of BoxDecoration
      child: Text(
        text,
        style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
      ), // End of Text
    ); // End of Container
  } // End of _buildEmptyBox method

  // Helper function to build the Group Cards.
  // Newbie Note: This builds a pretty card for each group in the list.
  Widget _buildQueueCard(Map<String, dynamic> group, Color accentColor) {
    // Extracting data from the group map.
    // The "Map" Cheat Sheet:
    // Expected keys: 'GroupIDs' (or 'groupId'), 'Status', 'MeetingTitle' (or 'title'), 'MeetingTime' (or 'time').
    String status = group['Status']?.toString() ?? "Unknown";
    bool isWaiting = status.toLowerCase() == "waiting";

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade100,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ), // End of BoxShadow
        ], // End of boxShadow
      ), // End of BoxDecoration
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Group ID and Status Badge.
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Group ${group['GroupIDs'] ?? group['groupId'] ?? 'N/A'}",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ), // End of TextStyle
              ), // End of Text
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ), // End of EdgeInsets
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ), // End of BoxDecoration
                child: Text(
                  status,
                  style: TextStyle(
                    color: accentColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ), // End of TextStyle
                ), // End of Text
              ), // End of Container
            ], // End of Row children
          ), // End of Row
          const SizedBox(height: 8),

          // Meeting Title.
          Text(
            group['MeetingTitle'] ?? group['title'] ?? "Project Meeting",
            style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
          ), // End of Text

          const SizedBox(height: 12),

          // Bottom Row: Time Icon and Estimated Time.
          Row(
            children: [
              Icon(Icons.access_time, size: 16, color: Colors.grey.shade500),
              const SizedBox(width: 6),
              Text(
                isWaiting
                    ? "Estimated: ${group['MeetingTime'] ?? group['time'] ?? 'TBD'}"
                    : "Estimated: Now",
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ), // End of Text
            ], // End of Row children
          ), // End of Row
        ], // End of Column children
      ), // End of Column
    ); // End of Container
  } // End of _buildQueueCard method
} // End of _StudentMeetingQueueViewState class
