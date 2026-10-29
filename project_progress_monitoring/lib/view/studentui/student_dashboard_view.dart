import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// --- ViewModels ---
// We import the ViewModel because it handles our logic (VVM pattern)
import '../../viewmodels/studentviewmodel/student_dashboard_view_model.dart';

// --- Views for the Bottom Nav ---
import 'tasks_view.dart';
import 'student_meeting_view.dart';
import 'student_profile_view.dart';
import 'student_group_details_view.dart';

// --- VIEW ---
// Newbie Note: This is the main UI screen for the Student Dashboard.
// It is a StatefulWidget because we have data (like tasks and meetings) that changes.
class StudentDashboardView extends StatefulWidget {
  // We pass the logged-in student's details as a simple List of Maps
  final List<Map<String, dynamic>> userData;

  const StudentDashboardView({super.key, required this.userData});

  @override
  State<StudentDashboardView> createState() => _StudentDashboardViewState();
} // End of StudentDashboardView class

class _StudentDashboardViewState extends State<StudentDashboardView> {
  // Connecting the View to its ViewModel
  final StudentDashboardViewModel _viewModel = StudentDashboardViewModel();

  // State variables that will trigger a UI rebuild when changed
  int _currentIndex = 0;
  bool _isLoading = true;
  bool _showNotifications = false;
  Map<String, dynamic> _data = {};
  String _activeMeetingTab = "Committee"; // Added to match React toggle

  @override
  void initState() {
    super.initState();
    // Fetch data as soon as the screen loads
    _loadData();
  } // End of initState

  Future<void> _loadData() async {
    // Changing state: Set isLoading to true
    // This tells Flutter to show the loading spinner instead of the content
    setState(() => _isLoading = true);
    
    String studentId = widget.userData[0]['id'] ?? "";
    
    // We ask the ViewModel to fetch everything from the server
    Map<String, dynamic> data = await _viewModel.getDashboardData(studentId);

    // Make sure the screen is still active before updating
    if (mounted) {
      // Changing state: Update the _data map and turn off the loading spinner
      // This tells Flutter to redraw the screen with the newly fetched data
      setState(() {
        _data = data;
        _isLoading = false;
      }); // End of setState
    } // End of if (mounted)
  } // End of _loadData

  // --- NEW NOTIFICATION ACTIONS ---

  // PRIMARY SCHOOLER NOTE: This method tells the computer to mark one single alert as "seen".
  Future<void> _markOneAsRead(int id) async {
    // We ask the Brain (ViewModel) to tell the server we read this one.
    bool success = await _viewModel.markAsRead(id);
    if (success) {
      // If it worked, we just refresh all our data to clear it from the list.
      _loadData();
    }
  }

  // PRIMARY SCHOOLER NOTE: This method tells the computer to mark EVERY alert as "seen" at once.
  Future<void> _markAllAsRead() async {
    String studentId = widget.userData[0]['id'] ?? "";
    // We ask the Brain to tell the server to clear everything for this student.
    bool success = await _viewModel.markAllAsRead(studentId);
    if (success) {
      // Refresh the screen so the red numbers and list disappear.
      _loadData();
    }
  }

  // --- UI WIDGETS ---

