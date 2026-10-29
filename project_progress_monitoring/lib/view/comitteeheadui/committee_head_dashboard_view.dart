import 'package:flutter/material.dart';
import '../../viewmodels/comitteeheadviewmodel/committee_head_dashboard_view_model.dart';

// --- Import other screens we want to open ---
import 'committee_head_meeting_queue_view.dart';
// Criteria tab goes directly to the view/edit screen (see case 2 below)
import 'committee_head_profile_view.dart';
import 'fyp1_setup_criteria_view.dart';       // FYP-1: Set up brand new criteria
import 'fyp1_view_edit_criteria_view.dart';  // FYP-1: View and edit saved criteria
import 'fyp2_setup_criteria_view.dart';      // FYP-2: Set up brand new criteria
import 'fyp2_view_edit_criteria_view.dart';  // FYP-2: View and edit saved criteria
import 'general_task_evaluation_view.dart';
import 'grades_view.dart';
import 'grading_analysis_view.dart';
import 'committee_head_project_allocation_view.dart';
import 'general_task_allocation_view.dart';


// ---------------------------------------------------------
// WHAT IS THIS FILE?
// This is the "Face" or "View" of our Committee Head Dashboard.
// It draws everything you see on the screen: Buttons, Text, etc.
// It uses "setState" to refresh the screen when things change.
// ---------------------------------------------------------

class CommitteeHeadDashboardView extends StatefulWidget {
  // This is the information of the user who logged in
  final List<Map<String, dynamic>> userData;

  const CommitteeHeadDashboardView({super.key, required this.userData});

  @override
  State<CommitteeHeadDashboardView> createState() => _CommitteeHeadDashboardViewState();
}

class _CommitteeHeadDashboardViewState extends State<CommitteeHeadDashboardView> {
  // 1. Link to our "Brain" (ViewModel)
  final CommitteeHeadDashboardViewModel _viewModel = CommitteeHeadDashboardViewModel();

  // 2. Local variables to keep track of things on the screen
  int _bottomNavIndex = 0; // Which tab is selected? (0 = Home, 1 = Queue, etc.)
  String _activeFYP = 'FYP-1'; // Which FYP is selected? (Starts with FYP-1)
  bool _showNotifications = false; // Should we show the notification list?
  bool _isLoading = false; // Are we busy loading data?
  
  // A list to hold our notifications (information about messages)
  List<Map<String, dynamic>> _notifications = [];

  @override
  void initState() {
    super.initState();
    // This runs ONCE when the screen first opens
    _loadDashboardData();
  }

