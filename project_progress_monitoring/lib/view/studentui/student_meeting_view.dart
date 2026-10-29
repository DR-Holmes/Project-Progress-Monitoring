import 'package:flutter/material.dart';
import '../../viewmodels/studentviewmodel/student_meeting_view_model.dart';
import 'student_meeting_queue_view.dart';
import 'student_meetingdetails_view.dart';

// --- VIEW ---
// Newbie Note: This is the main screen where students can see their upcoming, today's, and past meetings.
// It is a StatefulWidget because it needs to fetch and display data that changes over time.
class StudentMeetingView extends StatefulWidget {
  // We pass the user's information as a Map to this screen.
  final Map<String, dynamic> userMap;
  const StudentMeetingView({super.key, required this.userMap});

  @override
  State<StudentMeetingView> createState() => _StudentMeetingViewState();
} // End of StudentMeetingView class

class _StudentMeetingViewState extends State<StudentMeetingView> {
  // Connecting to the ViewModel which handles all the data logic.
  final StudentMeetingViewModel _viewModel = StudentMeetingViewModel();
  
  // Local state variables to store the meeting lists.
  // These are Lists of Maps, where each Map represents a single meeting's data.
  List<Map<String, dynamic>> _upcoming = [];
  List<Map<String, dynamic>> _today = [];
  List<Map<String, dynamic>> _past = [];
  
  // Loading state to show a spinner while data is being fetched.
  bool _isLoading = true;
  String _type = ""; // Will store the student's FYP type (e.g., FYP-1 or FYP-2).
  int? _groupId; // Will store the student's unique Group ID.
  String _activeTab = "Committee"; // Added to match React toggle

  // Supervisor-specific lists
  List<Map<String, dynamic>> _supUpcoming = [];
  List<Map<String, dynamic>> _supToday = [];
  List<Map<String, dynamic>> _supPast = [];

  @override
  void initState() {
    super.initState();
    // FYP TALKING POINT: "The initState method is the first thing that runs when a widget is created. We use it here to trigger the initial data load for the screen."
    _initData();
  } // End of initState method

  // --- LOGIC SECTION (ViewModel Interaction) ---

  // Initialize data: get student details first, then fetch all meetings.
  Future<void> _initData() async {
    // 1. Setting loading to true to show the progress spinner.
    // This variable tells the build method to show a loading icon.
    setState(() => _isLoading = true);
    
    // 2. Ask the ViewModel for the student's details.
    final studentData = await _viewModel.getStudentDetails(widget.userMap['id'] ?? "");
    
    if (studentData != null) {
      // Extract GroupId and FYP Type from the student data map.
      _groupId = studentData['GroupId'] ?? studentData['groupId'];
      _type = studentData['FypType'] ?? studentData['fypType'] ?? "FYP-1"; // Default to FYP-1 if not found.
      
      if (_groupId != null && _type.isNotEmpty) {
        // If we have a group ID, fetch the meetings lists.
        await _refreshMeetings();
      } // End of if (_groupId != null)
    } // End of if (studentData != null)
    
    // 3. Data load is finished, turn off the loading spinner.
    // If the widget is still on screen, we update the UI.
    if (mounted) {
      // _isLoading is now false.
      // This tells Flutter to remove the spinner and draw the actual list of meetings.
      setState(() => _isLoading = false);
    } // End of if (mounted)
  } // End of _initData method

  // Refreshes all meeting lists.
  Future<void> _refreshMeetings() async {
    if (_groupId == null) return;

    // FYP TALKING POINT: "We use Future.wait to fetch multiple categories of meetings simultaneously. This makes the app faster by not waiting for one request to finish before starting the next."
    final results = await Future.wait([
      _viewModel.fetchMeetings(_groupId!, _type, "upcoming"),
      _viewModel.fetchMeetings(_groupId!, _type, "today"),
      _viewModel.fetchMeetings(_groupId!, _type, "past"),
      _viewModel.fetchSupervisorMeetings(_groupId!),
    ]); // End of Future.wait

    if (mounted) {
      final supervisorData = results[3] as Map<String, List<Map<String, dynamic>>>;
      
      setState(() {
        _upcoming = results[0] as List<Map<String, dynamic>>;
        _today = results[1] as List<Map<String, dynamic>>;
        _past = results[2] as List<Map<String, dynamic>>;
        
        _supUpcoming = supervisorData['upcoming']!;
        _supToday = supervisorData['today']!;
        _supPast = supervisorData['past']!;
      }); // End of setState
    } // End of if (mounted)
  } // End of _refreshMeetings method

  // --- UI SECTION (Building the Screen) ---

  @override
  Widget build(BuildContext context) {
    // Newbie Note: Scaffold is the "blank canvas" for your screen. It provides the Appbar and Body.
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Meetings", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        actions: const [],
      ), // End of AppBar
      
