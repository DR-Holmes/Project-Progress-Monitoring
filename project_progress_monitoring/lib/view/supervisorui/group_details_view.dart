import 'package:flutter/material.dart';
import '../../viewmodels/supervisorviewmodel/group_details_viewmodel.dart';
import 'assign_task_view.dart';
import 'all_tasks_view.dart';

class GroupDetailsView extends StatefulWidget {
  final Map<String, dynamic> group;
  final Map<String, dynamic> userMap;
  final String fypType;

  const GroupDetailsView({
    super.key,
    required this.group,
    required this.userMap,
    required this.fypType,
  });

  @override
  State<GroupDetailsView> createState() => _GroupDetailsViewState();
}

class _GroupDetailsViewState extends State<GroupDetailsView> {
  final GroupDetailsViewModel _viewModel = GroupDetailsViewModel();

  bool _isEditing = false; // State for toggling edit mode
  final Map<String, dynamic> _newMember = {
    'studentName': '',
    'RegNum': '',
    'Cgpa': '',
    'Gender': '',
  };

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    // Try to find the ID - it might be 'groupName' or 'GroupId' or 'id'
    final dynamic rawId = widget.group['groupName'] ?? widget.group['GroupId'] ?? widget.group['id'];
    final int groupId = (rawId is int) ? rawId : int.tryParse(rawId.toString()) ?? 0;
    
    await _viewModel.fetchGroupDetails(groupId);
    if (mounted) setState(() {});
  }

  // Toggles the edit mode
  void _toggleEdit() {
    setState(() {
      _isEditing = !_isEditing;
    });
  }

  // Logic for adding a member (frontend only for now as per React sample)
  void _handleAddMember() {
    if (_newMember['studentName'].isEmpty || _newMember['RegNum'].isEmpty) return;
    
    setState(() {
      _viewModel.members.add(Map<String, dynamic>.from(_newMember));
      // Reset form
      _newMember['studentName'] = '';
      _newMember['RegNum'] = '';
      _newMember['Cgpa'] = '';
      _newMember['Gender'] = '';
      _isEditing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Group Details", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
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
                  // Header with Gradient and Edit Button
                  _buildPremiumHeader(),
                  const SizedBox(height: 20),

                  // Team Members Container
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey.shade200),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Team Members", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
                              child: Text("${_viewModel.members.length} members", style: const TextStyle(fontSize: 11, color: Colors.grey)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ..._viewModel.members.asMap().entries.map((entry) => _buildMemberCard(entry.value, entry.key)),
                        
                        // Add Member Form (Visible only in Edit Mode)
                        if (_isEditing) _buildAddMemberForm(),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Footer Actions
                  _buildFooterActions(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  Widget _buildPremiumHeader() {
    final String groupName = _viewModel.groupData?['groupName']?.toString() ?? "N/A";
    final String projectTitle = _viewModel.groupData?['projectTitle'] ?? "No Project Allocated";
    final String supervisor = _viewModel.groupData?['supervisor'] ?? "No Supervisor Assigned";

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade700, Colors.blue.shade500],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Group $groupName", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 4),
                Text(projectTitle, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w400)),
                Text(supervisor, style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: _toggleEdit,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.2),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
            ),
            child: Text(_isEditing ? "Cancel" : "Edit Members", style: const TextStyle(fontSize: 11)),
          ),
        ],
      ),
    );
  }

  Widget _buildAddMemberForm() {
    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.only(top: 20),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Add New Member", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 12),
          TextField(
            onChanged: (v) => _newMember['studentName'] = v,
            decoration: _inputDeco("Full Name"),
          ),
          const SizedBox(height: 10),
          TextField(
            onChanged: (v) => _newMember['RegNum'] = v,
            decoration: _inputDeco("Registration Number"),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: TextField(onChanged: (v) => _newMember['Cgpa'] = v, decoration: _inputDeco("CGPA"))),
              const SizedBox(width: 10),
              Expanded(child: TextField(onChanged: (v) => _newMember['Gender'] = v, decoration: _inputDeco("Gender"))),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _handleAddMember,
              icon: const Icon(Icons.person_add_alt_1, size: 18),
              label: const Text("Add Member"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey.shade100,
                foregroundColor: Colors.black87,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDeco(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      filled: true,
      fillColor: Colors.grey.shade50,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
    );
  }

  Widget _buildFooterActions() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: () {
          if (_isEditing) {
            _toggleEdit();
          } else {
            // Navigate to all tasks view
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AllTasksView(userMap: widget.userMap),
              ),
            );
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: Text(_isEditing ? "Save Changes" : "View All Tasks"),
      ),
    );
  }


  Widget _buildMemberCard(Map<String, dynamic> member, int index) {
    // Fetch individual progress for this member (calculated by backend)
    int progress = (member['progress'] ?? 0) as int;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Circular avatar
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  (member['studentName'] as String?)?.split(" ").map((n) => n[0]).join("").toUpperCase() ?? "S",
                  style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(member['studentName'] ?? "Student", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(4)),
                          child: const Text("Member", style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    _infoRow(Icons.mail_outline, member['Email'] ?? "No Email"),
                    _infoRow(Icons.badge_outlined, "${member['RegNum'] ?? 'N/A'} | CGPA ${member['Cgpa'] ?? 'N/A'}"),
                    _infoRow(Icons.business_outlined, "${member['DepartmentName'] ?? 'N/A'} (${member['studentSection'] ?? 'N/A'})"),
                    _infoRow(Icons.code, member['TechnologyName'] ?? "N/A"),
                    _infoRow(Icons.person_outline, member['Gender'] ?? "N/A"),
                  ],
                ),
              ),
              // Side buttons (Remarks/Assign) OR Delete
              if (_isEditing)
                IconButton(
                  onPressed: () {
                    setState(() {
                      _viewModel.members.removeAt(index);
                    });
                  },
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                )
              else
                Column(
                  children: [
                    _actionTextBtn("Remarks", Colors.blue, () {}),
                    const SizedBox(height: 8),
                    _actionTextBtn("Assign", Colors.blue, () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AssignTaskView(
                            userMap: widget.userMap,
                            initialGroupId: widget.group['GroupId'] ?? widget.group['id'],
                            initialFypType: widget.fypType,
                            initialStudentId: member['RegNum'], // Corrected parameter
                            initialStudentName: member['studentName'], // Pass name too
                          ),
                        ),
                      );
                    }),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 12),
          // Progress Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Progress", style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500)),
              Text("$progress%", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress / 100,
              minHeight: 4,
              backgroundColor: Colors.grey.shade100,
              color: _getProgColor(progress),
            ),
          ),
        ],
      ),
    );
  }

  // Small helper for info rows
  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          Icon(icon, size: 12, color: Colors.grey),
          const SizedBox(width: 6),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 11, color: Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }

  // Small helper for action buttons
  Widget _actionTextBtn(String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(border: Border.all(color: color.withOpacity(0.3)), borderRadius: BorderRadius.circular(8)),
        child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
      ),
    );
  }

  // Color helper based on progress percentage
  Color _getProgColor(int val) {
    if (val >= 70) return Colors.green;
    if (val >= 40) return Colors.orange;
    return Colors.red;
  }
}
