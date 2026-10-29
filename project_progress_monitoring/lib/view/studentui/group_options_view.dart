import 'package:flutter/material.dart';
import '../../viewmodels/studentviewmodel/group_options_view_model.dart';
import 'lobby_view.dart';
import 'join_existing_group.dart';
import 'package:project_progress_monitoring/view/login_view.dart';

// ============================================================================
//                     --- STUDENT GROUP OPTIONS SCREEN (VIEW) ---
// ============================================================================
// PRIMARY SCHOOLER NOTE:
// What does this screen do?
// It is a waiting lobby choices screen for students who do NOT have a group yet!
// They have 3 paths to choose from:
// 1. "Create New Group" (They become the Group leader/Admin).
// 2. "Join Existing Group" (They search and join another group).
// 3. "Group Invitations" (They accept or reject invitations sent to them).
//
// Keep it simple! We use standard StatefulWidget state and setState() to redraw.
// ============================================================================
class GroupOptionsView extends StatefulWidget {
  // Simple List of Maps to hold logged-in student details (like name, registration number).
  final List<Map<String, dynamic>> userData;

  const GroupOptionsView({super.key, required this.userData});

  @override
  State<GroupOptionsView> createState() => _GroupOptionsViewState();
} // End of GroupOptionsView class

class _GroupOptionsViewState extends State<GroupOptionsView> {
  // 1. Linking our brain file (ViewModel) here so we can call its methods!
  final GroupOptionsViewModel _viewModel = GroupOptionsViewModel();

  // 2. STATE VARIABLES:
  // - _pendingInvites: Holds a list of active invitations received by the student.
  // - _isLoading: True if we are loading initial data, showing a spinner.
  // - _isProcessing: True if we are communicating with the server on button clicks (disables actions).
  List<dynamic> _pendingInvites = [];
  bool _isLoading = true;
  bool _isProcessing = false;

  // --------------------------------------------------------------------------
  // initState: The startup bell!
  // Runs automatically the moment the screen loads to query any invitations.
  // --------------------------------------------------------------------------
  @override
  void initState() {
    super.initState();
    _fetchData();
  } // End of initState method

  // --------------------------------------------------------------------------
  // FUNCTION: Fetch invitations from the server
  // --------------------------------------------------------------------------
  Future<void> _fetchData() async {
    // A. Show the spinner by setting _isLoading to true
    setState(() => _isLoading = true);
    
    // B. Get the registration number of the logged-in student
    String regNum = widget.userData[0]['id'];
    
    // C. Get invitations sent to this student
    List<dynamic> invites = await _viewModel.getPendingInvites(regNum);

    // D. Save the invitations list and hide the spinner
    if (mounted) {
      setState(() {
        _pendingInvites = invites;
        _isLoading = false;
      }); // End of setState
    } // End of if (mounted)
  } // End of _fetchData method

  // --------------------------------------------------------------------------
  // FUNCTION: Accept or Reject an invitation
  // --------------------------------------------------------------------------
  Future<void> _handleResponse(int requestId, String status) async {
    // A. Turn on processing spinner to prevent double-clicks
    setState(() => _isProcessing = true);

    // B. Send response to the server (status is either "Accepted" or "Rejected")
    bool success = await _viewModel.respondToRequest(requestId, status);

    // C. Turn off processing spinner
    setState(() => _isProcessing = false);

    if (success) {
      if (status == "Accepted") {
        // If accepted, immediately jump to the group Lobby/Manage page!
        _navigateToLobby();
      } else {
        // If rejected, show a message and reload the pending list!
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Request Rejected")));
        _fetchData();
      } // End of status check
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Operation failed")));
    } // End of success check
  } // End of _handleResponse method

