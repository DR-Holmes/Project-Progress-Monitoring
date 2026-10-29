import 'package:flutter/material.dart';
import '../../viewmodels/supervisorviewmodel/supervisor_meeting_details_viewmodel.dart';

// --- VIEW ---
// PRIMARY SCHOOLER NOTE: This screen shows exactly what happened in one meeting.
// Supervisors can mark attendance, save group remarks, and student remarks.
class SupervisorMeetingDetailsView extends StatefulWidget {
  final Map<String, dynamic> meeting;
  final Map<String, dynamic> userMap;

  const SupervisorMeetingDetailsView({
    super.key,
    required this.meeting,
    required this.userMap,
  });

  @override
  State<SupervisorMeetingDetailsView> createState() => _SupervisorMeetingDetailsViewState();
}

class _SupervisorMeetingDetailsViewState extends State<SupervisorMeetingDetailsView> {
  final SupervisorMeetingDetailsViewModel _viewModel = SupervisorMeetingDetailsViewModel();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    String meetingId = widget.meeting['Id']?.toString() ?? widget.meeting['id']?.toString() ?? "";
    String supervisorId = widget.userMap['id']?.toString() ?? "";
    
    await _viewModel.loadAllData(meetingId, supervisorId);
    
    if (mounted) setState(() {});
  }

  // --- SAVE ACTIONS ---

  void _onSaveAttendance() async {
    String meetingId = widget.meeting['Id']?.toString() ?? widget.meeting['id']?.toString() ?? "";
    bool success = await _viewModel.saveAttendance(meetingId);
    
    if (mounted) {
      _showMsg(success ? "Attendance saved successfully" : "Failed to save attendance");
    }
  }

  void _onSaveGroupRemark() async {
    String meetingId = widget.meeting['Id']?.toString() ?? widget.meeting['id']?.toString() ?? "";
    String supervisorId = widget.userMap['id']?.toString() ?? "";
    
    bool success = await _viewModel.saveGroupRemark(meetingId, supervisorId);
    
    if (mounted) {
      _showMsg(success ? "Group remark saved" : "Failed to save group remark");
    }
  }

  void _onSaveStudentRemark(String studentId, String enrollId) async {
    String meetingId = widget.meeting['Id']?.toString() ?? widget.meeting['id']?.toString() ?? "";
    String supervisorId = widget.userMap['id']?.toString() ?? "";
    
    bool success = await _viewModel.saveStudentRemark(meetingId, supervisorId, studentId, enrollId);
    
    if (mounted) {
      _showMsg(success ? "Student remark saved" : "Failed to save student remark");
    }
  }

  void _showMsg(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Meeting Details", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        foregroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _viewModel.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. MEETING INFO BOX
                  if (_viewModel.meeting != null) _buildMeetingInfo(),
                  
                  const SizedBox(height: 16),
                  
                  // 2. GROUP REMARK BOX
                  if (_viewModel.meeting != null) _buildGroupRemark(),

                  const SizedBox(height: 16),

                  // 3. STUDENTS & ATTENDANCE BOX
                  if (_viewModel.group != null) _buildAttendanceList(),

                  const SizedBox(height: 16),

                  // 4. TASKS LIST
                  _buildTasksList(),
                  
                  const SizedBox(height: 32),
                  
                  // 5. BULK SAVE ATTENDANCE BUTTON
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _onSaveAttendance,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text("Save Attendance", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildMeetingInfo() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_viewModel.meeting!['title'] ?? _viewModel.meeting!['Title'] ?? 'No Title', 
               style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 4),
          Text(_viewModel.meeting!['date'] ?? _viewModel.meeting!['Date'] ?? 'No Date', 
               style: const TextStyle(fontSize: 13, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildGroupRemark() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Group Remark", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 8),
          TextField(
            maxLines: 3,
            decoration: InputDecoration(
              hintText: "Enter group remark...",
              filled: true,
              fillColor: Colors.grey.shade50,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
            ),
            onChanged: (val) => _viewModel.groupRemark = val,
            // Pre-fill if we fetched an existing remark
            controller: TextEditingController.fromValue(TextEditingValue(
              text: _viewModel.groupRemark,
              selection: TextSelection.collapsed(offset: _viewModel.groupRemark.length),
            )),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: _onSaveGroupRemark,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
              child: const Text("Save Group Remark", style: TextStyle(fontSize: 12)),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildAttendanceList() {
    List<dynamic> members = _viewModel.group!['Members'] ?? [];
    String groupName = _viewModel.group!['groupName'] ?? "Group";

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(groupName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          const Text("Mark Attendance & Remarks", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          const SizedBox(height: 12),
          
          ...members.map((m) {
            String studentId = m['id']?.toString() ?? "";
            String enrollId = m['EnrollmentID']?.toString() ?? m['enrollmentID']?.toString() ?? "";
            bool isPresent = _viewModel.attendance[studentId] ?? false;
            
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(m['name'] ?? m['studentName'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          Text(m['regNum'] ?? 'No Reg', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                      Checkbox(
                        value: isPresent,
                        activeColor: Colors.blue,
                        onChanged: (val) {
                          setState(() {
                            _viewModel.attendance[studentId] = val ?? false;
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    decoration: InputDecoration(
                      hintText: "Enter remark...",
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                    ),
                    onChanged: (val) => _viewModel.studentRemarks[studentId] = val,
                    controller: TextEditingController.fromValue(TextEditingValue(
                      text: _viewModel.studentRemarks[studentId] ?? "",
                      selection: TextSelection.collapsed(offset: (_viewModel.studentRemarks[studentId] ?? "").length),
                    )),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: OutlinedButton(
                      onPressed: () => _onSaveStudentRemark(studentId, enrollId),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                        minimumSize: const Size(0, 32),
                      ),
                      child: const Text("Save Remark", style: TextStyle(fontSize: 12, color: Colors.blue)),
                    ),
                  )
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTasksList() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Assigned Tasks (${_viewModel.tasks.length})", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 8),
          if (_viewModel.tasks.isEmpty)
            const Text("No tasks assigned.", style: TextStyle(fontSize: 13, color: Colors.grey)),
          ..._viewModel.tasks.map((t) {
            String title = t['title'] ?? t['Title'] ?? 'Untitled';
            String assignedType = t['AssignedType'] ?? t['assignedType'] ?? '';
            String name = t['name'] ?? t['Name'] ?? '';
            
            return Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(8)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 4),
                  Text("Assigned To: $assignedType-$name", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
