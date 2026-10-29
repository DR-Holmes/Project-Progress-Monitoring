import 'package:flutter/material.dart';
import '../../viewmodels/comitteeviewmodel/group_assignment_viewmodel.dart';

class GroupAssignmentView extends StatefulWidget {
  // 🏫 SCHOOL LESSON: We pass the selected student's data as a Map!
  final Map<String, dynamic> studentData;

  const GroupAssignmentView({super.key, required this.studentData});

  @override
  State<GroupAssignmentView> createState() => _GroupAssignmentViewState();
}

class _GroupAssignmentViewState extends State<GroupAssignmentView> {
  final GroupAssignmentViewModel _viewModel = GroupAssignmentViewModel();

  // 🏫 SCHOOL LESSON: We store the RAW groups from the API and the FILTERED ones for the UI!
  List<Map<String, dynamic>> _allGroupsRaw = [];
  List<Map<String, dynamic>> _filteredGroups = [];
  
  bool _isLoading = true;
  bool _isCreatingGroup = false;
  String _selectedFyp = 'FYP-1'; // Toggle state for groups list

  @override
  void initState() {
    super.initState();
    // 🏫 SCHOOL LESSON: Default the toggle to the student's fyp type if available
    _selectedFyp = widget.studentData['fypType'] ?? 'FYP-1';
    _loadGroupsFromApi();
  }

  // 🏫 SCHOOL LESSON: Load groups from the C# API: /committee-meetings/EligibleGroups/{regNum}
  Future<void> _loadGroupsFromApi() async {
    setState(() => _isLoading = true);
    
    // 1. Fetch the data from our ViewModel
    final data = await _viewModel.fetchEligibleGroups(widget.studentData['regNum']);
    
    if (mounted) {
      setState(() {
        // 2. Save the raw list so we don't have to keep calling the API when toggling
        _allGroupsRaw = data;
        
        // 3. Apply the initial filter
        _applyLocalFilter();
        
        _isLoading = false;
      });
    }
  }

  // 🏫 SCHOOL LESSON: This function filters the RAW groups by the Toggle (FYP-1 or FYP-2)
  void _applyLocalFilter() {
    setState(() {
      // We look at the 'type' or 'fypType' field from the C# JSON response
      _filteredGroups = _allGroupsRaw.where((g) {
        // 🏫 Check both 'type' and 'fypType' because C# naming can vary!
        final gType = g['type'] ?? g['fypType'] ?? 'FYP-1';
        return gType.toString().toUpperCase() == _selectedFyp.toUpperCase();
      }).toList();
    });
    
    debugPrint("🏫 Filtered Groups Count for $_selectedFyp: ${_filteredGroups.length}");
  }

  // 🏫 SCHOOL LESSON: Logic to add student to an existing group!
  void _handleAssign(int groupId) async {
    // 🛡️ SECURITY CHECK: Ensure student is assigned to their correct FYP type group!
    String studentFyp = widget.studentData['fypType'] ?? 'FYP-1';
    if (_selectedFyp != studentFyp) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: This student is enrolled in $studentFyp. You cannot add them to an $_selectedFyp group.")),
      );
      return;
    }

    setState(() => _isLoading = true);
    bool success = await _viewModel.addStudentToGroup(groupId, widget.studentData['regNum']);
    
    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Student added to group successfully!")),
        );
        Navigator.pop(context, true); // Go back with 'true' to trigger refresh
      } else {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to assign student.")),
        );
      }
    }
  }

  // 🏫 SCHOOL LESSON: Logic to create a NEW group with this student as Admin!
  void _handleCreateGroup() async {
    setState(() => _isLoading = true);
    
    // Use sessionId from student data or default to current
    int sessionId = widget.studentData['sessionId'] ?? 1; 

    bool success = await _viewModel.createGroup(widget.studentData['regNum'], sessionId);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("New group created successfully!")),
        );
        Navigator.pop(context, true); // Go back and refresh
      } else {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to create group.")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Assign to Group", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Student Info Card ---
                  _buildStudentInfo(),

                  const SizedBox(height: 24),
                  
                  // --- FYP Toggle Row ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Eligible Groups", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      _buildMiniFypToggle(),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // --- List of Eligible Groups ---
                  if (_filteredGroups.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Text("No eligible $_selectedFyp groups available for this technology.", 
                          style: const TextStyle(color: Colors.grey, fontSize: 14)),
                    )
                  else
                    ..._filteredGroups.map((group) => _buildGroupCard(group)),

                  const Divider(height: 40),

                  // --- Create Group Section ---
                  _buildCreateGroupSection(),
                ],
              ),
            ),
    );
  }

  Widget _buildStudentInfo() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withOpacity(0.1)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Selected Student", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 12)),
          const SizedBox(height: 8),
          Text(widget.studentData['name'] ?? "Unknown", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          Text("Registration: ${widget.studentData['regNum']}", style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(4)),
            child: Text("Technology: ${widget.studentData['technology'] ?? 'N/A'}", 
                style: const TextStyle(color: Colors.blue, fontSize: 12, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupCard(Map<String, dynamic> group) {
    List members = group['members'] ?? [];
    String membersNames = members.isEmpty ? "No members" : members.map((m) => m['name']).join(", ");

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Group ${group['id']}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.people_outline, size: 14, color: Colors.grey),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(membersNames, 
                          style: TextStyle(color: Colors.grey[600], fontSize: 12, overflow: TextOverflow.ellipsis)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => _handleAssign(group['id']),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text("Add", style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniFypToggle() {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: ['FYP-1', 'FYP-2'].map((fyp) {
          bool isSel = _selectedFyp == fyp;
          return GestureDetector(
            onTap: () {
              setState(() => _selectedFyp = fyp);
              _applyLocalFilter(); // 🏫 Filter the groups locally
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isSel ? Colors.blue : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(fyp,
                  style: TextStyle(
                      color: isSel ? Colors.white : Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 11)),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCreateGroupSection() {
    if (!_isCreatingGroup) {
      return Center(
        child: OutlinedButton.icon(
          onPressed: () => setState(() => _isCreatingGroup = true),
          icon: const Icon(Icons.add_circle_outline, size: 18),
          label: const Text("Create New Group"),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            side: const BorderSide(color: Colors.blue),
            foregroundColor: Colors.blue,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Create New Group", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          const Text("This will create a new project group and assign this student as the first member and Admin.", 
              style: TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => setState(() => _isCreatingGroup = false),
                child: const Text("Cancel"),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _handleCreateGroup,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child: const Text("Create"),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