  // --------------------------------------------------------------------------
  // FUNCTION: Logout and go back to Login screen
  // --------------------------------------------------------------------------
  // WHAT IT DOES: Clears all navigation history and returns to the Login screen.
  // WHY IT EXISTS: The student might want to switch accounts or exit before joining a group.
  // HOW IT WORKS: Navigator.pushAndRemoveUntil removes ALL previous screens so the Back
  //               button can never accidentally take you back to the app after logging out.
  void _logout() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginView()),
      (route) => false, // Remove every screen from the history stack
    ); // End of Navigator.pushAndRemoveUntil
  } // End of _logout method

  // --------------------------------------------------------------------------
  // FUNCTION: Create a brand new group as the leader (Admin)
  // --------------------------------------------------------------------------
  Future<void> _handleCreateGroup() async {
    // A. Turn on processing spinner to prevent double-clicks
    setState(() => _isProcessing = true);
    String regNum = widget.userData[0]['id'];

    // B. Tell the ViewModel to create a group
    bool success = await _viewModel.createGroup(regNum);

    // C. Turn off processing spinner
    setState(() => _isProcessing = false);

    if (success) {
      // If success, jump to the group Lobby page where they can invite friends!
      _navigateToLobby();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to create group")));
    } // End of success check
  } // End of _handleCreateGroup method

  // Helper method to navigate to LobbyView
  void _navigateToLobby() {
    // pushReplacement removes the options screen from memory so the user can't click "Back" into a non-group state!
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LobbyView(userData: widget.userData))
    ); // End of Navigator.pushReplacement

    _showNavigationDialog("Lobby Screen");
  } // End of _navigateToLobby method

  // Show a popup to confirm navigation success
  void _showNavigationDialog(String screenName) {
    showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Success"),
          content: Text("Action Successful. Navigate to: $screenName"),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK"))
          ], // End of actions
        ) // End of AlertDialog
    ); // End of showDialog
  } // End of _showNavigationDialog method

  // --------------------------------------------------------------------------
  // BUILD METHOD: Drawing the screen widgets!
  // --------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Group Options", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          // Refresh button to check for new invites
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchData,
          ), // End of IconButton
          // Logout Button
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            tooltip: "Logout",
            onPressed: _logout,
          ), // End of logout IconButton
        ], // End of actions
      ), // End of AppBar
      
      body: _isLoading
          ? const Center(child: CircularProgressIndicator()) // Spinner wheel
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            
            // --- SECTION 1: CREATE OR JOIN GROUP BANNER ---
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.blue.shade200),
              ), // End of BoxDecoration
              child: Column(
                children: [
                  const Icon(Icons.group_add, size: 50, color: Colors.blue),
                  const SizedBox(height: 15),
                  const Text(
                    "Haven't found a team yet?",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ), // End of Text
                  const SizedBox(height: 10),
                  const Text(
                    "Start your own group and invite your friends, or join an already existing eligible group!",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ), // End of Text
                  const SizedBox(height: 20),
                  
                  // BUTTON A: Create Group
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isProcessing ? null : _handleCreateGroup,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ), // End of styleFrom
                      child: _isProcessing
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text("Create New Group", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ), // End of ElevatedButton
                  ), // End of SizedBox
                  
                  const SizedBox(height: 12),
                  
                  // BUTTON B: Join Existing Group
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton(
                      onPressed: () {
                        // Navigate to JoinExistingGroup screen when clicked!
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => JoinExistingGroup(
                              student: {
                                "id": widget.userData[0]['id'],
                                "role": "student",
                              },
                            ),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.blue,
                        side: const BorderSide(color: Colors.blue, width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ), // End of styleFrom
                      child: const Text("Join Existing Group", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ), // End of OutlinedButton
                  ), // End of SizedBox
                ], // End of Column children
              ), // End of Column
            ), // End of Container

            const SizedBox(height: 40),
            const Divider(), // Grey horizontal separation line

            // --- SECTION 2: INCOMING GROUP INVITATIONS ---
            Row(
              children: const [
                Icon(Icons.notifications_active, color: Colors.orange),
                SizedBox(width: 8),
                Text(
                  "Group Invitations",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ), // End of Text
              ], // End of Row children
            ), // End of Row
            const SizedBox(height: 15),

            // Expanded stretches the list to fill all remaining empty room vertically!
            Expanded(
              child: _pendingInvites.isEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.mail_outline, size: 60, color: Colors.grey),
                    SizedBox(height: 15),
                    Text("No pending invitations", style: TextStyle(color: Colors.grey, fontSize: 16)),
                  ], // End of Column children
                ), // End of Column
              ) // End of Center
                  : ListView.builder(
                itemCount: _pendingInvites.length,
                itemBuilder: (context, index) {
                  final invite = _pendingInvites[index];
                  
                  // Return a clean invite card with Accept/Reject actions!
                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const CircleAvatar(
                                backgroundColor: Colors.orange,
                                child: Icon(Icons.group, color: Colors.white),
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Invite from: ${invite['FromRegNum']}",
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    ), // End of Text
                                    const Text("Wants you to join their group.", style: TextStyle(color: Colors.grey, fontSize: 13)),
                                  ], // End of Column children
                                ), // End of Column
                              ), // End of Expanded
                            ], // End of Row children
                          ), // End of Row
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              // REJECT BUTTON
                              OutlinedButton(
                                onPressed: _isProcessing
                                    ? null
                                    : () => _handleResponse(invite['RequestID'], "Rejected"),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.red,
                                  side: const BorderSide(color: Colors.red),
                                ),
                                child: const Text("Reject"),
                              ), // End of OutlinedButton
                              const SizedBox(width: 12),
                              
                              // ACCEPT BUTTON
                              ElevatedButton(
                                onPressed: _isProcessing
                                    ? null
                                    : () => _handleResponse(invite['RequestID'], "Accepted"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ), // End of styleFrom
                                child: const Text("Accept"),
                              ), // End of ElevatedButton
                            ], // End of Row children
                          ) // End of Row
                        ], // End of Column children
                      ), // End of Padding
                    ), // End of Card
                  ); // End of map item
                }, // End of itemBuilder
              ), // End of ListView.builder
            ), // End of Expanded
          ], // End of main Column children
        ), // End of Padding
      ), // End of body
    ); // End of Scaffold
  } // End of build method
} // End of _GroupOptionsViewState class