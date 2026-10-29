import 'package:flutter/material.dart';
import '../../viewmodels/comitteeviewmodel/committee_dashboard_view_model.dart';

// Import views
import 'committee_meeting_schedule_view.dart';
import 'committee_meeting_queue_view.dart';
import 'student_selection_view.dart';
import 'supervisor_allocation_view.dart';
import 'committee_supervisor_allocation_view.dart';
import 'project_allocation_view.dart';
import 'committee_member_profile_view.dart';
import 'approved_groups_view.dart';
import 'committee_my_meetings_view.dart'; // NEW IMPORT
import 'committee_general_task_evaluation_view.dart'; // NEW IMPORT

class CommitteeDashboardView extends StatefulWidget {
  final List<Map<String, dynamic>> userData;
  const CommitteeDashboardView({super.key, required this.userData});

  @override
  State<CommitteeDashboardView> createState() => _CommitteeDashboardViewState();
}

class _CommitteeDashboardViewState extends State<CommitteeDashboardView> {
  final CommitteeDashboardViewModel _viewModel = CommitteeDashboardViewModel();

  int _bottomNavIndex = 0;
  String _selectedFyp = 'FYP-1';
  String _searchQuery = '';
  String _selectedFilter = 'All';
  bool _isLoading = false;
  List<Map<String, dynamic>> _groupsList = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final data = await _viewModel.fetchGroupsList(_selectedFyp, _searchQuery, _selectedFilter);
    if (mounted) {
      setState(() {
        _groupsList = data;
        _isLoading = false;
      });
    }
  }

  void _setFyp(String fyp) {
    setState(() => _selectedFyp = fyp);
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    Widget bodyContent;
    switch (_bottomNavIndex) {
      case 0:
        bodyContent = _buildHomeTab();
        break;
      case 1:
        // Meeting Queue — mobile fixed view
        bodyContent = CommitteeMeetingQueueView(userData: widget.userData);
        break;
      case 2:
        bodyContent = const Center(child: Text("Tasks Management"));
        break;
      case 3:
        bodyContent = CommitteeMemberProfileView(userData: widget.userData);
        break;
      default:
        bodyContent = _buildHomeTab();
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _bottomNavIndex == 0
          ? AppBar(
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Committee Panel',
                      style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18)),
                  Text('Welcome, ${widget.userData[0]['name'] ?? 'Member'}',
                      style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
              backgroundColor: Colors.white,
              elevation: 0,
              iconTheme: const IconThemeData(color: Colors.black),
              actions: [
                IconButton(
                  icon: const Icon(Icons.notifications_none, color: Colors.blueAccent),
                  onPressed: () {},
                ),
              ],
            )
          : AppBar(
              title: Text(
                _bottomNavIndex == 1 ? 'Meeting Queue' : _bottomNavIndex == 2 ? 'Tasks' : 'Profile',
                style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
              ),
              backgroundColor: Colors.white,
              elevation: 0,
              iconTheme: const IconThemeData(color: Colors.black),
            ),
      body: SafeArea(child: bodyContent),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _bottomNavIndex,
        onTap: (index) => setState(() => _bottomNavIndex = index),
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: 'Meetings'),
          BottomNavigationBarItem(icon: Icon(Icons.task_alt), label: 'Tasks'),
          BottomNavigationBarItem(icon: Icon(Icons.person_pin), label: 'Profile'),
        ],
      ),
    );
  }

  // ─────────────────── HOME TAB ───────────────────
  Widget _buildHomeTab() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFypToggle(),
            const SizedBox(height: 20),
            const Text("Quick Actions", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildQuickActionsGrid(),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Groups ($_selectedFyp)', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                IconButton(icon: const Icon(Icons.refresh, size: 20), onPressed: _loadData),
              ],
            ),
            const SizedBox(height: 8),
            _isLoading
                ? const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
                : _buildGroupsList(),
          ],
        ),
      ),
    );
  }

  Widget _buildFypToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: ['FYP-1', 'FYP-2'].map((fyp) {
          bool isSel = _selectedFyp == fyp;
          return Expanded(
            child: GestureDetector(
              onTap: () => _setFyp(fyp),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSel ? Colors.blueAccent : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(fyp,
                      style: TextStyle(
                          color: isSel ? Colors.white : Colors.black,
                          fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildQuickActionsGrid() {
    final actions = [
      {
        't': 'Student Selection',
        'i': Icons.how_to_reg,
        'c': Colors.blue,
        'action': () => Navigator.push(context, MaterialPageRoute(builder: (c) => const StudentSelectionView())),
      },
      {
        't': 'Supervisor Alloc.',
        'i': Icons.person_add,
        'c': Colors.purple,
        'action': () => Navigator.push(context, MaterialPageRoute(builder: (c) => const CommitteeSupervisorAllocationView())),
      },
      {
        't': 'Project Alloc.',
        'i': Icons.assignment_outlined,
        'c': Colors.orange,
        'action': () => Navigator.push(context, MaterialPageRoute(builder: (c) => const ProjectAllocationView())),
      },
      {
        't': 'Schedule Meeting',
        'i': Icons.add_alarm_outlined,
        'c': Colors.teal,
        'action': () => Navigator.push(context, MaterialPageRoute(builder: (c) => CommitteeMeetingScheduleView(fypType: _selectedFyp, userData: widget.userData))),
      },
      {
        't': 'Meeting Queue',
        'i': Icons.queue_play_next,
        'c': Colors.green,
        'action': () => Navigator.push(context, MaterialPageRoute(builder: (c) => CommitteeMeetingQueueView(userData: widget.userData))),
      },
      {
        't': 'View Meetings',
        'i': Icons.calendar_month_outlined,
        'c': Colors.indigo,
        'action': () => setState(() => _bottomNavIndex = 1),
      },
      {
        't': 'Approved Groups',
        'i': Icons.task_alt,
        'c': Colors.deepOrange,
        'action': () => Navigator.push(context, MaterialPageRoute(builder: (c) => ApprovedGroupsView(activeFyp: _selectedFyp))),
      },
      {
        't': 'My Meetings', // NEW ACTION
        'i': Icons.event_note,
        'c': Colors.pink,
        'action': () => Navigator.push(context, MaterialPageRoute(builder: (c) => CommitteeMyMeetingsView(userData: widget.userData))),
      },
      {
        't': 'Task Evaluation',
        'i': Icons.checklist_rtl_outlined,
        'c': Colors.blueGrey,
        'action': () => Navigator.push(context, MaterialPageRoute(builder: (c) => CommitteeGeneralTaskEvaluationView(userMap: widget.userData[0], fypType: _selectedFyp))),
      },
    ];


    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.9,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
      ),
      itemCount: actions.length,
      itemBuilder: (context, i) {
        final Color color = actions[i]['c'] as Color;
        return InkWell(
          onTap: actions[i]['action'] as VoidCallback,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4, offset: const Offset(0, 2))],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(actions[i]['i'] as IconData, color: color, size: 24),
                ),
                const SizedBox(height: 8),
                Text(
                  actions[i]['t'] as String,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGroupsList() {
    if (_groupsList.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 30),
          child: Column(
            children: [
              Icon(Icons.groups_outlined, size: 48, color: Colors.grey.shade300),
              const SizedBox(height: 12),
              Text("No groups found for $_selectedFyp", style: TextStyle(color: Colors.grey.shade500)),
            ],
          ),
        ),
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _groupsList.length,
      itemBuilder: (context, i) {
        final g = _groupsList[i];
        // Support both camelCase and PascalCase keys from backend
        final groupName = (g['groupName'] ?? g['GroupName'] ?? g['title'] ?? 'Group ${g['id'] ?? ''}').toString();
        final supervisorName = (g['supervisor'] ?? g['supervisorName'] ?? g['SupervisorName'] ?? 'Not Assigned').toString();
        final status = (g['status'] ?? g['requestStatus'] ?? 'Pending').toString();
        final bool isActive = status.toLowerCase() == 'active';

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blueAccent.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.group_outlined, color: Colors.blueAccent, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(groupName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 2),
                    Text("Supervisor: $supervisorName",
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isActive ? Colors.green.shade50 : Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: isActive ? Colors.green : Colors.orange,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