  // Newbie Note: This builds the top part of the screen (Avatar, Greeting, Bell icon)
  Widget _buildHeader() {
    // Get notifications list, default to empty list if null
    List<dynamic> notifs = _data['notifications'] ?? [];

    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 10),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 25,
            backgroundColor: Colors.blueAccent,
            child: Icon(Icons.person, color: Colors.white, size: 30),
          ), // End of CircleAvatar
          const SizedBox(width: 15),
          
          // Expanded forces this column to take up remaining horizontal space
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Hi, ${widget.userData[0]['name'] ?? 'Student'}",
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
                ), // End of Text
                const SizedBox(height: 4),
                const Text(
                  "Your daily adventure starts now",
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ), // End of Text
              ], // End of Column children
            ), // End of Column
          ), // End of Expanded
          
          // Stack lets us put widgets on top of each other (like a red badge over a bell)
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                decoration: BoxDecoration(color: Colors.grey.shade200, shape: BoxShape.circle),
                child: IconButton(
                  icon: const Icon(Icons.notifications_none, color: Colors.black87),
                  onPressed: () {
                    // Changing state: Toggle the _showNotifications boolean
                    // This tells Flutter to either show or hide the notification panel
                    setState(() {
                      _showNotifications = !_showNotifications;
                    }); // End of setState
                  }, // End of onPressed
                ), // End of IconButton
              ), // End of Container
              
              // Only draw the red badge if there are notifications
              if (notifs.isNotEmpty)
                Positioned(
                  right: -2,
                  top: -2,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ), // End of BoxDecoration
                    child: Text(
                      "${notifs.length}",
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ), // End of Text
                  ), // End of Container
                ), // End of Positioned
            ], // End of Stack children
          ), // End of Stack
        ], // End of Row children
      ), // End of Row
    ); // End of Padding
  } // End of _buildHeader

  // Newbie Note: This builds the dropdown panel showing recent alerts
  Widget _buildNotificationsPanel() {
    // If we shouldn't show it, return an empty invisible widget (SizedBox.shrink)
    if (!_showNotifications) return const SizedBox.shrink();

    List<dynamic> notifs = _data['notifications'] ?? [];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, spreadRadius: 1)],
      ), // End of BoxDecoration
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Notifications", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              
              Row(
                children: [
                  // PRIMARY SCHOOLER NOTE: This button clears all alerts with one tap!
                  if (notifs.isNotEmpty)
                    TextButton(
                      onPressed: _markAllAsRead,
                      child: const Text("Mark all", style: TextStyle(fontSize: 12, color: Colors.blue)),
                    ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () {
                      // Changing state: Set _showNotifications to false
                      // This tells Flutter to hide the notification panel
                      setState(() => _showNotifications = false);
                    }, // End of onPressed
                  ),
                ],
              ) // End of Row
            ], // End of Row children
          ), // End of Row
          
          if (notifs.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Center(child: Text("No new notifications", style: TextStyle(color: Colors.grey))),
            ) // End of Padding
          else
            // The "..." is the spread operator. It takes a list of widgets and inserts them here.
            ...notifs.map((n) {
              String dateStr = "Just now";
              if (n['createdAt'] != null) {
                try {
                  dateStr = DateFormat('MMM dd, hh:mm a').format(DateTime.parse(n['createdAt']));
                } catch (e) {
                  dateStr = n['createdAt'].toString();
                } // End of catch
              } // End of if
              
              // PRIMARY SCHOOLER NOTE: We wrap the alert in an "InkWell" so that when you tap it, it triggers the code!
              return InkWell(
                onTap: () {
                  // We get the unique number for this alert and mark it as read.
                  int? id = n['id'] ?? n['Id'];
                  if (id != null) {
                    _markOneAsRead(id);
                  }
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade200),
                  ), // End of BoxDecoration
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(n['title'] ?? "Alert", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 4),
                      Text(n['message'] ?? "", style: const TextStyle(fontSize: 13)),
                      const SizedBox(height: 6),
                      Text(dateStr, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                    ], // End of Column children
                  ), // End of Column
                ), // End of Container
              ); // End of InkWell
            }), // End of map
        ], // End of Column children
      ), // End of Column
    ); // End of Container
  } // End of _buildNotificationsPanel

  // Newbie Note: This builds the three square cards showing numbers (Tasks, Meetings, Group details)
  Widget _buildStatsRow() {
    int activeTasks = (_data['tasks'] as List?)?.length ?? 0;
    int upcomingMeetings = (_data['meetings'] as List?)?.length ?? 0;
    String groupIdStr = _data['groupId'] != null ? "${_data['groupId']}" : "-";

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _statCard(Icons.check_box, "Active Tasks", "$activeTasks", Colors.orange),
          _statCard(Icons.calendar_month, "Meetings", "$upcomingMeetings", Colors.blue),
          _statCard(Icons.trending_up, "Group $groupIdStr", "Details", Colors.green, onTap: () {
            // FYP TALKING POINT: "Clicking 'Details' takes the student to the Group Details screen, where they can see all their teammates and their leader."
            Navigator.push(
              context,
                MaterialPageRoute(
                  builder: (context) => StudentGroupDetailsView(userMap: widget.userData[0]),
                ), // End of MaterialPageRoute
            ); // End of Navigator.push
          }), // End of _statCard
        ], // End of Row children
      ), // End of Row
    ); // End of Padding
  } // End of _buildStatsRow

  // Helper method to draw a single stat square
  Widget _statCard(IconData icon, String label, String value, Color color, {VoidCallback? onTap}) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 5)],
          ), // End of BoxDecoration
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 4),
              Text(label, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey, fontSize: 11)),
            ], // End of Column children
          ), // End of Column
        ), // End of Container
      ), // End of InkWell
    ); // End of Expanded
  } // End of _statCard

  // Newbie Note: Shows a single large card for the next meeting (Committee or Supervisor)
  Widget _buildUpcomingMeeting() {
    List<dynamic> committeeMeetings = _data['meetings'] ?? [];
    List<dynamic> supervisorMeetings = _data['supervisorMeetings'] ?? [];
    
    // Choose which meeting to show based on the toggle
    dynamic nextMeeting = _activeMeetingTab == "Committee" 
        ? (committeeMeetings.isNotEmpty ? committeeMeetings[0] : null)
        : (supervisorMeetings.isNotEmpty ? supervisorMeetings[0] : null);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Next Upcoming Meeting", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              
              // Toggle Button (Committee vs Supervisor)
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    _meetingToggleButton("Committee"),
                    _meetingToggleButton("Supervisor"),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          if (nextMeeting == null)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Text(
                  "No upcoming ${_activeMeetingTab.toLowerCase()} meetings", 
                  style: const TextStyle(color: Colors.grey)
                ),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 5)],
                border: Border.all(color: _activeMeetingTab == "Committee" ? Colors.blue.shade100 : Colors.indigo.shade100),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _activeMeetingTab == "Committee" ? Colors.blue.shade50 : Colors.indigo.shade50, 
                      shape: BoxShape.circle
                    ),
                    child: Icon(
                      Icons.event, 
                      color: _activeMeetingTab == "Committee" ? Colors.blue : Colors.indigo
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          nextMeeting['title'] ?? nextMeeting['Title'] ?? "Meeting", 
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
                        ),
                        const SizedBox(height: 5),
                        Text(
                          nextMeeting['date'] != null || nextMeeting['Date'] != null
                              ? DateFormat('EEE, MMM dd, yyyy').format(DateTime.parse(nextMeeting['date'] ?? nextMeeting['Date'])) 
                              : "Unknown Date",
                          style: const TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _activeMeetingTab == "Committee" ? Colors.blue.withValues(alpha: 0.1) : Colors.indigo.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _activeMeetingTab,
                      style: TextStyle(
                        fontSize: 10, 
                        fontWeight: FontWeight.bold,
                        color: _activeMeetingTab == "Committee" ? Colors.blue : Colors.indigo,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // Helper for the small toggle switch
  Widget _meetingToggleButton(String type) {
    bool isActive = _activeMeetingTab == type;
    return GestureDetector(
      onTap: () => setState(() => _activeMeetingTab = type),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          boxShadow: isActive ? [const BoxShadow(color: Colors.black12, blurRadius: 2)] : [],
        ),
        child: Text(
          type,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            color: isActive ? Colors.black87 : Colors.grey,
          ),
        ),
      ),
    );
  } // End of _buildUpcomingMeeting

  // Newbie Note: Shows a list of recent tasks
  Widget _buildRecentTasks() {
    List<dynamic> tasks = _data['tasks'] ?? [];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Recent Tasks", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              TextButton(
                onPressed: () {
                  // Changing state: Set _currentIndex to 2
                  // This tells Flutter to switch the bottom navigation to the Tasks tab
                  setState(() => _currentIndex = 2);
                }, // End of onPressed
                child: const Text("View All"),
              ), // End of TextButton
            ], // End of Row children
          ), // End of Row
          
          if (tasks.isEmpty)
            const Center(child: Padding(
              padding: EdgeInsets.all(8.0),
              child: Text("No recent tasks", style: TextStyle(color: Colors.grey)),
            )) // End of Padding
          else
            // ListView.builder generates a scrolling list dynamically based on how many items exist
            ListView.builder(
              shrinkWrap: true, // Forces the ListView to only take up as much space as it needs
              physics: const NeverScrollableScrollPhysics(), // Disables scrolling for the list itself (the whole page scrolls instead)
              itemCount: tasks.length,
              itemBuilder: (context, index) {
                final task = tasks[index];
                String dueDateString = "No Date";
                if (task['dueDate'] != null) {
                  try {
                    dueDateString = DateFormat('MMM dd, yyyy').format(DateTime.parse(task['dueDate']));
                  } catch (e) { dueDateString = task['dueDate'].toString(); }
                } // End of if
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 5, spreadRadius: 2)],
                  ), // End of BoxDecoration
                  child: Row(
                    children: [
                      Container(
                        width: 8, height: 70,
                        decoration: const BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.only(topLeft: Radius.circular(15), bottomLeft: Radius.circular(15)),
                        ), // End of BoxDecoration
                      ), // End of Container
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(task['title'] ?? "Task Title", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                            const SizedBox(height: 4),
                            Text("Due: $dueDateString", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                          ], // End of Column children
                        ), // End of Column
                      ), // End of Expanded
                      Container(
                        margin: const EdgeInsets.only(right: 15),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ), // End of BoxDecoration
                        child: Text(task['status'] ?? "Pending", style: const TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.bold)),
                      ) // End of Container
                    ], // End of Row children
                  ), // End of Row
                ); // End of Container
              }, // End of itemBuilder
            ), // End of ListView.builder
        ], // End of Column children
      ), // End of Column
    ); // End of Padding
  } // End of _buildRecentTasks

  // The build method assembles all the widgets we defined above
  @override
  Widget build(BuildContext context) {
    Widget bodyContent;

    // We use a switch statement to determine which page to show based on the bottom nav bar
    switch (_currentIndex) {
      case 0:
        // FYP TALKING POINT: "We show a CircularProgressIndicator while waiting for API data, enhancing the User Experience."
        bodyContent = _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
          onRefresh: _loadData,
          // SingleChildScrollView makes the entire screen scrollable
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                _buildNotificationsPanel(),
                _buildStatsRow(),
                _buildUpcomingMeeting(),
                _buildRecentTasks(),
                const SizedBox(height: 30),
              ], // End of Column children
            ), // End of Column
          ), // End of SingleChildScrollView
        ); // End of RefreshIndicator
        break;
      case 1:
        // Load the Meeting View page
        bodyContent = StudentMeetingView(userMap: widget.userData[0]);
        break;
      case 2:
        // Load the Tasks View page
        bodyContent = TasksView(userMap: widget.userData[0]);
        break;
      case 3:
        // Load the Profile View page
        bodyContent = StudentProfileView(userMap: widget.userData[0]);
        break;
      default:
        bodyContent = const Center(child: Text("Page Not Found"));
    } // End of switch

    // Scaffold provides the structural backbone of the screen
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      // SafeArea ensures UI doesn't overlap with phone notches or status bars
      body: SafeArea(child: bodyContent),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          // Changing state: Update _currentIndex to the tapped icon
          // This tells Flutter to rebuild the Scaffold and swap out the 'bodyContent'
          setState(() => _currentIndex = index);
        }, // End of onTap
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF4A65FF),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: 'Meetings'),
          BottomNavigationBarItem(icon: Icon(Icons.assignment), label: 'Tasks'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ], // End of BottomNavigationBar items
      ), // End of BottomNavigationBar
    ); // End of Scaffold
  } // End of build method
} // End of _StudentDashboardViewState class