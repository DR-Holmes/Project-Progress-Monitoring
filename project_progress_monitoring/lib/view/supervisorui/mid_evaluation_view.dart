import 'package:flutter/material.dart';
import '../../viewmodels/supervisorviewmodel/mid_evaluation_viewmodel.dart';

// ============================================================================
// WHAT IS THIS FILE?
// This is the "View" or "UI Screen" for the Supervisor's Mid Task Evaluation (FYP-2).
// It replaces the old basic dropdown screen with a beautiful, rich General Task Evaluation
// workflow featuring side-by-side group list cards, filter badges (Unassigned, Assigned, Evaluated),
// live search, rubric details, and individual student grading cards.
//
// WHY DOES IT EXIST?
// To provide supervisors with a premium, newbie-friendly evaluation interface matching the
// Committee General Task Evaluation screen, tailored specifically for FYP-2 Mid Evaluation.
// ============================================================================

class MidEvaluationView extends StatefulWidget {
  final Map<String, dynamic> userMap;
  const MidEvaluationView({super.key, required this.userMap});

  @override
  State<MidEvaluationView> createState() => _MidEvaluationViewState();
}

class _MidEvaluationViewState extends State<MidEvaluationView> {
  // 1. Instantiate our Brain (ViewModel)
  final MidEvaluationViewModel _viewModel = MidEvaluationViewModel();

  // 2. Local State Variables managed via setState()
  String _activeFilter = "assigned"; // unassigned, assigned, evaluated
  String _searchQuery = "";

