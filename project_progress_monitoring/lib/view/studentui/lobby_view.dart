import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../api_config.dart';
import 'package:flutter/material.dart';
import 'package:project_progress_monitoring/view/login_view.dart';
import 'package:project_progress_monitoring/view/studentui/group_options_view.dart';
import 'package:project_progress_monitoring/view/studentui/student_dashboard_view.dart';

import '../../viewmodels/studentviewmodel/lobby_view_model.dart';

// ============================================================================
//                       --- MANAGE GROUP LOBBY SCREEN (VIEW) ---
// ============================================================================
// PRIMARY SCHOOLER NOTE:
// What does this screen do?
// This is the active "Lobby" for students who are currently in a group!
// 1. If you are a normal Group Member:
//    - You see your group members list.
//    - You wait for the Group leader (Admin) to finalize the group.
// 2. If you are the Group Leader (Admin):
//    - You can remove members if they aren't working.
//    - You can tap "Add More Members" to open a bottom search drawer.
//    - You can click "Finalize Group" to lock the group when you have your team!
//
// Keep it simple! We use standard StatefulWidget state and setState() to redraw.
// ============================================================================
class LobbyView extends StatefulWidget {
  // Simple List of Maps to hold logged-in student details (like name, registration number).
  final List<Map<String, dynamic>> userData;

  const LobbyView({super.key, required this.userData});

  @override
  State<LobbyView> createState() => _LobbyViewState();
} // End of LobbyView class

class _LobbyViewState extends State<LobbyView> {
  // 1. Linking our brain file (ViewModel) here so we can call its group APIs!
  final LobbyViewModel _viewModel = LobbyViewModel();

  // 2. STATE VARIABLES:
  // - _groupData: A Map containing details of this student's active group (ID, members, etc).
  // - _pendingRequests: Active invites sent out by the Admin that are still waiting for responses.
  // - _isLoading: True if we are fetching initial database details, showing a spinner.
  // - _isAdmin: True if this logged-in student is the group leader (Admin).
  Map<String, dynamic>? _groupData;
  List<dynamic> _pendingRequests = [];
  bool _isLoading = true;
  bool _isAdmin = false;

  // --------------------------------------------------------------------------
  // initState: The startup bell!
  // Runs automatically the moment the screen loads to query any active group details.
  // --------------------------------------------------------------------------
  @override
  void initState() {
    super.initState();
    // Start loading data immediately.
    _loadAllData();
  } // End of initState method

  // --------------------------------------------------------------------------
  // FUNCTION: Load all group details from the server
  // --------------------------------------------------------------------------
  Future<void> _loadAllData() async {
    // A. Show the spinner by setting _isLoading to true
    setState(() => _isLoading = true);
    
    // B. Get registration number of the logged-in student
    String regNum = widget.userData[0]['id'];

    // C. Ask the ViewModel brain if this student is the leader/Admin
    _isAdmin = await _viewModel.checkIsAdmin(regNum);

    // D. Fetch the actual active group details (ID and members list)
    final group = await _viewModel.getMyGroup(regNum);

    // E. If Admin, fetch the list of pending invitations sent out
    if (_isAdmin) {
      _pendingRequests = await _viewModel.getGroupRequests(regNum);
    } // End of if (_isAdmin)

    if (mounted) {
      // F. Save the data and hide the spinner!
      setState(() {
        _groupData = group;
        _isLoading = false;
      }); // End of setState
    } // End of if (mounted)
  } // End of _loadAllData method

