import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../viewmodels/comitteeviewmodel/committee_my_meetings_view_model.dart';
import 'committee_meeting_queue_view.dart';

// --- VIEW ---
// PRIMARY SCHOOLER NOTE: This screen shows the committee member all the meetings they need to attend.
// It is a StatefulWidget because the list of meetings can change!
class CommitteeMyMeetingsView extends StatefulWidget {
  final List<Map<String, dynamic>> userData;
  const CommitteeMyMeetingsView({super.key, required this.userData});

  @override
  State<CommitteeMyMeetingsView> createState() => _CommitteeMyMeetingsViewState();
}

class _CommitteeMyMeetingsViewState extends State<CommitteeMyMeetingsView> {
  // Connecting to our Brain (ViewModel)
  final CommitteeMyMeetingsViewModel _viewModel = CommitteeMyMeetingsViewModel();

  // Variables to keep track of our state
  String _activeFYP = "FYP-1";
  List<Map<String, dynamic>> _meetings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // As soon as the screen opens, we go get the data!
    _loadMeetings();
  }

  /// ──────────────────────────────────────────────────────────────────────────
  /// WHAT IT DOES: Asks the ViewModel to get the meetings list.
  /// HOW IT WORKS: It uses the User ID and the selected FYP Type.
  /// ──────────────────────────────────────────────────────────────────────────
  Future<void> _loadMeetings() async {
    setState(() => _isLoading = true);
    
    // We get the ID of the person logged in.
    String userId = widget.userData[0]['id'].toString();
    
    // We fetch the data.
    final data = await _viewModel.fetchMyMeetings(userId, _activeFYP);
    
    if (mounted) {
      setState(() {
        _meetings = data;
        _isLoading = false;
      });
    }
  }

  /// ──────────────────────────────────────────────────────────────────────────
  /// WHAT IT DOES: Changes the FYP type and reloads the list.
  /// ──────────────────────────────────────────────────────────────────────────
  void _switchFYP(String type) {
    if (_activeFYP == type) return;
    setState(() => _activeFYP = type);
    _loadMeetings();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("My Scheduled Meetings", 
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: Column(
        children: [
          // 1. FYP Switcher (Toggle)
          _buildToggle(),
          
          // 2. The Main List Section
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _loadMeetings,
                    child: _meetings.isEmpty 
                        ? _buildEmptyState() 
                        : _buildMeetingsList(),
                  ),
          ),
        ],
      ),
    );
  }

  // Helper for the FYP-1 / FYP-2 Toggle
  Widget _buildToggle() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: ["FYP-1", "FYP-2"].map((type) {
            bool isActive = _activeFYP == type;
            return Expanded(
              child: GestureDetector(
                onTap: () => _switchFYP(type),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: isActive ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: isActive 
                        ? [const BoxShadow(color: Colors.black12, blurRadius: 4)] 
                        : [],
                  ),
                  child: Center(
                    child: Text(
                      type,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isActive ? Colors.blueAccent : Colors.grey,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // Helper for when no meetings are found
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.calendar_today_outlined, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text("No Meetings Found", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text("You haven't scheduled any $_activeFYP meetings yet.", 
            style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  // Helper to build the list of cards
  Widget _buildMeetingsList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _meetings.length,
      itemBuilder: (context, index) {
        final m = _meetings[index];
        return _buildMeetingCard(m);
      },
    );
  }

  // The Card Widget for each meeting
  Widget _buildMeetingCard(Map<String, dynamic> m) {
    String status = m['Status'] ?? "Incoming";
    Color statusColor = Colors.blue;
    IconData statusIcon = Icons.access_time;

    // We change colors based on the status (Ongoing, Past, Incoming)
    if (status == "Ongoing") {
      statusColor = Colors.green;
      statusIcon = Icons.play_circle_outline;
    } else if (status == "Past") {
      statusColor = Colors.grey;
      statusIcon = Icons.check_circle_outline;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Status Badge and ID
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(statusIcon, size: 14, color: statusColor),
                    const SizedBox(width: 6),
                    Text(status, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12)),
                  ],
                ),
              ),
              Text("ID: #${m['MeetingId']}", style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 16),

          // Row 2: Title and Description
          Text(m['MeetingTitle'] ?? "Untitled Evaluation", 
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 6),
          Text(m['Description'] ?? "No description provided.", 
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
            maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 20),

          // Row 3: Details Box (Date, Location, Groups)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _detailRow(Icons.calendar_month_outlined, 
                  m['Date'] != null 
                    ? DateFormat('MMM dd, yyyy').format(DateTime.parse(m['Date'])) 
                    : "TBD"),
                const SizedBox(height: 10),
                _detailRow(Icons.map_outlined, m['Venue'] ?? "TBD"),
                const SizedBox(height: 10),
                _detailRow(Icons.groups_outlined, "${m['GroupCount'] ?? 0} Groups Assigned"),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Row 4: Action Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () {
                // PRIMARY SCHOOLER NOTE: This takes you to the Queue screen!
                Navigator.push(context, MaterialPageRoute(
                  builder: (context) => CommitteeMeetingQueueView(userData: widget.userData)
                ));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Manage Queue", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  SizedBox(width: 8),
                  Icon(Icons.chevron_right, color: Colors.white, size: 18),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Simple helper for detail rows
  Widget _detailRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 10),
        Text(text, style: TextStyle(color: Colors.grey[800], fontSize: 13, fontWeight: FontWeight.w500)),
      ],
    );
  }
} // End of _CommitteeMyMeetingsViewState
