import 'package:flutter/material.dart';
import '../../viewmodels/comitteeviewmodel/approved_groups_view_model.dart';
import 'group_detail_view.dart';

class ApprovedGroupsView extends StatefulWidget {
  final String activeFyp; // 🏫 SCHOOL LESSON: We pass the FYP type from the previous screen!

  const ApprovedGroupsView({super.key, required this.activeFyp});

  @override
  State<ApprovedGroupsView> createState() => _ApprovedGroupsViewState();
}

class _ApprovedGroupsViewState extends State<ApprovedGroupsView> {
  final ApprovedGroupsViewModel _viewModel = ApprovedGroupsViewModel();
  
  String _selectedFyp = 'FYP-1';
  String _searchQuery = "";
  List<Map<String, dynamic>> _allGroups = [];

  @override
  void initState() {
    super.initState();
    _selectedFyp = widget.activeFyp;
    _loadGroups();
  }

  // 🏫 SCHOOL LESSON: Fetch groups from the ViewModel!
  Future<void> _loadGroups() async {
    final data = await _viewModel.fetchApprovedGroups(_selectedFyp);
    if (mounted) {
      setState(() {
        _allGroups = data;
      });
    }
  }

  // 🏫 SCHOOL LESSON: This function filters the list based on project title or group name!
  List<Map<String, dynamic>> get _filteredGroups {
    return _allGroups.where((g) {
      final title = (g['projectTitle'] ?? "").toString().toLowerCase();
      final groupName = "Group ${g['groupName'] ?? ""}".toLowerCase();
      final search = _searchQuery.toLowerCase();
      
      return title.contains(search) || groupName.contains(search);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Approved Groups", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
          // --- FYP Toggle ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: ['FYP-1', 'FYP-2'].map((fyp) {
                bool isSel = _selectedFyp == fyp;
                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() => _selectedFyp = fyp);
                      _loadGroups();
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: isSel ? Colors.blueAccent : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: isSel ? Colors.blueAccent : Colors.grey.shade200),
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
          ),
          
          // --- Search Bar ---
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: "Search groups or projects...",
                prefixIcon: const Icon(Icons.search, size: 20),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),

          // --- Groups List ---
          Expanded(
            child: _viewModel.isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredGroups.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _filteredGroups.length,
                        itemBuilder: (context, index) {
                          final group = _filteredGroups[index];
                          return _buildGroupCard(group);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupCard(Map<String, dynamic> group) {
    // 🏫 SCHOOL LESSON: Extracting data from the Map!
    final String groupName = "Group ${group['groupName'] ?? ""}";
    final String title = group['projectTitle'] ?? "No Project Assigned";
    final String supervisor = group['supervisor'] ?? "Not Assigned";
    final List members = group['members'] ?? [];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(groupName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blue)),
              const Icon(Icons.check_circle, color: Colors.green, size: 18),
            ],
          ),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 4),
          Text("Supervisor: $supervisor", style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          const Divider(height: 24),
          const Text("Members:", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            children: members.map((m) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(4)),
              child: Text(m.toString(), style: const TextStyle(color: Colors.blue, fontSize: 10, fontWeight: FontWeight.w500)),
            )).toList(),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                // 🏫 SCHOOL LESSON: Navigate to Group Details!
                final groupId = int.tryParse(group['groupName'].toString()) ?? 0;
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (c) => GroupDetailView(groupId: groupId)),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[50],
                foregroundColor: Colors.blue,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text("View Details", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.group_off_outlined, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text("No approved groups found.", style: TextStyle(color: Colors.grey[500])),
        ],
      ),
    );
  }
}