  // --------------------------------------------------------------------------
  // FUNCTION: Logout and clear navigation history
  // --------------------------------------------------------------------------
  void _logout() {
    // Clear the navigation stack and go to Login screen.
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginView()),
      (route) => false,
    ); // End of Navigator.pushAndRemoveUntil
  } // End of _logout method

  // --------------------------------------------------------------------------
  // FUNCTION: Go back to choices (if group was deleted/null)
  // --------------------------------------------------------------------------
  void _goBack() {
    // Go back to the screen where you choose to create or join a group.
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => GroupOptionsView(userData: widget.userData)),
    ); // End of Navigator.pushReplacement
  } // End of _goBack method

  // --------------------------------------------------------------------------
  // FUNCTION: Open "Add Member Drawer" from the bottom of the phone
  // --------------------------------------------------------------------------
  void _showAddMembersSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Allows the sheet to expand up and have custom height
      backgroundColor: Colors.transparent, // Keeps edges rounded and transparent
      builder: (_) => AddMemberSheet(
        currentUserRegNum: widget.userData[0]['id'],
        viewModel: _viewModel,
        onRefresh: _loadAllData, // Passes refresh function so we reload members after invites are sent!
      ), // End of AddMemberSheet
    ); // End of showModalBottomSheet
  } // End of _showAddMembersSheet method

  // --------------------------------------------------------------------------
  // FUNCTION: Finalize (Lock) the group
  // --------------------------------------------------------------------------
  Future<void> _finalizeGroup() async {
    if (_groupData == null) return;

    // A. Show a nice dialog box to double-check if they are sure!
    bool confirm = await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Finalize Group?"),
          content: const Text("Once finalized, you cannot add or remove members. You will be moved to the Dashboard."),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
            ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text("Confirm")),
          ], // End of actions
        ) // End of AlertDialog
    ) ?? false; // End of showDialog

    if (!confirm) return;

    // B. Call the ViewModel to lock the group in the database.
    bool success = await _viewModel.finalizeGroup(_groupData!['groupId']);
    
    if (success) {
      if(!mounted) return;
      // C. Navigate to the Dashboard after success!
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => StudentDashboardView(userData: widget.userData))
      ); // End of Navigator.pushReplacement
    } else {
      if(!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to finalize.")));
    } // End of if/else
  } // End of _finalizeGroup method

  // --------------------------------------------------------------------------
  // FUNCTION: Remove a student from the group (Admin only)
  // --------------------------------------------------------------------------
  Future<void> _removeMember(String regNum) async {
    bool success = await _viewModel.removeMember(_groupData!['groupId'], regNum);
    if (success) {
      _loadAllData(); // Refresh the list if successful.
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to remove member.")));
    } // End of if/else
  } // End of _removeMember method

  // --------------------------------------------------------------------------
  // BUILD METHOD: Painting the Lobby UI screen!
  // --------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    // 1. Error state: If group data is null, show a clean message and let them go back!
    if (_groupData == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Lobby"),
          actions: [
            IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
          ], // End of actions
        ), // End of AppBar
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.group_off, size: 80, color: Colors.grey),
                const SizedBox(height: 20),
                const Text(
                  "No active group found for you.",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ), // End of Text
                const SizedBox(height: 10),
                const Text(
                  "You might have been removed or the group was deleted.",
                  style: TextStyle(color: Colors.grey),
                  textAlign: TextAlign.center,
                ), // End of Text
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _goBack,
                    child: const Text("Back to Group Options"),
                  ), // End of ElevatedButton
                ), // End of SizedBox
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _logout,
                    child: const Text("Logout"),
                  ), // End of OutlinedButton
                ), // End of SizedBox
              ], // End of Column children
            ), // End of Column
          ), // End of Padding
        ), // End of Center
      ); // End of Scaffold
    } // End of if (_groupData == null)

    List members = _groupData!['members'];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Manage Group"),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadAllData),
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
        ], // End of actions
      ), // End of AppBar
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            
            // A. Status Banner (Tells you if you are leader or member)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: _isAdmin ? Colors.blue.shade50 : Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _isAdmin ? Colors.blue.shade200 : Colors.orange.shade200)
              ), // End of BoxDecoration
              child: Row(
                children: [
                  Icon(_isAdmin ? Icons.admin_panel_settings : Icons.hourglass_empty, 
                       color: _isAdmin ? Colors.blue : Colors.orange),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _isAdmin
                          ? "You are the Admin. Manage your team and finalize when ready."
                          : "You are a member. Only the Admin can add/remove members or finalize.",
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                    ), // End of Text
                  ), // End of Expanded
                ], // End of Row children
              ), // End of Row
            ), // End of Container
            const SizedBox(height: 24),

            // B. Members List Section
            Row(
              children: const [
                Icon(Icons.people, color: Colors.blue),
                SizedBox(width: 8),
                Text("Group Members", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ], // End of Row children
            ), // End of Row
            const SizedBox(height: 12),
            
            // Loop through and display a card for each current group member!
            ...members.map((m) {
              bool isMe = m['regNum'] == widget.userData[0]['id'];
              bool isMemberAdmin = m['isAdmin'] == 1;
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isMemberAdmin ? Colors.amber : Colors.blueGrey,
                    child: Icon(isMemberAdmin ? Icons.star : Icons.person, color: Colors.white),
                  ), // End of CircleAvatar
                  title: Text("${m['name'] ?? 'Student'}", style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(m['regNum'] + (isMe ? " (You)" : "")),
                  trailing: (_isAdmin && !isMe)
                      ? IconButton(
                    icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                    onPressed: () => _removeMember(m['regNum']),
                  ) // End of IconButton
                      : (isMemberAdmin ? const Text("Admin", style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)) : null),
                ), // End of ListTile
              ); // End of Card
            }).toList(), // End of map

            const SizedBox(height: 24),

            // C. Pending Invitations Section (Visible only to the Admin!)
            if (_isAdmin && _pendingRequests.isNotEmpty) ...[
              Row(
                children: const [
                  Icon(Icons.mail_outline, color: Colors.orange),
                  SizedBox(width: 8),
                  Text("Pending Invites", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ], // End of Row children
              ), // End of Row
              const SizedBox(height: 12),
              ..._pendingRequests.map((r) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  color: Colors.grey.shade50,
                  child: ListTile(
                    title: Text(r['MemberRegNum']),
                    subtitle: Text("Status: ${r['Status']}"),
                    trailing: const Icon(Icons.timer, color: Colors.orange, size: 20),
                  ), // End of ListTile
                ); // End of Card
              }).toList(), // End of map
              const SizedBox(height: 24),
            ], // End of if (_isAdmin)

            // D. Admin action buttons (Invite members, Finalize group)
            if (_isAdmin) ...[
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton.icon(
                  onPressed: _showAddMembersSheet,
                  icon: const Icon(Icons.person_add_alt_1),
                  label: const Text("Add More Members", style: TextStyle(fontSize: 16)),
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ), // End of styleFrom
                ), // End of ElevatedButton.icon
              ), // End of SizedBox
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton.icon(
                  onPressed: members.length >= 1 ? _finalizeGroup : null,
                  icon: const Icon(Icons.rocket_launch),
                  label: const Text("Finalize Group", style: TextStyle(fontSize: 16)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ), // End of styleFrom
                ), // End of ElevatedButton.icon
              ), // End of SizedBox
            ], // End of if (_isAdmin)
          ], // End of Column children
        ), // End of Column
      ), // End of SingleChildScrollView
    ); // End of Scaffold
  } // End of build method
} // End of _LobbyViewState class


