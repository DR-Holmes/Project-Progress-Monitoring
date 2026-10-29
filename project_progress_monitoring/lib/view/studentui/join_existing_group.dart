import 'package:flutter/material.dart';
import '../../viewmodels/studentviewmodel/join_existing_group_view_model.dart';
import 'lobby_view.dart';
import 'package:project_progress_monitoring/view/login_view.dart';

// ============================================================================
//                     --- JOIN EXISTING GROUP SCREEN (VIEW) ---
// ============================================================================
// PRIMARY SCHOOLER NOTE:
// What is a "View"? 
// This file is the "face" of your app! It is a "StatefulWidget" because the 
// things on the screen will change (like when groups load, when we search, 
// or when a card expands!).
//
// We do NOT use complex packages like BLoC or Provider here. 
// We strictly use simple "setState()" to tell Flutter to redraw the screen!
// ============================================================================
class JoinExistingGroup extends StatefulWidget {
  // A simple Map to hold the logged-in student's information!
  // Why? So we don't have to create complex Dart model classes that are hard to edit.
  final Map<String, dynamic> student;

  const JoinExistingGroup({super.key, required this.student});

  @override
  State<JoinExistingGroup> createState() => _JoinExistingGroupState();
} // End of JoinExistingGroup class

class _JoinExistingGroupState extends State<JoinExistingGroup> {
  // 1. Linking our brain file (ViewModel) here so we can ask it for data!
  final JoinExistingGroupViewModel _viewModel = JoinExistingGroupViewModel();
  
  // 2. STATE VARIABLES: Simple variables that store data on our screen!
  // - _groups: A list of maps representing the eligible groups fetched from the server.
  // - _isLoading: A true/false flag. If true, we show a circular spinner. If false, we show the list!
  // - _searchTerm: Whatever letters the user typed into the search bar.
  // - _selectedGroupId: The ID of the group the student has currently clicked on (-1 means none).
  // - _isProcessing: A true/false flag to disable buttons and show a tiny spinner when joining is in progress.
  List<Map<String, dynamic>> _groups = [];
  bool _isLoading = true;
  String _searchTerm = "";
  int _selectedGroupId = -1;
  bool _isProcessing = false;
  // - _selectedGenderFilter: The selected option for group gender composition ("ALL", "WITH_FEMALE", "NO_FEMALE").
  String _selectedGenderFilter = "ALL";

  // --------------------------------------------------------------------------
  // initState: The starting bell!
  // This is the very first function Flutter runs automatically when the screen opens.
  // We use it to start fetching eligible groups immediately!
  // --------------------------------------------------------------------------
  @override
  void initState() {
    super.initState();
    _fetchEligibleGroups();
  } // End of initState

  // --------------------------------------------------------------------------
  // FUNCTION: Fetch eligible groups from the ViewModel
  // --------------------------------------------------------------------------
  Future<void> _fetchEligibleGroups() async {
    // A. Show the loading spinner by setting _isLoading to true
    setState(() => _isLoading = true);

    // B. Get the registration number from the passed student map
    String regNum = widget.student['id'] ?? widget.student['regNum'];

    // C. Ask the ViewModel brain to get groups from the server
    final eligible = await _viewModel.getEligibleGroups(regNum);
    
    // D. If the screen is still active, save the list and hide the spinner!
    if (mounted) {
      setState(() {
        _groups = eligible;
        _isLoading = false;
      });
    }
  } // End of _fetchEligibleGroups

  // --------------------------------------------------------------------------
  // FUNCTION: Join the selected group and go to the dashboard
  // --------------------------------------------------------------------------
  Future<void> _handleJoin(int groupId) async {
    // A. Disable buttons and show progress spinner
    setState(() => _isProcessing = true);

    // B. Extract the student's registration number
    String regNum = widget.student['id'] ?? widget.student['regNum'];
    
    // C. Tell the ViewModel to register us in this group
    bool success = await _viewModel.joinGroup(groupId, regNum);
    
    // D. Turn off the process spinner
    setState(() => _isProcessing = false);

    if (success) {
      if (!mounted) return;
      // E. Show a happy green banner message at the bottom of the screen!
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Joined successfully ✅"),
          backgroundColor: Colors.green,
        ),
      );
      
