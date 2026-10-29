import 'package:flutter/material.dart';
import '../../viewmodels/supervisorviewmodel/attendance_progress_viewmodel.dart';

class AttendanceProgressView extends StatefulWidget {
  final Map<String, dynamic> userMap;

  const AttendanceProgressView({super.key, required this.userMap});

  @override
  State<AttendanceProgressView> createState() => _AttendanceProgressViewState();
}

class _AttendanceProgressViewState extends State<AttendanceProgressView> {
  final AttendanceProgressViewModel _viewModel = AttendanceProgressViewModel();
  
  // 🏫 SCHOOL LESSON: We use a simple variable to track which FYP we are looking at!
  String _selectedFYP = "FYP-1";

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // 🏫 SCHOOL LESSON: This function calls the ViewModel to get data from the Internet!
  Future<void> _loadData() async {
    await _viewModel.loadAttendanceData(
      widget.userMap['id'].toString(), 
      _selectedFYP
    );
    // 🏫 SCHOOL LESSON: setState tells the phone "Hey! Something changed, redraw the screen!"
    if (mounted) setState(() {});
  }

  void _switchFYP(String fyp) {
    if (_selectedFYP == fyp) return;
    setState(() {
      _selectedFYP = fyp;
    });
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("Attendance ($_selectedFYP)", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // FYP Tabs (Like the React Code)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _tabButton("FYP-1"),
                const SizedBox(width: 8),
                _tabButton("FYP-2"),
              ],
            ),
          ),

          Expanded(
            child: _viewModel.isLoading
                ? const Center(child: CircularProgressIndicator())
                : _viewModel.groups.isEmpty
                    ? const Center(child: Text("No groups found.", style: TextStyle(color: Colors.grey)))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _viewModel.groups.length,
                        itemBuilder: (context, index) {
                          final group = _viewModel.groups[index];
                          return _buildGroupCard(group);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  // 🏫 SCHOOL LESSON: A helper function to create those nice FYP-1/2 buttons!
  Widget _tabButton(String label) {
    bool isActive = _selectedFYP == label;
    return Expanded(
      child: GestureDetector(
        onTap: () => _switchFYP(label),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? Colors.blue : Colors.white,
            border: Border.all(color: isActive ? Colors.blue : Colors.grey.shade200),
            borderRadius: BorderRadius.circular(20),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: isActive ? Colors.white : Colors.black87,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  // 🏫 SCHOOL LESSON: This widget builds the box for each group!
  Widget _buildGroupCard(Map<String, dynamic> group) {
    List<dynamic> members = group['members'] ?? [];

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Group ${group['groupName']}", 
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
          const SizedBox(height: 4),
          Text(group['projectTitle'] ?? "No Project Title", 
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          const Divider(height: 24),
          
          // List each member
          ...members.map((m) => _buildMemberRow(m)),
        ],
      ),
    );
  }

  // 🏫 SCHOOL LESSON: This widget shows each student and their progress bar!
  Widget _buildMemberRow(Map<String, dynamic> m) {
    int percentage = m['attendancePercentage'] ?? 0;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(m['studentName'] ?? "Unknown", 
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text("Reg: ${m['studentRegNum']} | CGPA: ${m['Cgpa']}", 
                      style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
                ],
              ),
            ),
            
            // Percentage and Progress Bar
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text("$percentage%", 
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                const SizedBox(height: 4),
                Container(
                  width: 80,
                  height: 6,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      width: 80 * (percentage / 100),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