  // ---------------------------------------------------------
  // FUNCTION: _loadDashboardData
  // This tells the "Brain" to go get data from the internet.
  // ---------------------------------------------------------
  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true); // Start the loading spinner
    
    if (mounted) {
      setState(() {
        _isLoading = false; // Stop the loading spinner
      });
    }
  }

  // ---------------------------------------------------------
  // BUILD FUNCTION: This is where we draw the UI!
  // ---------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    // ---------------------------------------------------------
    // TAB LOGIC: Which screen should we show in the "body"?
    // ---------------------------------------------------------
    Widget bodyContent;
    switch (_bottomNavIndex) {
      case 0:
        bodyContent = _buildHomeTab(); // Show the main dashboard
        break;
      case 1:
        bodyContent = CommitteeHeadMeetingQueueView(userData: widget.userData);
        break;
      case 2:
        // Open the View/Edit criteria screen directly - matches your React ViewEditCriteria file
        if (_activeFYP == "FYP-1") {
          bodyContent = const Fyp1ViewEditCriteriaView();
        } else {
          bodyContent = const Fyp2ViewEditCriteriaView();
        }
        break;
      case 3:
        bodyContent = CommitteeHeadProfileView(userData: widget.userData);
        break;
      default:
        bodyContent = _buildHomeTab();
    }

    return Scaffold(
      backgroundColor: Colors.grey[50], // Light grey background
      
      // --- THE SELECTED SCREEN ---
      body: bodyContent,

      // --- BOTTOM NAVIGATION BAR ---
      // This is the menu at the bottom that lets us switch screens.
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _bottomNavIndex, // Tell it which button is active
        onTap: (index) {
          // When a button is clicked, update the index and refresh!
          setState(() => _bottomNavIndex = index);
        },
        selectedItemColor: Colors.deepPurple, // Color of the active button
        unselectedItemColor: Colors.grey, // Color of inactive buttons
        type: BottomNavigationBarType.fixed, // Keep the buttons still
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.queue_play_next), label: 'Queue'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Criteria'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  // ---------------------------------------------------------
  // HELPER: Build the "Home" tab content
  // ---------------------------------------------------------
  Widget _buildHomeTab() {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              title: const Text(
                "Committee Head Dashboard",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black),
              ),
              backgroundColor: Colors.white,
              elevation: 1,
              actions: [
                IconButton(
                  icon: const Icon(Icons.notifications_none, color: Colors.black),
                  onPressed: () => setState(() => _showNotifications = !_showNotifications),
                ),
              ],
            ),
            body: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildFypToggleButton("FYP-1"),
                      const SizedBox(width: 10),
                      _buildFypToggleButton("FYP-2"),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(20, 30, 20, 10),
                    child: Text("Quick Actions", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.1,
                      children: [
                        _buildActionCard(
                          icon: Icons.assignment_outlined,
                          label: "Set Criteria",
                          color: Colors.blue,
                          onClick: () {
                            if (_activeFYP == "FYP-1") {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (c) => const Fyp1SetupCriteriaView()),
                              );
                            } else {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (c) => const Fyp2SetupCriteriaView()),
                              );
                            }
                          },
                        ),
                        _buildActionCard(
                          icon: Icons.remove_red_eye_outlined,
                          label: "View Criteria",
                          color: Colors.orange,
                          onClick: () {
                            if (_activeFYP == "FYP-1") {
                              // Open the screen where you VIEW and EDIT saved FYP-1 rules
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (c) => const Fyp1ViewEditCriteriaView()),
                              );
                            } else {
                              // Open the screen where you VIEW and EDIT saved FYP-2 rules
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (c) => const Fyp2ViewEditCriteriaView()),
                              );
                            }
                          },
                        ),
                        _buildActionCard(
                          icon: Icons.queue_play_next,
                          label: "Meeting Queue",
                          color: Colors.purple,
                          onClick: () => setState(() => _bottomNavIndex = 1), // Go to Queue tab
                        ),
                        _buildActionCard(
                          icon: Icons.bar_chart_outlined, // Replaced Award with bar_chart_outlined
                          label: "Grading Analysis",
                          color: Colors.teal,
                          onClick: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (c) => GradingAnalysisView(initialFyp: _activeFYP),
                              ),
                            );
                          },
                        ),
                        _buildActionCard(
                          icon: Icons.assignment_turned_in_outlined,
                          label: "Project Allocation",
                          color: Colors.pink,
                          onClick: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (c) => const CommitteeHeadProjectAllocationView(),
                              ),
                            );
                          },
                        ),
                        if (_activeFYP == 'FYP-2') ...[
                          _buildActionCard(
                            icon: Icons.task_outlined,
                            label: "Task Allocation",
                            color: Colors.blueAccent,
                            onClick: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (c) => const GeneralTaskAllocationDashboardView()),
                              );
                            },
                          ),
                          _buildActionCard(
                            icon: Icons.checklist_rtl_outlined,
                            label: "Task Evaluation",
                            color: Colors.indigo,
                            onClick: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (c) => GeneralTaskEvaluationView(userMap: widget.userData[0], fypType: _activeFYP)),
                              );
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  if (_showNotifications) _buildNotificationsList(),
                ],
              ),
            ),
          );
  }

  // --- HELPER: Build the FYP-1 / FYP-2 Toggle Button ---
  Widget _buildFypToggleButton(String label) {
    bool isSelected = _activeFYP == label;
    return GestureDetector(
      onTap: () {
        // When clicked, change the active FYP and refresh the screen
        setState(() => _activeFYP = label);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.deepPurple : Colors.grey[200],
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // --- HELPER: Build a Single Action Card (Button) ---
  Widget _buildActionCard({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onClick,
  }) {
    return InkWell(
      onTap: onClick,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon in a colored circle
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 12),
            // The Label Text
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  // --- HELPER: Build the Notification List ---
  Widget _buildNotificationsList() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Notifications", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 10),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: Text("No new notifications", style: TextStyle(color: Colors.grey)),
            ),
          ),
          Center(
            child: TextButton(
              onPressed: () => setState(() => _showNotifications = false),
              child: const Text("Close"),
            ),
          ),
        ],
      ),
    );
  }
}