      // F. Go to the Lobby to wait!
      // WHY: The group may not be finalized yet.
      // The admin still needs to lock the group before everyone moves to the Dashboard.
      // As a regular member (not admin), you go to the Lobby and wait.
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => LobbyView(
            userData: [
              {
                "id": regNum,
                "role": "student",
              }
            ],
          ),
        ),
        (route) => false,
      );
    } else {
      if (!mounted) return;
      // G. Show a sad red banner message if something failed!
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Failed to join group ❌"),
          backgroundColor: Colors.red,
        ),
      );
    }
  } // End of _handleJoin

  // --------------------------------------------------------------------------
  // FUNCTION: Logout and go back to Login screen
  // --------------------------------------------------------------------------
  // WHAT IT DOES: Clears all navigation history and returns to the Login screen.
  // WHY IT EXISTS: The student might want to exit before joining any group.
  void _logout() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginView()),
      (route) => false, // Remove every screen from the history stack
    ); // End of Navigator.pushAndRemoveUntil
  } // End of _logout method

  // --------------------------------------------------------------------------
  // BUILD METHOD: This is where we define the visual look of the screen!
  // --------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final filteredGroups = _groups.where((g) {
      final grpIdStr = "group ${g['groupId']}".toLowerCase();
      final matchesSearch = grpIdStr.contains(_searchTerm.toLowerCase());

      // Gender Composition Check
      // A group has a female member if any member's gender value is "F".
      final members = g['members'] as List<dynamic>? ?? [];
      final hasFemale = members.any((m) {
        final gValue = (m['gender'] ?? m['Gender'] ?? "").toString().toUpperCase();
        return gValue == "F";
      });

      bool matchesGender = true;
      if (_selectedGenderFilter == "WITH_FEMALE") {
        matchesGender = hasFemale;
      } else if (_selectedGenderFilter == "NO_FEMALE") {
        matchesGender = !hasFemale;
      }

      return matchesSearch && matchesGender;
    }).toList();

    // 2. Scaffold is the basic sheet of paper that forms our app page.
    return Scaffold(
      backgroundColor: Colors.grey.shade50, // Soft grey background color
      
      // Top Navigation Bar
      appBar: AppBar(
        title: const Text(
          "Join Existing Group",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0, // No shadow underneath the AppBar
        iconTheme: const IconThemeData(color: Colors.black), // Black back-arrow
        actions: [
          // Refresh Button: Tapping this pulls groups again from the server!
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchEligibleGroups,
          ),
          // Logout Button
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            tooltip: "Logout",
            onPressed: _logout,
          ),
        ],
      ),

      // Main screen content area
      body: _isLoading
          ? const Center(child: CircularProgressIndicator()) // Shows a round spinning wheel while loading!
          : Padding(
              padding: const EdgeInsets.all(16.0), // Gives 16 units of empty space around the border
              
              // Stacks widgets vertically from top to bottom
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  
                  // A. blue Info Banner at the top
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50, // Very soft blue background
                      borderRadius: BorderRadius.circular(10), // Rounded corners
                      border: Border.all(color: Colors.blue.shade200), // Blue border line
                    ),
                    child: const Text(
                      "Only eligible groups are shown (automatically filtered by your technology and FYP type).",
                      style: TextStyle(fontSize: 13, color: Colors.blue, fontWeight: FontWeight.w500),
                    ),
                  ),
                  const SizedBox(height: 15), // Puts 15 units of empty vertical space

                  // B. Search input Box
                  TextField(
                    onChanged: (val) => setState(() => _searchTerm = val), // Redraws list every time we type!
                    decoration: InputDecoration(
                      hintText: "Search by Group ID...",
                      prefixIcon: const Icon(Icons.search), // Magnifying glass icon on the left
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.white, // White background for the input box
                    ),
                  ),
                  const SizedBox(height: 12),

                  // C. Gender Composition dropdown filter
                  DropdownButtonFormField<String>(
                    value: _selectedGenderFilter,
                    decoration: InputDecoration(
                      labelText: "Group Gender Filter",
                      labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    items: const [
                      DropdownMenuItem<String>(value: "ALL", child: Text("All Groups")),
                      DropdownMenuItem<String>(value: "WITH_FEMALE", child: Text("Groups with Females")),
                      DropdownMenuItem<String>(value: "NO_FEMALE", child: Text("Groups with Males (Only)")),
                    ],
                    onChanged: (val) {
                      setState(() {
                        _selectedGenderFilter = val ?? "ALL";
                      });
                    },
                  ),
                  const SizedBox(height: 20),

                  // C. scrolling List of groups
                  Expanded(
                    child: filteredGroups.isEmpty
                        ? const Center(
                            // Shows a sad message if no groups match the search term or exist!
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.group_off, size: 60, color: Colors.grey),
                                SizedBox(height: 10),
                                Text(
                                  "No eligible groups found.",
                                  style: TextStyle(color: Colors.grey, fontSize: 16),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: filteredGroups.length,
                            itemBuilder: (context, index) {
                              final grp = filteredGroups[index];
                              final groupId = grp['groupId'] ?? -1;
                              final memberCount = grp['memberCount'] ?? 0;
                              final members = grp['members'] as List<dynamic>? ?? [];

                              // Return a beautiful Card for each group!
                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                elevation: 1,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(
                                    color: Colors.grey.shade200,
                                    width: 1,
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      
                                      // --- LEFT SIDE: Group Name, Member Count, and Members List ---
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "Group $groupId",
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black87,
                                              ),
                                            ),
                                            // GenderComposition Badge helper
                                            (() {
                                              final hasFemale = members.any((m) {
                                                final gValue = (m['gender'] ?? m['Gender'] ?? "").toString().toUpperCase();
                                                return gValue == "F";
                                              });

                                              return Wrap(
                                                spacing: 8,
                                                runSpacing: 4,
                                                crossAxisAlignment: WrapCrossAlignment.center,
                                                children: [
                                                  Text(
                                                    "$memberCount Members",
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                      color: Colors.grey.shade600,
                                                    ),
                                                  ),
                                                  if (hasFemale)
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                      decoration: BoxDecoration(
                                                        color: Colors.pink.shade50,
                                                        borderRadius: BorderRadius.circular(4),
                                                        border: Border.all(color: Colors.pink.shade100),
                                                      ),
                                                      child: Row(
                                                        mainAxisSize: MainAxisSize.min,
                                                        children: [
                                                          Icon(Icons.female, size: 12, color: Colors.pink.shade400),
                                                          const SizedBox(width: 2),
                                                          Text(
                                                            "Has Female",
                                                            style: TextStyle(
                                                              fontSize: 10,
                                                              fontWeight: FontWeight.bold,
                                                              color: Colors.pink.shade700,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    )
                                                  else
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                      decoration: BoxDecoration(
                                                        color: Colors.blue.shade50,
                                                        borderRadius: BorderRadius.circular(4),
                                                        border: Border.all(color: Colors.blue.shade100),
                                                      ),
                                                      child: Row(
                                                        mainAxisSize: MainAxisSize.min,
                                                        children: [
                                                          Icon(Icons.male, size: 12, color: Colors.blue.shade400),
                                                          const SizedBox(width: 2),
                                                          Text(
                                                            "Male Only",
                                                            style: TextStyle(
                                                              fontSize: 10,
                                                              fontWeight: FontWeight.bold,
                                                              color: Colors.blue.shade700,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                ],
                                              );
                                            })(),
                                            const SizedBox(height: 8),

                                            // Members List (Directly displayed like in the React Web code!)
                                            if (members.isNotEmpty) ...[
                                              Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: members.map((m) {
                                                  final String mName = m['name'] ?? m['Name'] ?? 'Student';
                                                  final String mTech = m['Technology'] ?? m['technology'] ?? 'General';
                                                  final String mGender = (m['gender'] ?? m['Gender'] ?? 'M').toString().toUpperCase();
                                                  
                                                  return Padding(
                                                    padding: const EdgeInsets.only(top: 4.0),
                                                    child: Row(
                                                      children: [
                                                        Icon(Icons.circle, size: 6, color: mGender == 'F' ? Colors.pink.shade300 : Colors.blue),
                                                        const SizedBox(width: 6),
                                                        Expanded(
                                                          child: Text(
                                                            "$mName ($mTech) - $mGender",
                                                            style: TextStyle(
                                                              fontSize: 12,
                                                              color: Colors.grey.shade800,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  );
                                                }).toList(),
                                              ),
                                            ] else ...[
                                              const Text(
                                                "No members yet",
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey,
                                                  fontStyle: FontStyle.italic,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),

                                      const SizedBox(width: 12),

                                      // --- RIGHT SIDE: Join Button ---
                                      SizedBox(
                                        height: 40,
                                        child: ElevatedButton(
                                          onPressed: _isProcessing
                                              ? null // Disable if already sending request to server
                                              : () => _handleJoin(groupId),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.blue,
                                            foregroundColor: Colors.white,
                                            elevation: 0,
                                            padding: const EdgeInsets.symmetric(horizontal: 16),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                          ),
                                          child: const Text(
                                            "Join",
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),

                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  } // End of build
} // End of _JoinExistingGroupState
