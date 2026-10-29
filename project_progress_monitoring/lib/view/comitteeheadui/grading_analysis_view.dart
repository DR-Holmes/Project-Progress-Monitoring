import 'package:flutter/material.dart';
import 'package:project_progress_monitoring/view/comitteeheadui/supervisor_sorted_list_view.dart';
import '../../viewmodels/comitteeheadviewmodel/grading_analysis_view_model.dart';

// ---------------------------------------------------------
// WHAT IS THIS FILE?
// This is the "View" or "Screen" for Grading Analysis.
// It draws the graphs, lists, and tables you see on the screen.
// It is heavily commented so a Primary Schooler can learn from it!
// ---------------------------------------------------------

class GradingAnalysisView extends StatefulWidget {
  // We pass the currently selected FYP from the dashboard here so we start on the right foot
  final String initialFyp;

  const GradingAnalysisView({super.key, required this.initialFyp});

  @override
  State<GradingAnalysisView> createState() => _GradingAnalysisViewState();
}

class _GradingAnalysisViewState extends State<GradingAnalysisView> {
  // 1. Link to our "Brain" (ViewModel)
  final GradingAnalysisViewModel _viewModel = GradingAnalysisViewModel();

  // 2. These lists hold the data we get from the internet
  // We use simple List<Map> instead of complicated models to keep it beginner-friendly
  List<Map<String, dynamic>> _sessionData = [];
  List<Map<String, dynamic>> _supervisorData = [];
  List<Map<String, dynamic>> _groupData = [];

  // 3. Variables to control the screen
  bool _isLoading = false; // Is the loading spinner spinning?
  late String _activeFyp; // Which FYP are we looking at? (FYP-1 or FYP-2)
  String _activeTab = "session"; // Which tab is clicked? (session, supervisor, or group)

  // 4. Variables for Searching and Filtering
  String _selectedSessionId = "all"; // "all" means show everything
  String _sessionSearchText = ""; // What did the user type in the session search box?
  String _supervisorSearchText = ""; // What did the user type in the supervisor search box?
  String _groupSearchText = ""; // What did the user type in the group search box?
  String _supervisorSort = "default"; // How should we sort supervisors?

  @override
  void initState() {
    super.initState();
    // Set our active FYP to the one passed from the previous screen
    _activeFyp = widget.initialFyp;
    // Load the data the very first time the screen opens
    _loadAllData();
  }

  // ---------------------------------------------------------
  // FUNCTION: _loadAllData
  // This talks to our ViewModel and downloads all three lists of data.
  // ---------------------------------------------------------
  Future<void> _loadAllData() async {
    // 1. Turn ON the loading spinner
    setState(() => _isLoading = true);

    // 2. Wait for all three lists to download from the internet
    var sessions = await _viewModel.fetchSessionData(_activeFyp);
    var supervisors = await _viewModel.fetchSupervisorData(_activeFyp);
    var groups = await _viewModel.fetchGroupData();

    // 3. Save the lists and turn OFF the loading spinner
    if (mounted) {
      setState(() {
        _sessionData = sessions;
        _supervisorData = supervisors;
        _groupData = groups;
        _isLoading = false;
      });
    }
  }

  // ---------------------------------------------------------
  // HELPER: Get Grade Colors
  // This returns a pretty color based on the grade letter (A+ is green, F is red).
  // ---------------------------------------------------------
  Color _getGradeColor(String? grade) {
    if (grade == null || grade.isEmpty) return Colors.grey;
    String g = grade.toUpperCase();
    if (g.startsWith("A")) return Colors.green; // A+, A, A-
    if (g.startsWith("B")) return Colors.blue; // B+, B, B-
    if (g.startsWith("C")) return Colors.orange; // C+, C, C-
    if (g.startsWith("D")) return Colors.deepOrangeAccent; // D+, D
    return Colors.red; // F
  }

  // ---------------------------------------------------------
  // HELPER: Filter Sessions
  // This grabs only the sessions that match our search text.
  // ---------------------------------------------------------
  List<Map<String, dynamic>> _getFilteredSessions() {
    return _sessionData.where((s) {
      String name = (s['SessionName'] ?? "").toString().toLowerCase();
      String search = _sessionSearchText.toLowerCase();
      bool matchesSearch = name.contains(search);

      // If a specific session is selected from the dropdown, only show that one
      if (_selectedSessionId != "all") {
        return matchesSearch && s['SessionId'].toString() == _selectedSessionId;
      }
      return matchesSearch;
    }).toList();
  }