// ============================================================================
//                  --- BOTTOM SHEET FOR INVITING MEMBERS ---
// ============================================================================
// PRIMARY SCHOOLER NOTE:
// This is the bottom sheet drawer that slides up.
// It fetches available students who are in a different technology (for multidisciplinary group creation),
// and lets the Admin search and filter them by Department and Section in real-time!
// ============================================================================
class AddMemberSheet extends StatefulWidget {
  final String currentUserRegNum;
  final LobbyViewModel viewModel;
  final VoidCallback onRefresh;

  const AddMemberSheet({
    super.key, 
    required this.currentUserRegNum, 
    required this.viewModel,
    required this.onRefresh
  }); // End of constructor

  @override
  State<AddMemberSheet> createState() => _AddMemberSheetState();
} // End of AddMemberSheet class

class _AddMemberSheetState extends State<AddMemberSheet> {
  // Lists for local student lists
  List<dynamic> _allStudents = [];
  List<dynamic> _filteredStudents = [];
  final List<String> _selectedStudents = [];
  
  bool _isLoading = true;
  bool _isSending = false;

  // Dynamic dropdown value lists from the database!
  List<dynamic> _departments = [];
  List<dynamic> _sections = [];

  // Dropdown selections
  String _selectedDepartment = "ALL";
  String _selectedSection = "ALL";
  String _selectedGender = "ALL";
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    // Load available students as soon as the drawer sheet is opened!
    _loadStudents();
  } // End of initState method

  // Fetch available students from the ViewModel API
  Future<void> _loadStudents() async {
    // 1. Fetch available students list (from different tech tracks)
    var list = await widget.viewModel.getAvailableStudents(widget.currentUserRegNum);
    
    // 2. Fetch departments and sections dynamically from DB!
    var deptList = await widget.viewModel.getDepartments();
    var secList = await widget.viewModel.getSections();

    // 3. Fetch logged-in student's details to get their default department and section
    final meUrl = Uri.parse("${ApiConfig.baseUrl}/users/StudentDetails/${widget.currentUserRegNum}");
    try {
      final meResponse = await http.get(meUrl);
      if (meResponse.statusCode == 200) {
        final List<dynamic> meDataList = jsonDecode(meResponse.body);
        if (meDataList.isNotEmpty) {
          final studentData = meDataList[0];
          final String rawDept = (studentData['DepartmentName'] ?? "ALL").toString().toUpperCase();
          final String rawSec = (studentData['SectionName'] ?? "ALL").toString().toUpperCase();

          // Match the department from DB list that contains the text
          for (var d in deptList) {
            final String dName = (d['name'] ?? "").toString().toUpperCase();
            if (rawDept.contains(dName) || dName.contains(rawDept)) {
              _selectedDepartment = d['name'];
              break;
            }
          }

          // Match the section from DB list that contains the text
          for (var s in secList) {
            final String sName = (s['name'] ?? "").toString().toUpperCase();
            if (rawSec.contains(sName) || sName.contains(rawSec)) {
              _selectedSection = s['name'];
              break;
            }
          }
        }
      }
    } catch(e) {
      debugPrint("!!! [Primary Schooler Warning] Failed to load my default dept/section: $e");
    }

    if(mounted) {
      setState(() {
        _allStudents = list;
        
        // Build departments dropdown items list, ensuring "ALL" is first
        _departments = [{"id": 0, "name": "ALL"}];
        _departments.addAll(deptList);

        // Build sections dropdown items list, ensuring "ALL" is first
        _sections = [{"id": 0, "name": "ALL"}];
        _sections.addAll(secList);

        _isLoading = false;
        // 4. Immediately filter the students using our newly mapped default filters!
        _filterStudents();
      }); // End of setState
    } // End of if (mounted)
  } // End of _loadStudents method

  // --------------------------------------------------------------------------
  // FUNCTION: Filter students by text, department, and section dropdowns
  // --------------------------------------------------------------------------
  // WHAT IT DOES: 
  // It filters the student list based on name, registration number, department, 
  // and section. It also ensures the logged-in student themselves is excluded!
  // --------------------------------------------------------------------------
  void _filterStudents() {
    setState(() {
      _filteredStudents = _allStudents.where((s) {
        // A. Exclude logged-in student (notSelf check)
        final studentReg = (s['regNum'] ?? s['studentId'] ?? "").toString();
        if (studentReg == widget.currentUserRegNum) {
          return false;
        }

        // B. Match text search (searches name and registration number)
        final name = (s['name'] ?? "").toString().toLowerCase();
        final reg = (s['regNum'] ?? "").toString().toLowerCase();
        final q = _searchQuery.toLowerCase();
        final matchesSearch = name.contains(q) || reg.contains(q);

        // C. Match selected Department dropdown (dynamically fetched)
        final dept = (s['DepartmentName'] ?? s['departmentName'] ?? s['department'] ?? "").toString().toUpperCase();
        final matchesDept = _selectedDepartment == "ALL" || dept.contains(_selectedDepartment.toUpperCase());

        // D. Match selected Section dropdown (dynamically fetched)
        final sec = (s['SectionName'] ?? s['sectionName'] ?? s['section'] ?? "").toString().toUpperCase();
        final matchesSection = _selectedSection == "ALL" || sec.contains(_selectedSection.toUpperCase());

        // E. Match selected Gender dropdown
        final gnd = (s['gender'] ?? s['Gender'] ?? "").toString().toUpperCase();
        final matchesGender = _selectedGender == "ALL" || gnd == _selectedGender.toUpperCase();

        return matchesSearch && matchesDept && matchesSection && matchesGender;
      }).toList(); // End of filtering
    }); // End of setState
  } // End of _filterStudents method

  // --------------------------------------------------------------------------
  // FUNCTION: Send invitations to selected students
  // --------------------------------------------------------------------------
  Future<void> _sendInvites() async {
    setState(() => _isSending = true);

    bool success = await widget.viewModel.sendInvites(widget.currentUserRegNum, _selectedStudents);

    if(mounted) {
      setState(() => _isSending = false);
      if(success) {
        Navigator.pop(context); // Close the bottom sheet drawer!
        widget.onRefresh(); // Refresh the main lobby list immediately!
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Group Requests Sent Successfully ✅")));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to send requests ❌")));
      } // End of success check
    } // End of if mounted
  } // End of _sendInvites method

  // --------------------------------------------------------------------------
  // BUILD METHOD: Painting the bottom drawer UI!
  // --------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85, // Fill 85% height of the phone screen
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ), // End of BoxDecoration
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle tab at the top of the sheet
          Center(
            child: Container(
              width: 40, height: 5,
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)),
            ), // End of Container
          ), // End of Center
          const SizedBox(height: 20),
          
          const Text("Add Members", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const Text("Filter and search students to send invitations.", style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 20),

          // --- Search Bar ---
          TextField(
            onChanged: (val) {
              _searchQuery = val;
              _filterStudents();
            },
            decoration: InputDecoration(
              hintText: "Search students...",
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Colors.grey.shade50,
            ), // End of InputDecoration
          ), // End of TextField
          const SizedBox(height: 12),

          // --- Dropdown filters row ---
          Row(
            children: [
              // Department dropdown
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedDepartment,
                  decoration: InputDecoration(
                    labelText: "Department",
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  items: _departments.map<DropdownMenuItem<String>>((dynamic dept) {
                    final String value = (dept['name'] ?? "ALL").toString();
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value == "ALL" ? "All Depts" : value, style: const TextStyle(fontSize: 13)),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedDepartment = val ?? "ALL";
                      _filterStudents();
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),
              
              // Section dropdown
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedSection,
                  decoration: InputDecoration(
                    labelText: "Section",
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  items: _sections.map<DropdownMenuItem<String>>((dynamic sec) {
                    final String value = (sec['name'] ?? "ALL").toString();
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value == "ALL" ? "All Sections" : value, style: const TextStyle(fontSize: 13)),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedSection = val ?? "ALL";
                      _filterStudents();
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Gender dropdown (Full width)
          DropdownButtonFormField<String>(
            value: _selectedGender,
            decoration: InputDecoration(
              labelText: "Gender",
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
            items: const [
              DropdownMenuItem<String>(value: "ALL", child: Text("All Genders", style: TextStyle(fontSize: 13))),
              DropdownMenuItem<String>(value: "M", child: Text("Male", style: TextStyle(fontSize: 13))),
              DropdownMenuItem<String>(value: "F", child: Text("Female", style: TextStyle(fontSize: 13))),
            ],
            onChanged: (val) {
              setState(() {
                _selectedGender = val ?? "ALL";
                _filterStudents();
              });
            },
          ),
          const SizedBox(height: 15),

          // --- Student scrolling checkbox list ---
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredStudents.isEmpty
                ? const Center(child: Text("No students match your filters."))
                : ListView.builder(
              itemCount: _filteredStudents.length,
              itemBuilder: (context, index) {
                final s = _filteredStudents[index];
                bool isSelected = _selectedStudents.contains(s['regNum']);

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: isSelected ? Colors.blue : Colors.grey.shade200, width: 1.5),
                  ), // End of RoundedRectangleBorder
                  child: CheckboxListTile(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    title: Text("${s['name']}", style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text("${s['regNum']} • ${s['DepartmentName'] ?? 'Student'}"),
                    secondary: CircleAvatar(
                      backgroundColor: Colors.blue.shade50,
                      child: Text(s['name'][0], style: const TextStyle(color: Colors.blue)),
                    ), // End of CircleAvatar
                    value: isSelected,
                    onChanged: (val) {
                      // Toggle selection of this student.
                      setState(() {
                        if(val == true) {
                          _selectedStudents.add(s['regNum']);
                        } else {
                          _selectedStudents.remove(s['regNum']);
                        } // End of if/else
                      }); // End of setState
                    }, // End of onChanged
                  ), // End of CheckboxListTile
                ); // End of Card
              }, // End of itemBuilder
            ), // End of ListView.builder
          ), // End of Expanded

          const SizedBox(height: 20),
          
          // --- Cancel and Send buttons ---
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ), // End of styleFrom
                  child: const Text("Cancel"),
                ), // End of OutlinedButton
              ), // End of Expanded
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: (_isSending || _selectedStudents.isEmpty) ? null : _sendInvites,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ), // End of styleFrom
                  child: _isSending 
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                      : const Text("Send Requests"),
                ), // End of ElevatedButton
              ), // End of Expanded
            ], // End of Row children
          ) // End of Row
        ], // End of Column children
      ), // End of Column
    ); // End of Container
  } // End of build method
} // End of _AddMemberSheetState class
