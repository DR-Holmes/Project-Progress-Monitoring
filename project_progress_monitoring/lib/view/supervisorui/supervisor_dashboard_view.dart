import 'package:flutter/material.dart';
import '../../viewmodels/supervisorviewmodel/supervisor_dashboard_viewmodel.dart';
import 'schedule_meeting_view.dart';
import 'view_meetings_view.dart';
import 'assign_task_view.dart';
// --- ADDED IMPORT FOR ALL TASKS ---
import 'all_tasks_view.dart';
import 'supervisor_profile_view.dart';
import 'group_details_view.dart';
import 'attendance_progress_view.dart';
import 'mid_evaluation_view.dart';
import 'supervisor_suggest_project_view.dart';


class SupervisorDashboardView extends StatefulWidget {
  final List<Map<String, dynamic>> userData;

  const SupervisorDashboardView({super.key, required this.userData});

  @override
  State<SupervisorDashboardView> createState() => _SupervisorDashboardViewState();
}

class _SupervisorDashboardViewState extends State<SupervisorDashboardView> {
  final SupervisorDashboardViewModel _viewModel = SupervisorDashboardViewModel();
  String _activeTab = "FYP-1";
  int _bottomNavIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _viewModel.isLoading = true);
    await _viewModel.fetchDashboardData(widget.userData[0]['id'].toString(), _activeTab);
    setState(() {});
  }

  void _switchTab(String tab) {
    if (_activeTab == tab) return;
    setState(() => _activeTab = tab);
    _loadData();
  }

  // Common Navigation Helpers
  void _goToMeetings() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ViewMeetingsView(userMap: widget.userData[0])),
    );
  }

  void _goToAssignTask() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AssignTaskView(userMap: widget.userData[0])),
    );
  }

  // --- ADDED NAVIGATION HELPER FOR ALL TASKS ---
  void _goToAllTasks() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AllTasksView(userMap: widget.userData[0])),
    );
  }

  void _goToSuggestProject() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SupervisorSuggestProjectView(userMap: widget.userData[0])),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text("Supervisor Dashboard",
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.blue),
            onPressed: () {},
          ),
        ],
      ),
      body: _viewModel.isLoading
          ? const Center(child: CircularProgressIndicator())
          : (_bottomNavIndex == 3
              ? SupervisorProfileView(userMap: widget.userData[0])
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFypTabs(),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("My Groups",
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 12),
                              _buildGroupListContainer(),
                              const SizedBox(height: 24),
                              const Text("Quick Actions",
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 12),
                              _buildQuickActionsGrid(),
                              const SizedBox(height: 30),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                )),
      floatingActionButton: FloatingActionButton(
        onPressed: _goToAssignTask,
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        currentIndex: _bottomNavIndex,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          setState(() => _bottomNavIndex = index);
          if (index == 1) {
            _goToMeetings();
          } else if (index == 2) {
            _goToAllTasks();
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Dashboard"),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: "Meetings"),
          BottomNavigationBarItem(icon: Icon(Icons.assignment), label: "Tasks"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }

  // --- UI COMPONENT METHODS ---

  Widget _buildFypTabs() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          _tabButton("FYP-1", true),
          _tabButton("FYP-2", false),
        ],
      ),
    );
  }

  Widget _tabButton(String label, bool isLeft) {
    bool isActive = _activeTab == label;
    return Expanded(
      child: GestureDetector(
        onTap: () => _switchTab(label),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? Colors.blue : Colors.grey.shade200,
            borderRadius: isLeft
                ? const BorderRadius.horizontal(left: Radius.circular(8))
                : const BorderRadius.horizontal(right: Radius.circular(8)),
          ),
          alignment: Alignment.center,
          child: Text(label,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isActive ? Colors.white : Colors.grey.shade600
              )),
        ),
      ),
    );
  }

  Widget _buildGroupListContainer() {
    if (_viewModel.myGroups.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 30),
        alignment: Alignment.center,
        child: Text("No $_activeTab groups assigned.",
            style: TextStyle(color: Colors.grey.shade600)),
      );
    }

    return Container(
      height: 320,
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: _viewModel.myGroups.length,
        itemBuilder: (context, index) => _buildGroupCard(_viewModel.myGroups[index]),
      ),
    );
  }

  Widget _buildGroupCard(Map<String, dynamic> group) {
    List<dynamic> members = group['Members'] ?? [];
    int progress = group['Progress'] ?? 0;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => GroupDetailsView(group: group, userMap: widget.userData[0], fypType: _activeTab),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4, offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // The backend returns 'groupName' as the Group ID (int)
          Text("Group ${group['groupName'] ?? 'N/A'}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          // The backend returns 'projectTitle'
          Text("Project: ${group['projectTitle'] ?? 'Untitled'}",
              style: TextStyle(color: Colors.grey.shade700, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
          const Divider(height: 20),
          // Show ALL members (removed .take(2) to match React)
          ...members.map((m) => Padding(
            padding: const EdgeInsets.only(bottom: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Backend returns 'studentName'
                Text(m['studentName'] ?? 'Unknown', style: const TextStyle(fontSize: 13)),
                // Matches React: {m.technology ?? "—"} | CGPA {m.Cgpa}
                Text("${m['technology'] ?? '—'} | CGPA ${m['Cgpa'] ?? 'N/A'}", style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          )),
          const SizedBox(height: 12),
          // Progress Section (Matches React EXACTLY)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Progress", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              Text("$progress%", style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            // Backend returns 'progress' (int 0-100)
            value: (progress.toDouble()) / 100,
            backgroundColor: Colors.grey.shade200,
            // Matches React logic: >=75 Green, >=50 Yellow, else Red
            color: progress >= 75
                ? Colors.green
                : progress >= 50
                    ? Colors.orange // Flutter's orange looks better than yellow here
                    : Colors.red,
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    ));
  }

  Widget _buildQuickActionsGrid() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _quickActionBtn("Schedule Meeting", () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ScheduleMeetingView(userMap: widget.userData[0])),
              );
            }),

        // Kept this so you can still assign directly from the dashboard
        _quickActionBtn("Assign Task", _goToAssignTask),

        _quickActionBtn("View All Meetings", _goToMeetings),
        _quickActionBtn("Attendance Progress", () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => AttendanceProgressView(userMap: widget.userData[0])));
        }),
        if (_activeTab == "FYP-2")
          _quickActionBtn("Mid Evaluation", () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => MidEvaluationView(userMap: widget.userData[0])));
          }),
        _quickActionBtn("Suggest Project", _goToSuggestProject),
      ],
    );
  }

  Widget _quickActionBtn(String title, VoidCallback onTap) {
    return SizedBox(
      width: (MediaQuery.of(context).size.width / 2) - 24,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.blue),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        child: Text(title, style: const TextStyle(color: Colors.blue, fontSize: 13), textAlign: TextAlign.center),
      ),
    );
  }
}