  // ---------------------------------------------------------
  // HELPER: Get Total Enrolled Students count quickly
  // ---------------------------------------------------------
  int _getTotalStudents() {
    int total = 0;
    for (var s in _sessionData) {
      total += (s['TotalStudents'] as int? ?? 0);
    }
    return total;
  }

  // ---------------------------------------------------------
  // THE BIG BUILD FUNCTION
  // This draws everything on the screen.
  // ---------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50], // Very light grey background
      appBar: AppBar(
        title: const Text("Grading Analysis Dashboard", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 1, // Slight shadow under the bar
      ),
      // SingleChildScrollView makes the whole screen scrollable
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              
              // 1. FYP-1 and FYP-2 Toggle Buttons
              Row(
                children: [
                  _buildFypToggleBtn("FYP-1"),
                  const SizedBox(width: 10),
                  _buildFypToggleBtn("FYP-2"),
                ],
              ),
              const SizedBox(height: 20),

              // 2. Summary Cards (Total Students, Supervisors, Groups)
              Row(
                children: [
                  Expanded(child: _buildSummaryCard("Total Evaluated", "${_getTotalStudents()} Students", Colors.green)),
                  const SizedBox(width: 10),
                  Expanded(child: _buildSummaryCard("Supervisors", "${_supervisorData.length} Faculty", Colors.blue)),
                  const SizedBox(width: 10),
                  Expanded(child: _buildSummaryCard("Project Groups", "${_groupData.length} Groups", Colors.purple)),
                ],
              ),
              const SizedBox(height: 20),

              // 3. Search and Dropdown Controls
              _buildFilterControls(),
              const SizedBox(height: 20),

              // 4. The 3 Tabs (Session, Supervisor, Group)
              Row(
                children: [
                  Expanded(child: _buildTabBtn("Session Distribution", "session")),
                  Expanded(child: _buildTabBtn("Supervisor Performance", "supervisor")),
                  Expanded(child: _buildTabBtn("Group Deep Flow", "group")),
                ],
              ),
              const SizedBox(height: 20),

              // 5. The Content of the selected Tab
              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40.0),
                    child: CircularProgressIndicator(), // The spinning circle
                  ),
                )
              else
                _buildActiveTabContent(),

            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------
  // UI WIDGET: FYP Toggle Button
  // ---------------------------------------------------------
  Widget _buildFypToggleBtn(String fyp) {
    bool isActive = _activeFyp == fyp;
    return GestureDetector(
      onTap: () {
        // When clicked, change the FYP and reload the data!
        setState(() {
          _activeFyp = fyp;
        });
        _loadAllData();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? Colors.deepPurple : Colors.grey[200], // Purple if active, grey if not
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          "$fyp Grades",
          style: TextStyle(
            color: isActive ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------
  // UI WIDGET: Summary Card (Top colored boxes)
  // ---------------------------------------------------------
  Widget _buildSummaryCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1), // Very light version of the color
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black)),
        ],
      ),
    );
  }

  // ---------------------------------------------------------
  // UI WIDGET: Filter and Search Boxes
  // ---------------------------------------------------------
  Widget _buildFilterControls() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          // 1. Session Dropdown (Always visible)
          const Text("SESSION FILTER: ", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButton<String>(
              isExpanded: true,
              value: _selectedSessionId,
              underline: const SizedBox(), // Hides the default ugly line
              items: [
                const DropdownMenuItem(value: "all", child: Text("All Sessions")),
                // Add all our sessions to the dropdown
                ..._sessionData.map((s) {
                  return DropdownMenuItem(
                    value: s['SessionId'].toString(),
                    child: Text(s['SessionName'] ?? "Unknown"),
                  );
                }).toList(),
              ],
              onChanged: (val) {
                if (val != null) setState(() => _selectedSessionId = val);
              },
            ),
          ),
          
          const SizedBox(width: 20),

          // 2. The Search Box (Changes based on which tab is open)
          Expanded(
            flex: 2, // Take up twice as much space as the dropdown
            child: TextField(
              decoration: InputDecoration(
                hintText: "Search here...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 10),
              ),
              onChanged: (val) {
                // Save the text to the correct variable based on the active tab
                setState(() {
                  if (_activeTab == "session") _sessionSearchText = val;
                  if (_activeTab == "supervisor") _supervisorSearchText = val;
                  if (_activeTab == "group") _groupSearchText = val;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------
  // UI WIDGET: Tab Buttons (Session / Supervisor / Group)
  // ---------------------------------------------------------
  Widget _buildTabBtn(String title, String tabId) {
    bool isActive = _activeTab == tabId;
    return GestureDetector(
      onTap: () => setState(() => _activeTab = tabId), // Change active tab when clicked
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isActive ? Colors.deepPurple : Colors.transparent, // Underline if active
              width: 3,
            ),
          ),
        ),
        child: Center(
          child: Text(
            title,
            style: TextStyle(
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              color: isActive ? Colors.deepPurple : Colors.grey[600],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------
  // UI WIDGET: Decide which tab content to show
  // ---------------------------------------------------------
  Widget _buildActiveTabContent() {
    if (_activeTab == "session") {
      return _buildSessionTab();
    } else if (_activeTab == "supervisor") {
      return _buildSupervisorTab();
    } else {
      return _buildGroupTab();
    }
  }

  // ---------------------------------------------------------
  // TAB 1: SESSION DISTRIBUTION CONTENT
  // ---------------------------------------------------------
  Widget _buildSessionTab() {
    List<Map<String, dynamic>> filteredList = _getFilteredSessions();

    if (filteredList.isEmpty) {
      return const Center(child: Text("No sessions found."));
    }

    // A Column allows us to stack multiple widgets vertically
    return Column(
      children: filteredList.map((session) {
        
        // Extract grades safely
        Map<String, dynamic> grades = session['Grades'] ?? {};

        // List of all possible grades to loop through
        List<String> gradeKeys = ["APlus", "A", "AMinus", "BPlus", "B", "BMinus", "CPlus", "C", "CMinus", "DPlus", "D", "F"];
        List<String> gradeLabels = ["A+", "A", "A-", "B+", "B", "B-", "C+", "C", "C-", "D+", "D", "F"];

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          color: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // Session Name and Enrolled count
                Text(session['SessionName'] ?? "Unknown", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text("Total Enrolled: ${session['TotalStudents']}", style: const TextStyle(color: Colors.grey)),
                const Divider(height: 30),

                // Grid showing the grades
                LayoutBuilder(
                  builder: (context, constraints) {
                    // Decide how many columns we need based on the screen width!
                    double width = MediaQuery.of(context).size.width;
                    int crossAxisCount = width > 800 ? 6 : 4; // 4 boxes on mobile, 6 on tablets/PC
                    
                    return GridView.builder(
                      shrinkWrap: true, // Needed when GridView is inside a Column
                      physics: const NeverScrollableScrollPhysics(), // Prevent scrolling inside the card
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        childAspectRatio: 1.0, // Make the boxes square
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: gradeKeys.length,

                      itemBuilder: (context, index) {
                        String label = gradeLabels[index];
                        int count = grades[gradeKeys[index]] ?? 0;
                        Color color = _getGradeColor(label);

                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(
                                  color: color.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  label, 
                                  style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 10),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "$count", 
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  }
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ---------------------------------------------------------
  // TAB 2: SUPERVISOR PERFORMANCE CONTENT
  // ---------------------------------------------------------
  Widget _buildSupervisorTab() {
    // 1. Filter by search text
    List<Map<String, dynamic>> filteredList = _supervisorData.where((sup) {
      String name = (sup['SupervisorName'] ?? "").toString().toLowerCase();
      return name.contains(_supervisorSearchText.toLowerCase());
    }).toList();

    if (filteredList.isEmpty) {
      return const Center(child: Text("No supervisors found."));
    }

    return Column(
      children: filteredList.map((sup) {
        
        // Find grades. If a specific session is selected, find the grades for that session.
        int totalSupervised = sup['TotalSupervised'] ?? 0;
        Map<String, dynamic> grades = sup['Grades'] ?? {};

        if (_selectedSessionId != "all") {
          List<dynamic> breakdowns = sup['SessionBreakdowns'] ?? [];
          for (var b in breakdowns) {
            if (b['SessionId'].toString() == _selectedSessionId) {
              totalSupervised = b['TotalSupervised'] ?? 0;
              grades = b['Grades'] ?? {};
            }
          }
        }

        // List of all possible grades
        List<String> gradeKeys = ["APlus", "A", "AMinus", "BPlus", "B", "BMinus", "CPlus", "C", "CMinus", "DPlus", "D", "F"];
        List<String> gradeLabels = ["A+", "A", "A-", "B+", "B", "B-", "C+", "C", "C-", "D+", "D", "F"];

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          color: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(sup['SupervisorName'] ?? "Unknown", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(8)),
                      child: Text("$totalSupervised Students", style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Show tiny pills for each grade they've given
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: List.generate(gradeKeys.length, (index) {
                    int count = grades[gradeKeys[index]] ?? 0;
                    if (count == 0) return const SizedBox.shrink(); // Hide if count is 0


                    String label = gradeLabels[index];
                    Color color = _getGradeColor(label);

                    // Map<String, dynamic> grade = {"grades": "${label}"};
                    // GestureDetector(
                    //     onTap: () =>
                    //
                    //         Navigator.push(context, MaterialPageRoute(builder: (_) => SupervisorSortedListView(grade: [grade], )))
                    //
                    // );

                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            decoration: BoxDecoration(color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
                            child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 10)),
                          ),
                          const SizedBox(width: 4),
                          Text("$count", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        ],
                      ),
                    );
                  }),
                )
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ---------------------------------------------------------
  // TAB 3: GROUP DEEP FLOW CONTENT
  // ---------------------------------------------------------
  Widget _buildGroupTab() {
    // 1. Filter by search text (Checking project title or student name)
    List<Map<String, dynamic>> filteredList = _groupData.where((g) {
      String title = (g['ProjectTitle'] ?? "").toString().toLowerCase();
      
      // We also check if the search text matches any student inside the group!
      bool memberMatch = false;
      List<dynamic> members = g['Members'] ?? [];
      for (var m in members) {
        String studentName = (m['StudentName'] ?? "").toString().toLowerCase();
        if (studentName.contains(_groupSearchText.toLowerCase())) {
          memberMatch = true;
        }
      }

      bool textMatch = title.contains(_groupSearchText.toLowerCase()) || memberMatch;

      // 2. Check Session Dropdown Filter
      if (_selectedSessionId != "all") {
        // We find the session name from the id because group only has session name
        String selectedSessName = "";
        for (var s in _sessionData) {
          if (s['SessionId'].toString() == _selectedSessionId) {
            selectedSessName = s['SessionName'];
          }
        }
        return textMatch && (g['SessionName'] == selectedSessName);
      }
      return textMatch;
    }).toList();

    if (filteredList.isEmpty) {
      return const Center(child: Text("No groups found."));
    }

    return Column(
      children: filteredList.map((group) {
        List<dynamic> members = group['Members'] ?? [];

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          color: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Group Header
                Text(group['ProjectTitle'] ?? "No Title", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text("Supervisor: ${group['SupervisorName']}", style: const TextStyle(color: Colors.grey, fontSize: 13)),
                const SizedBox(height: 10),

                // Table of Members
                Container(
                  decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade200), borderRadius: BorderRadius.circular(8)),
                  child: Table(
                    columnWidths: const {
                      0: FlexColumnWidth(2), // Name column is wider
                      1: FlexColumnWidth(1), // RegNum column
                      2: FlexColumnWidth(1), // FYP1
                      3: FlexColumnWidth(1), // FYP2
                    },
                    children: [
                      // Table Header Row
                      TableRow(
                        decoration: BoxDecoration(color: Colors.grey[100]),
                        children: const [
                          Padding(padding: EdgeInsets.all(8.0), child: Text("Student", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                          Padding(padding: EdgeInsets.all(8.0), child: Text("RegNum", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                          Padding(padding: EdgeInsets.all(8.0), child: Text("FYP-1", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                          Padding(padding: EdgeInsets.all(8.0), child: Text("FYP-2", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                        ],
                      ),
                      // Loop through students in this group
                      ...members.map((m) {
                        return TableRow(
                          children: [
                            Padding(padding: const EdgeInsets.all(8.0), child: Text(m['StudentName'] ?? "", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500))),
                            Padding(padding: const EdgeInsets.all(8.0), child: Text(m['RegNum'] ?? "", style: const TextStyle(fontSize: 11, color: Colors.grey))),
                            Padding(padding: const EdgeInsets.all(8.0), child: _buildTinyGrade(m['Fyp1Grade'])),
                            Padding(padding: const EdgeInsets.all(8.0), child: _buildTinyGrade(m['Fyp2Grade'])),
                          ],
                        );
                      }).toList(),
                    ],
                  ),
                )
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ---------------------------------------------------------
  // HELPER: Build Tiny Grade Pill for Table
  // ---------------------------------------------------------
  Widget _buildTinyGrade(String? grade) {
    if (grade == null || grade.isEmpty) {
      return const Text("Pending", style: TextStyle(color: Colors.grey, fontSize: 11, fontStyle: FontStyle.italic));
    }
    Color color = _getGradeColor(grade);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Center(
        child: Text(grade, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 10)),
      ),
    );
  }
}
