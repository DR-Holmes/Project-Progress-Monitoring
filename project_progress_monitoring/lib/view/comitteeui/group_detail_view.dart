import 'package:flutter/material.dart';
import '../../viewmodels/comitteeviewmodel/group_detail_view_model.dart';

class GroupDetailView extends StatefulWidget {
  final int groupId;

  const GroupDetailView({super.key, required this.groupId});

  @override
  State<GroupDetailView> createState() => _GroupDetailViewState();
}

class _GroupDetailViewState extends State<GroupDetailView> {
  final GroupDetailViewModel _viewModel = GroupDetailViewModel();
  bool _isEditing = false;
  String _studentSearch = "";
  Map<String, dynamic>? _selectedStudent;

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  Future<void> _refreshData() async {
    await _viewModel.fetchGroupDetails(widget.groupId);
    await _viewModel.fetchEligibleStudents(widget.groupId);
    await _viewModel.fetchTechnologies();
    if (mounted) setState(() {});
  }

  Color _getProgressColor(int value) {
    if (value >= 70) return Colors.green;
    if (value >= 40) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final group = _viewModel.groupData;
    final members = (group['members'] as List?) ?? [];

    return Scaffold(
      backgroundColor: Colors.grey[50],
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
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Header Card ---
                  _buildHeader(group),
                  const SizedBox(height: 20),

                  // --- Members List ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Team Members", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(12)),
                        child: Text("${members.length} members", style: const TextStyle(color: Colors.blue, fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...members.asMap().entries.map((entry) => _buildMemberCard(entry.value, entry.key)).toList(),

                  // --- Add Member Section (Visible when Editing) ---
                  if (_isEditing) _buildAddMemberSection(),

                  const SizedBox(height: 24),
                  if (_isEditing)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _handleSaveChanges,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text("Save Changes", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader(Map<String, dynamic> group) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Colors.blueAccent, Colors.blue]),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Group ${group['groupName'] ?? ""}", style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              TextButton(
                onPressed: () => setState(() => _isEditing = !_isEditing),
                style: TextButton.styleFrom(backgroundColor: Colors.white.withOpacity(0.2), foregroundColor: Colors.white),
                child: Text(_isEditing ? "Cancel" : "Edit Members", style: const TextStyle(fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(group['projectTitle'] ?? "No Project", style: const TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 4),
          Text(group['supervisor'] ?? "No Supervisor", style: const TextStyle(color: Colors.white70, fontSize: 13, fontStyle: FontStyle.italic)),
        ],
      ),
    );
  }

  Widget _buildMemberCard(Map<String, dynamic> m, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: Colors.blue[50],
                child: Text(m['studentName']?.substring(0, 1) ?? "?", style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(m['studentName'] ?? "", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 4),
                    _buildInfoRow(Icons.email_outlined, m['Email'] ?? ""),
                    _buildInfoRow(Icons.school_outlined, "${m['DepartmentName']} - ${m['studentSection']}"),
                    _buildInfoRow(Icons.person_outline, m['Gender'] ?? ""),
                    
                    // Technology Selector or Display
                    const SizedBox(height: 6),
                    _isEditing 
                      ? _buildTechDropdown(m, index)
                      : _buildInfoRow(Icons.code, m['TechnologyName'] ?? ""),
                  ],
                ),
              ),
              if (_isEditing)
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => _handleRemoveMember(m['RegNum']),
                ),
            ],
          ),
          const Divider(height: 24),
          // Progress Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Progress", style: TextStyle(fontSize: 11, color: Colors.grey)),
              Text("${m['progress']}%", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: (m['progress'] ?? 0) / 100,
              backgroundColor: Colors.grey[200],
              color: _getProgressColor(m['progress'] ?? 0),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          Icon(icon, size: 12, color: Colors.grey),
          const SizedBox(width: 4),
          Expanded(child: Text(text, style: TextStyle(color: Colors.grey[600], fontSize: 11))),
        ],
      ),
    );
  }

  Widget _buildTechDropdown(Map<String, dynamic> member, int index) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: member['TechnologyId'],
          isDense: true,
          style: const TextStyle(fontSize: 11, color: Colors.black),
          items: _viewModel.allTechnologies.map((t) {
            return DropdownMenuItem<int>(
              value: t['id'],
              child: Text(t['name'] ?? ""),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) {
              setState(() {
                _viewModel.groupData['members'][index]['TechnologyId'] = val;
                _viewModel.groupData['members'][index]['TechnologyName'] = 
                  _viewModel.allTechnologies.firstWhere((t) => t['id'] == val)['name'];
              });
            }
          },
        ),
      ),
    );
  }

  Widget _buildAddMemberSection() {
    final filtered = _viewModel.eligibleStudents.where((s) {
      final query = _studentSearch.toLowerCase();
      return (s['name'] ?? "").toString().toLowerCase().contains(query) ||
             (s['regNum'] ?? "").toString().toLowerCase().contains(query);
    }).toList();

    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Add New Member", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 12),
          TextField(
            onChanged: (v) => setState(() => _studentSearch = v),
            decoration: InputDecoration(
              hintText: "Search students...",
              prefixIcon: const Icon(Icons.search, size: 18),
              filled: true,
              fillColor: Colors.grey[50],
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
              contentPadding: EdgeInsets.zero,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 150,
            decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade100), borderRadius: BorderRadius.circular(8)),
            child: ListView.builder(
              itemCount: filtered.length,
              itemBuilder: (c, i) {
                final s = filtered[i];
                bool isSel = _selectedStudent?['regNum'] == s['regNum'];
                return ListTile(
                  title: Text(s['name'] ?? "", style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                  subtitle: Text("${s['regNum']} • ${s['TechnologyName']}", style: const TextStyle(fontSize: 11)),
                  tileColor: isSel ? Colors.blue[50] : null,
                  onTap: () => setState(() => _selectedStudent = s),
                  dense: true,
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _selectedStudent == null ? null : _handleAddMember,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, foregroundColor: Colors.white),
              child: const Text("Add Selected Student"),
            ),
          ),
        ],
      ),
    );
  }

  // --- Actions ---

  void _handleRemoveMember(String regNum) async {
    bool ok = await _viewModel.removeMember(widget.groupId, regNum);
    if (ok) {
      _refreshData();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Member removed ❌")));
    }
  }

  void _handleAddMember() async {
    if (_selectedStudent == null) return;
    bool ok = await _viewModel.addStudentToGroup(widget.groupId, _selectedStudent!['regNum']);
    if (ok) {
      setState(() {
        _selectedStudent = null;
        _studentSearch = "";
      });
      _refreshData();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Member added ✅")));
    }
  }

  void _handleSaveChanges() async {
    final members = List<Map<String, dynamic>>.from(_viewModel.groupData['members']);
    bool ok = await _viewModel.saveTechnologies(widget.groupId, members);
    if (ok) {
      setState(() => _isEditing = false);
      _refreshData();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Technologies updated successfully ✅")));
    }
  }
}