      // If data is still loading, show a center spinner. Otherwise, show the content.
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator()) 
          : Column(
              children: [
                // Tab Switcher
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Row(
                      children: [
                        _tabButton("Committee"),
                        _tabButton("Supervisor"),
                      ],
                    ),
                  ),
                ),
                
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _refreshMeetings,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // --- Dynamic Sections based on active tab ---
                          _sectionTitle("Upcoming", _currentUpcoming.length),
                          if (_currentUpcoming.isEmpty) _emptyState("No upcoming meetings")
                          else ..._currentUpcoming.map((m) => _meetingCard(m, Colors.blueAccent)),

                          const SizedBox(height: 30),

                          _sectionTitle("Today", _currentToday.length),
                          if (_currentToday.isEmpty) _emptyState("No meetings today")
                          else ..._currentToday.map((m) => _meetingCard(m, Colors.green, isToday: true)),

                          const SizedBox(height: 30),

                          _sectionTitle("Past", _currentPast.length),
                          if (_currentPast.isEmpty) _emptyState("No past meetings")
                          else ..._currentPast.map((m) => _meetingCard(m, Colors.grey)),
                          
                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
      // Floating Action Button (FAB) for Live Queue.
      // Only show for Committee meetings as Supervisor meetings don't have a live queue system
      floatingActionButton: _activeTab == "Committee" ? FloatingActionButton(
        backgroundColor: const Color(0xFF4A65FF),
        onPressed: () {
          if (_today.isNotEmpty) {
             Navigator.push(
              context, 
              MaterialPageRoute(builder: (_) => StudentMeetingQueueView(meeting: _today.first, isCommittee: true))
            ); 
          } else {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No live queue today")));
          }
        },
        child: const Icon(Icons.live_tv, color: Colors.white),
      ) : null, // End of FloatingActionButton
    ); // End of Scaffold
  } // End of build method

  // Getters to return the correct lists based on active tab
  List<Map<String, dynamic>> get _currentUpcoming => _activeTab == "Committee" ? _upcoming : _supUpcoming;
  List<Map<String, dynamic>> get _currentToday => _activeTab == "Committee" ? _today : _supToday;
  List<Map<String, dynamic>> get _currentPast => _activeTab == "Committee" ? _past : _supPast;

  // Helper for the tab switcher buttons
  Widget _tabButton(String title) {
    bool isActive = _activeTab == title;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _activeTab = title),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isActive ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))] : [],
          ),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                color: isActive ? const Color(0xFF4A65FF) : Colors.grey,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Section title widget helper.
  Widget _sectionTitle(String title, int count) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        "$title ($count)",
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
      ), // End of Text
    ); // End of Padding
  } // End of _sectionTitle method

  // Empty state placeholder widget helper.
  Widget _emptyState(String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Text(message, style: const TextStyle(color: Colors.grey, fontSize: 14)),
    ); // End of Padding
  } // End of _emptyState method

  // Meeting card widget (Premium design but simple implementation).
  // Newbie Note: This builds a reusable card for each meeting in our lists.
  Widget _meetingCard(Map<String, dynamic> m, Color accentColor, {bool isToday = false}) {
    // 1. Formatting date and time from the map data.
    String dateStr = m['date'] != null ? m['date'].toString().split('T')[0] : "No Date";
    String timeStr = m['time']?.toString() ?? "TBD";

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.grey.shade100, blurRadius: 10, offset: const Offset(0, 4)),
        ], // End of boxShadow
      ), // End of BoxDecoration
      child: InkWell(
        // InkWell adds a nice "ripple" effect when the card is tapped.
        onTap: () {
          // Navigate to the Meeting Details screen.
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => StudentMeetingdetailsView(meeting: m))
          ); // End of Navigator.push
        }, // End of onTap
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // --- Icon Container ---
              Container(
                height: 50, width: 50,
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ), // End of BoxDecoration
                child: Icon(Icons.groups_outlined, color: accentColor),
              ), // End of Container
              const SizedBox(width: 15),
              
              // --- Content Section ---
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      m['title'] ?? "FYP Meeting",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ), // End of Text
                    const SizedBox(height: 4),
                    Text(
                      "$dateStr • $timeStr",
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                    ), // End of Text
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(m['location'] ?? m['venue'] ?? "Online", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      ], // End of Row children
                    ) // End of Row
                  ], // End of Column children
                ), // End of Column
              ), // End of Expanded
              
              // --- Today Indicator or Arrow ---
              if (isToday)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(8)),
                  child: const Text("LIVE", style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
                ) // End of Container
              else
                const Icon(Icons.chevron_right, color: Colors.grey),
            ], // End of Row children
          ), // End of Row
        ), // End of Padding
      ), // End of InkWell
    ); // End of Container
  } // End of _meetingCard method
} // End of _StudentMeetingViewState class