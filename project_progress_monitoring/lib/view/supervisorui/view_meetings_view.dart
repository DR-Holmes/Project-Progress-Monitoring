import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../viewmodels/supervisorviewmodel/view_meetings_viewmodel.dart';
import 'schedule_meeting_view.dart';
import 'assign_task_view.dart'; // Assume this exists
import 'edit_meeting_view.dart';
import 'supervisor_meeting_details_view.dart';

// --- VIEW ---
// PRIMARY SCHOOLER NOTE: This screen shows the supervisor all their meetings.
// It is a StatefulWidget because we can search and switch between FYP types!
class ViewMeetingsView extends StatefulWidget {
  final Map<String, dynamic> userMap;

  const ViewMeetingsView({super.key, required this.userMap});

  @override
  State<ViewMeetingsView> createState() => _ViewMeetingsViewState();
}

class _ViewMeetingsViewState extends State<ViewMeetingsView> {
  // Connecting to our Brain (ViewModel)
  final ViewMeetingsViewModel _viewModel = ViewMeetingsViewModel();

  // Variables to keep track of our state
  String _activeFYP = "FYP-1";
  String _searchTerm = "";
  List<Map<String, dynamic>> _allMeetings = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // As soon as the screen opens, we go get the data!
    _loadData();
  }

  /// ──────────────────────────────────────────────────────────────────────────
  /// WHAT IT DOES: Asks the Brain (ViewModel) to get the meetings list.
  /// ──────────────────────────────────────────────────────────────────────────
  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    String supervisorId = widget.userMap['id'].toString();
    final data = await _viewModel.fetchMeetings(supervisorId, _activeFYP);
    
    if (mounted) {
      setState(() {
        _allMeetings = data;
        _isLoading = false;
      });
    }
  }

  /// ──────────────────────────────────────────────────────────────────────────
  /// WHAT IT DOES: Filters the list based on what the user types in the search bar.
  /// ──────────────────────────────────────────────────────────────────────────
  List<Map<String, dynamic>> _getFilteredMeetings() {
    if (_searchTerm.isEmpty) return _allMeetings;
    
    return _allMeetings.where((m) {
      String groupId = (m['GroupId'] ?? "").toString().toLowerCase();
      String memberName = (m['memberName'] ?? "").toString().toLowerCase();
      String term = _searchTerm.toLowerCase();
      return groupId.contains(term) || memberName.contains(term);
    }).toList();
  }

  /// ──────────────────────────────────────────────────────────────────────────
  /// WHAT IT DOES: Groups meetings into Today, Upcoming, and Past.
  /// ──────────────────────────────────────────────────────────────────────────
  Map<String, List<Map<String, dynamic>>> _categorizeMeetings(List<Map<String, dynamic>> list) {
    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);

    List<Map<String, dynamic>> todayList = [];
    List<Map<String, dynamic>> upcomingList = [];
    List<Map<String, dynamic>> pastList = [];

    for (var m in list) {
      try {
        // We try to turn the date string into a real Date object
        DateTime dt = DateTime.parse(m['Date'] ?? m['date']);
        DateTime meetingDate = DateTime(dt.year, dt.month, dt.day);

        if (meetingDate.isAtSameMomentAs(today)) {
          todayList.add(m);
        } else if (meetingDate.isAfter(today)) {
          upcomingList.add(m);
        } else {
          pastList.add(m);
        }
      } catch (e) {
        // If the date is weird, we put it in "Past" just in case.
        pastList.add(m);
      }
    }

    return {
      "Today": todayList,
      "Upcoming": upcomingList,
      "Past": pastList,
    };
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _getFilteredMeetings();
    final categorized = _categorizeMeetings(filtered);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Supervisor Meetings", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        foregroundColor: Colors.black,
        actions: [
          // Back to Dashboard button like in React
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Back", style: TextStyle(color: Colors.blue)),
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. Controls Section (Toggle + Search)
          _buildControls(),

          // 2. Main List Section
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _loadData,
                    child: filtered.isEmpty 
                        ? _buildEmptyState() 
                        : ListView(
                            padding: const EdgeInsets.all(16),
                            children: [
                              _buildSection("📅 Today's Meetings", categorized['Today']!),
                              _buildSection("⏳ Upcoming Meetings", categorized['Upcoming']!),
                              _buildSection("📁 Past Meetings", categorized['Past']!),
                            ],
                          ),
                  ),
          ),
        ],
      ),
      // Floating button to schedule a new meeting
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (c) => ScheduleMeetingView(userMap: widget.userMap))),
        backgroundColor: Colors.blueAccent,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  // Helper for Toggle and Search Bar
  Widget _buildControls() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[50],
      child: Column(
        children: [
          // FYP Switcher
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: ["FYP-1", "FYP-2"].map((type) {
                bool isActive = _activeFYP == type;
                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() => _activeFYP = type);
                      _loadData();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: isActive ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: isActive ? [const BoxShadow(color: Colors.black12, blurRadius: 2)] : [],
                      ),
                      child: Center(child: Text(type, style: TextStyle(fontWeight: FontWeight.bold, color: isActive ? Colors.blueAccent : Colors.grey))),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),
          // Search Box
          TextField(
            onChanged: (val) => setState(() => _searchTerm = val),
            decoration: InputDecoration(
              hintText: "Search by Group or Member...",
              prefixIcon: const Icon(Icons.search, size: 20),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
            ),
          ),
        ],
      ),
    );
  }

  // Helper for Section Titles and Lists
  Widget _buildSection(String title, List<Map<String, dynamic>> list) {
    if (list.isEmpty) return const SizedBox.shrink();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
        ...list.map((m) => _buildMeetingCard(m)),
        const SizedBox(height: 10),
      ],
    );
  }

  // The Card Widget for each meeting
  Widget _buildMeetingCard(Map<String, dynamic> m) {
    String status = m['Status'] ?? m['status'] ?? "Pending";
    bool isCompleted = status.toLowerCase() == "completed";

    // Format Date/Time for display
    String displayDateTime = "TBD";
    try {
      DateTime dt = DateTime.parse(m['Date'] ?? m['date']);
      displayDateTime = DateFormat('MMM dd, hh:mm a').format(dt);
    } catch (_) {}

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      m['memberId'] != null 
                        ? "Individual — ${m['memberName'] ?? m['memberId']}"
                        : "Group Meeting — Group ${m['GroupId'] ?? m['groupId']}",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.blueAccent),
                    ),
                    const SizedBox(height: 4),
                    Text(m['Title'] ?? m['title'] ?? "No Title", style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
                    child: Text(displayDateTime, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
                  ),
                  const SizedBox(height: 6),
                  Text(status.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isCompleted ? Colors.green : Colors.blue)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(m['Description'] ?? m['description'] ?? "No description provided.", 
            style: TextStyle(color: Colors.grey[600], fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 16),
          // Action Buttons
          Row(
            children: [
              _actionBtn("Details", Icons.visibility_outlined, Colors.grey, () {
                Navigator.push(context, MaterialPageRoute(builder: (c) => SupervisorMeetingDetailsView(
                  meeting: m,
                  userMap: widget.userMap,
                )));
              }),
              const SizedBox(width: 8),
              _actionBtn("Assign Task", Icons.add_task, Colors.blueAccent, () {
                Navigator.push(context, MaterialPageRoute(builder: (c) => AssignTaskView(
                  userMap: widget.userMap, 
                  initialGroupId: m['GroupId'] ?? m['groupId'],
                  initialMeetingId: m['Id'] ?? m['id'], // NEW: Pass the meeting too!
                )));
              }, isPrimary: true),
              const SizedBox(width: 8),
              _actionBtn("Edit", Icons.edit_outlined, Colors.grey, () {
                Navigator.push(context, MaterialPageRoute(builder: (c) => EditMeetingView(meeting: m)));
              }),
            ],
          ),
        ],
      ),
    );
  }

  // Helper for small action buttons
  Widget _actionBtn(String label, IconData icon, Color color, VoidCallback onTap, {bool isPrimary = false}) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isPrimary ? color : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isPrimary ? Colors.transparent : Colors.grey.shade300),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: isPrimary ? Colors.white : Colors.grey[700]),
              const SizedBox(width: 4),
              Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isPrimary ? Colors.white : Colors.grey[700])),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_busy_outlined, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text("No $_activeFYP meetings found.", style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
} // End of _ViewMeetingsViewState