  // 3. Controllers mapped by studentName matching existing supervisor pattern
  final Map<String, TextEditingController> _marksControllers = {};
  final Map<String, TextEditingController> _remarksControllers = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    for (var c in _marksControllers.values) { c.dispose(); }
    for (var c in _remarksControllers.values) { c.dispose(); }
    super.dispose();
  }

  // -------------------------------------------------------------
  // METHOD: _loadData
  // Fetches approved supervisor groups and refreshes UI
  // -------------------------------------------------------------
  Future<void> _loadData() async {
    final mySupervisorId = (widget.userMap['id'] ?? '').toString();
    await _viewModel.fetchSupervisorGroups(
      supervisorId: mySupervisorId,
      activeFilter: _activeFilter,
      searchQuery: _searchQuery,
    );
    if (mounted) setState(() {});
  }

  // -------------------------------------------------------------
  // METHOD: _onSelectGroup
  // Loads group members and initializes controllers
  // -------------------------------------------------------------
  Future<void> _onSelectGroup(Map<String, dynamic> group) async {
    setState(() => _viewModel.isLoading = true);

    final mySupervisorId = (widget.userMap['id'] ?? '').toString();
    await _viewModel.selectGroupAndLoadMembers(group, mySupervisorId);

    // Initialize controllers for each student
    _marksControllers.clear();
    _remarksControllers.clear();

    for (var student in _viewModel.selectedGroupMembers) {
      final sName = student['StudentName']?.toString() ?? '';
      if (sName.isNotEmpty) {
        final savedMarks = _viewModel.marksInput[sName] ?? '';
        final savedRemarks = _viewModel.remarksInput[sName] ?? '';

        _marksControllers[sName] = TextEditingController(text: savedMarks);
        _remarksControllers[sName] = TextEditingController(text: savedRemarks);
      }
    }

    if (mounted) {
      setState(() => _viewModel.isLoading = false);
    }
  }

  // -------------------------------------------------------------
  // METHOD: _onSaveIndividualStudent
  // Triggers post-back for a single student's evaluation marks and remarks
  // -------------------------------------------------------------
  Future<void> _onSaveIndividualStudent(Map<String, dynamic> member) async {
    final sName = member['StudentName']?.toString() ?? '';
    final mySupervisorId = (widget.userMap['id'] ?? '').toString();

    // Copy controller values to our ViewModel inputs
    _viewModel.marksInput[sName] = _marksControllers[sName]?.text.trim() ?? '';
    _viewModel.remarksInput[sName] = _remarksControllers[sName]?.text.trim() ?? '';

    setState(() => _viewModel.savingIndividualMap[sName] = true);

    final errorMsg = await _viewModel.saveIndividualEvaluation(
      member: member,
      supervisorId: mySupervisorId,
    );

    if (mounted) {
      setState(() => _viewModel.savingIndividualMap[sName] = false);
      if (errorMsg != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg), backgroundColor: Colors.redAccent),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Evaluation marks saved successfully for $sName! ✅"),
            backgroundColor: Colors.green,
          ),
        );
        _loadData(); // Refresh list to update evaluated counts
      }
    }
  }

  // -------------------------------------------------------------
  // METHOD: _onSubmitAllEvaluations
  // Submits all students in the group at once
  // -------------------------------------------------------------
  Future<void> _onSubmitAllEvaluations() async {
    final mySupervisorId = (widget.userMap['id'] ?? '').toString();

    // Copy all controller values to ViewModel
    for (var student in _viewModel.selectedGroupMembers) {
      final sName = student['StudentName']?.toString() ?? '';
      if (sName.isNotEmpty) {
        _viewModel.marksInput[sName] = _marksControllers[sName]?.text.trim() ?? '';
        _viewModel.remarksInput[sName] = _remarksControllers[sName]?.text.trim() ?? '';
      }
    }

    setState(() => _viewModel.isSavingAll = true);

    final errorMsg = await _viewModel.submitAllEvaluations(supervisorId: mySupervisorId);

    if (mounted) {
      setState(() => _viewModel.isSavingAll = false);
      if (errorMsg != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg), backgroundColor: Colors.redAccent),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("All evaluations submitted successfully for Group ${_viewModel.selectedGroup!['groupName']}! 🎉"),
            backgroundColor: Colors.green,
          ),
        );
        _loadData(); // Refresh list
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Supervisor Mid Evaluation (FYP-2)',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.blueAccent),
            onPressed: _loadData,
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // 1. Top Controls Bar (Static Title + Search)
              _buildTopControlsBar(),
              const SizedBox(height: 16),

              // 2. Filter Badges Bar (Unassigned, Assigned, Evaluated)
              _buildFilterBadgesBar(),
              const SizedBox(height: 20),

              // 3. Main Content Split Pane
              Expanded(
                child: isDesktop ? _buildDesktopSplitView() : _buildMobileStackView(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // TOP BAR: Static Title Badge & Search Bar
  // -------------------------------------------------------------
  Widget _buildTopControlsBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: Colors.blueAccent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.3)),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.assessment_outlined, color: Colors.blueAccent, size: 20),
                SizedBox(width: 8),
                Text(
                  "MidTask Evaluation Panel (FYP-2)",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.blueAccent),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            decoration: InputDecoration(
              hintText: "Search by Group ID or Project Name...",
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              filled: true,
              fillColor: Colors.grey.shade100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            ),
            onChanged: (val) {
              _searchQuery = val;
              _viewModel.applyFilters(_activeFilter, val);
              setState(() {});
            },
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // FILTER BADGES: Unassigned, Assigned, Evaluated
  // -------------------------------------------------------------
  Widget _buildFilterBadgesBar() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFilterBadge("unassigned", "Unassigned Task", Icons.assignment_late_outlined, Colors.redAccent),
          const SizedBox(width: 10),
          _buildFilterBadge("assigned", "Assigned Task", Icons.play_circle_outline, Colors.amber.shade800),
          const SizedBox(width: 10),
          _buildFilterBadge("evaluated", "Evaluated Milestone", Icons.check_circle_outline, const Color(0xFF10B981)),
        ],
      ),
    );
  }

  Widget _buildFilterBadge(String filterKey, String label, IconData icon, Color color) {
    final bool isSel = _activeFilter == filterKey;
    return InkWell(
      onTap: () {
        setState(() {
          _activeFilter = filterKey;
          _viewModel.selectedGroup = null;
          _viewModel.applyFilters(filterKey, _searchQuery);
        });
      },
      borderRadius: BorderRadius.circular(30),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: isSel ? color.withValues(alpha: 0.12) : Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: isSel ? color : Colors.grey.shade200, width: isSel ? 1.5 : 1),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: isSel ? color : Colors.grey.shade600),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: isSel ? color : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // SPLIT VIEWS: Desktop (Side-by-Side) vs Mobile (Stack/Modal)
  // -------------------------------------------------------------
  Widget _buildDesktopSplitView() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left Pane: Groups List
        Expanded(
          flex: 4,
          child: _buildGroupsListPanel(),
        ),
        const SizedBox(width: 20),
        // Right Pane: Detailed Grading Forms
        Expanded(
          flex: 6,
          child: SingleChildScrollView(
            child: _buildGradingPanel(),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileStackView() {
    if (_viewModel.selectedGroup != null) {
      return Column(
        children: [
          Row(
            children: [
              TextButton.icon(
                onPressed: () => setState(() => _viewModel.selectedGroup = null),
                icon: const Icon(Icons.arrow_back_ios, size: 14),
                label: const Text("Back to Groups List"),
              ),
            ],
          ),
          Expanded(
            child: SingleChildScrollView(
              child: _buildGradingPanel(),
            ),
          ),
        ],
      );
    }
    return _buildGroupsListPanel();
  }

  // -------------------------------------------------------------
  // PANEL COMPONENT: Groups List Panel
  // -------------------------------------------------------------
  Widget _buildGroupsListPanel() {
    if (_viewModel.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_viewModel.filteredGroups.isEmpty) {
      return Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.group_off_outlined, size: 48, color: Colors.grey.shade300),
              const SizedBox(height: 12),
              const Text("No Groups Found", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 6),
              Text(
                "No groups match the current filter and search query.",
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: _viewModel.filteredGroups.length,
      itemBuilder: (context, index) {
        final g = _viewModel.filteredGroups[index];
        final bool isSel = _viewModel.selectedGroup?['groupName'] == g['groupName'];
        final Color statusColor = _getStatusBadgeColor(g['evaluationStatus']);

        return InkWell(
          onTap: () => _onSelectGroup(g),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSel ? Colors.blueAccent.withValues(alpha: 0.05) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSel ? Colors.blueAccent : Colors.grey.shade200,
                width: isSel ? 2 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Group ${g['groupName']}",
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        g['evaluationStatus'].toString().toUpperCase(),
                        style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  g['projectTitle'] ?? "No Project Title",
                  style: TextStyle(fontSize: 12, color: Colors.grey[700], fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.school_outlined, size: 14, color: Colors.blueAccent),
                        const SizedBox(width: 4),
                        Text(
                          "${g['membersCount']} Members",
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    if (g['evaluationStatus'] == "assigned")
                      Text(
                        "${g['membersEvaluatedCount']} / ${g['membersCount']} Graded",
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber[800],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _getStatusBadgeColor(dynamic status) {
    switch (status?.toString().toLowerCase()) {
      case "evaluated":
        return const Color(0xFF10B981);
      case "assigned":
        return Colors.amber.shade800;
      default:
        return Colors.redAccent;
    }
  }

  // -------------------------------------------------------------
  // PANEL COMPONENT: Detailed Grading Panel
  // -------------------------------------------------------------
  Widget _buildGradingPanel() {
    if (_viewModel.selectedGroup == null) {
      return _buildRubricOverviewCard();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Highlight active group info
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.star_rounded, color: Colors.amber, size: 22),
                  const SizedBox(width: 6),
                  Text(
                    "Evaluating Group ${_viewModel.selectedGroup!['groupName']}",
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                "Project Title: ${_viewModel.selectedGroup!['projectTitle']}",
                style: TextStyle(color: Colors.grey[700], fontSize: 13, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 4),
              Text(
                "Mid Task Description: ${_viewModel.selectedGroup!['midTaskDescription'] ?? 'None Assigned'}",
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // List individual member grading cards
        if (_viewModel.selectedGroupMembers.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(child: Text("Loading members' enrollment cards...")),
          )
        else ...[
          ..._viewModel.selectedGroupMembers.map((member) {
            return _buildStudentGradingCard(member);
          }),
          const SizedBox(height: 16),
          
          // Submit All Evaluations Button at bottom
          _viewModel.isSavingAll
              ? const Center(child: CircularProgressIndicator())
              : SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _onSubmitAllEvaluations,
                    icon: const Icon(Icons.check_circle_outline, size: 18, color: Colors.white),
                    label: const Text("Submit All Group Evaluations", style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
        ],
      ],
    );
  }

  // Default rubric card overview when no group is selected
  Widget _buildRubricOverviewCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blueAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.collections_bookmark_outlined, color: Colors.blueAccent, size: 28),
              ),
              const SizedBox(width: 14),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Supervisor Mid Evaluation Panel",
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Colors.black87),
                  ),
                  Text(
                    "Select any group on the left to start",
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),
          const Text(
            "Evaluation Workflow Instructions:",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(height: 10),
          _buildBulletPoint("Filter list based on assigned status to search groups."),
          _buildBulletPoint("Tapping a group will pull its student members & mid task details."),
          _buildBulletPoint("Enter marks (0-100) and qualitative remarks for each student."),
          _buildBulletPoint("Save individual student marks or submit the entire group at once."),
        ],
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.brightness_1, size: 6, color: Colors.blueAccent),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 11, color: Colors.grey[700]),
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // PANEL COMPONENT: Student Grading Card
  // -------------------------------------------------------------
  Widget _buildStudentGradingCard(Map<String, dynamic> student) {
    final sName = student['StudentName']?.toString() ?? '';
    
    // Safety check in case controllers were not initialized
    if (!_remarksControllers.containsKey(sName)) {
      _remarksControllers[sName] = TextEditingController();
    }
    if (!_marksControllers.containsKey(sName)) {
      _marksControllers[sName] = TextEditingController();
    }

    final isSavingStudent = _viewModel.savingIndividualMap[sName] == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.01),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name & tech banner
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sName.isEmpty ? 'Unknown Student' : sName,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Colors.blueAccent),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      "Reg ID: ${student['StudentID'] ?? 'N/A'} | CGPA: ${student['currentCGPA'] ?? 'N/A'}",
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              if (student['Tech'] != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    student['Tech'].toString(),
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blue),
                  ),
                ),
            ],
          ),
          const Divider(height: 24),

          // Marks form
          const Text(
            "Mid Evaluation Marks (0 - 100):",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black87),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 38,
            child: TextField(
              controller: _marksControllers[sName],
              keyboardType: TextInputType.number,
              style: const TextStyle(fontSize: 12),
              decoration: InputDecoration(
                hintText: "Enter marks (e.g. 85)",
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Evaluation remarks
          const Text(
            "Evaluation Remarks / Feedback:",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black87),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _remarksControllers[sName],
            maxLines: 2,
            style: const TextStyle(fontSize: 12),
            decoration: InputDecoration(
              hintText: "Type qualitative feedback / evaluation observations...",
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
          const SizedBox(height: 16),

          // Standard Save button
          isSavingStudent
              ? const Center(child: CircularProgressIndicator())
              : SizedBox(
                  width: double.infinity,
                  height: 38,
                  child: ElevatedButton.icon(
                    onPressed: () => _onSaveIndividualStudent(student),
                    icon: const Icon(Icons.save_outlined, size: 16, color: Colors.white),
                    label: const Text("Save Evaluation Marks", style: TextStyle(color: Colors.white, fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}
