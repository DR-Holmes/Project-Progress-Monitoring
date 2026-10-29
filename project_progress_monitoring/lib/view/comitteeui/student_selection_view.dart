import 'package:flutter/material.dart';
import '../../viewmodels/comitteeviewmodel/student_selection_viewmodel.dart';
import 'group_assignment_view.dart';

class StudentSelectionView extends StatefulWidget {
  const StudentSelectionView({super.key});

  @override
  State<StudentSelectionView> createState() => _StudentSelectionViewState();
}

class _StudentSelectionViewState extends State<StudentSelectionView> {
  final StudentSelectionViewModel _viewModel = StudentSelectionViewModel();
  
  // 🏫 SCHOOL LESSON: Local variables for searching and filtering!
  String _searchQuery = "";
  String _fypType = "FYP-1"; // Subject Type
  bool _showUnassignedOnly = false;
  List<Map<String, dynamic>> _students = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // 🏫 SCHOOL LESSON: Fetch data from the backend using our ViewModel!
  Future<void> _loadData() async {
    final data = await _viewModel.fetchStudents(_fypType);
    if (mounted) {
      setState(() {
        _students = data;
      });
    }
  }

  // 🏫 SCHOOL LESSON: This function filters the list based on Search and the Toggle!
  List<Map<String, dynamic>> get _filteredStudents {
    return _students.where((s) {
      final matchesSearch = s['name'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
                          s['regNum'].toString().contains(_searchQuery);
      
      final matchesUnassigned = _showUnassignedOnly ? (s['group'] == 0) : true;
      
      return matchesSearch && matchesUnassigned;
    }).toList();
  }

  void _onStudentSelect(Map<String, dynamic> student) async {
    if (student['group'] == 0) {
      // 🏫 SCHOOL LESSON: Navigate to Group Assignment and wait for result!
      final bool? refresh = await Navigator.push(
        context, 
        MaterialPageRoute(builder: (c) => GroupAssignmentView(
          studentData: {
            ...student,
            'fypType': _fypType, // 🏫 Pass the current FYP type the user is viewing
          },
        ))
      );
      
      // If the user performed an action, refresh the list!
      if (refresh == true) {
        _loadData();
      }
    } else {
      // Show alert like in React code
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text("Already Assigned"),
          content: const Text("This student is already assigned to a group."),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("OK"))
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Student Selection", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
          // FYP Type Selector
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _fypTab("FYP-1"),
                const SizedBox(width: 8),
                _fypTab("FYP-2"),
              ],
            ),
          ),

          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: "Search by name or reg no...",
                prefixIcon: const Icon(Icons.search, size: 20),
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),

          // Filter Toggle Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("All Students", style: TextStyle(fontWeight: FontWeight.bold)),
                TextButton.icon(
                  onPressed: () => setState(() => _showUnassignedOnly = !_showUnassignedOnly),
                  icon: Icon(_showUnassignedOnly ? Icons.check_circle : Icons.circle_outlined, size: 18),
                  label: Text(_showUnassignedOnly ? "Unassigned Only" : "Show All", style: const TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(foregroundColor: _showUnassignedOnly ? Colors.blue : Colors.grey),
                ),
              ],
            ),
          ),

          // List Count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Text("${_filteredStudents.length} students", style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),

          // Student List
          Expanded(
            child: _viewModel.isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredStudents.length,
                    itemBuilder: (context, index) {
                      final student = _filteredStudents[index];
                      return _buildStudentCard(student);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _fypTab(String label) {
    bool active = _fypType == label;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _fypType = label);
          _loadData();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? Colors.blue : Colors.white,
            border: Border.all(color: active ? Colors.blue : Colors.grey.shade200),
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(label, style: TextStyle(color: active ? Colors.white : Colors.black87, fontWeight: FontWeight.bold, fontSize: 13)),
        ),
      ),
    );
  }

  Widget _buildStudentCard(Map<String, dynamic> student) {
    int groupNum = student['group'] ?? 0;
    String name = student['name'] ?? "Unknown";
    
    // 🏫 SCHOOL LESSON: Get Initials for the Avatar!
    String initials = name.split(' ').map((n) => n.isNotEmpty ? n[0] : "").join('').toUpperCase();
    if (initials.length > 2) initials = initials.substring(0, 2);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: Colors.blue.shade50, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Text(initials, style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 12)),
          ),
          const SizedBox(width: 12),
          
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Text("Reg: ${student['regNum']} | CGPA: ${student['cgpa']}", style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Text("Group: ", style: TextStyle(fontSize: 11, color: Colors.grey)),
                    Text(groupNum == 0 ? "Unassigned" : "$groupNum", 
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: groupNum == 0 ? Colors.orange : Colors.green)),
                  ],
                ),
              ],
            ),
          ),

          // Action Button
          IconButton(
            icon: const Icon(Icons.person_add_alt_1, color: Colors.blue, size: 20),
            onPressed: () => _onStudentSelect(student),
          ),
        ],
      ),
    );
  }
}