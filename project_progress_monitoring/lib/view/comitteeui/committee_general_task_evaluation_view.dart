import 'package:flutter/material.dart';
import '../../viewmodels/comitteeviewmodel/committee_general_task_evaluation_view_model.dart';

// ============================================================================
// WHAT IS THIS FILE?
// This is the "Face" or "View" for the Committee Member's General Task Evaluation screen.
// It allows regular Committee Members to view assigned groups, select them,
// enter subparameter marks, and provide qualitative feedback/remarks.
//
// WHY DOES IT EXIST?
// To provide a dedicated, simplified evaluation workflow for Committee Members without
// exposing Director/Committee Head final grading suites and calculations.
//
// DESIGN PHILOSOPHY (Primary Schooler Style):
// 1. Beautiful Cards: Rounded corners, elegant shadows, and clear status badges.
// 2. Responsive Layout: Side-by-side list and details on wide screens; stack on narrow screens.
// 3. Simple State: Pure setState() state management with straightforward controllers.
// ============================================================================

class CommitteeGeneralTaskEvaluationView extends StatefulWidget {
  // Information of the logged-in user (e.g. id, name, role)
  final Map<String, dynamic> userMap;
  // FYP Type (FYP-1 or FYP-2)
  final String fypType;

  const CommitteeGeneralTaskEvaluationView({
    super.key,
    required this.userMap,
    this.fypType = "FYP-2",
  });

  @override
  State<CommitteeGeneralTaskEvaluationView> createState() => _CommitteeGeneralTaskEvaluationViewState();
}

class _CommitteeGeneralTaskEvaluationViewState extends State<CommitteeGeneralTaskEvaluationView> {
  // 1. Instantiate our "Brain" (ViewModel)
  final CommitteeGeneralTaskEvaluationViewModel _viewModel = CommitteeGeneralTaskEvaluationViewModel();

  // 2. Local State Variables to handle toggle menus and filters
  // _activeMilestone: MidTask or Final Task
  // _activeFilter: unassigned, assigned, evaluated
  // _searchQuery: text entered in the search bar
  String _activeMilestone = "MidTask";
  String _activeFilter = "unassigned";
  String _searchQuery = "";

  // Controllers for editing individual marks & remarks
  // We keep them in state to avoid losing typing focus during rebuilds
  // _marksControllers structure: { studentID: { subParamID: TextEditingController } }
  final Map<String, Map<String, TextEditingController>> _marksControllers = {};
  // _remarksControllers structure: { studentID: TextEditingController }
  final Map<String, TextEditingController> _remarksControllers = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // Helper method to load session, matched parameter, and group information from the server
  Future<void> _loadData() async {
    final role = (widget.userMap['role'] ?? '').toString();
    final name = (widget.userMap['name'] ?? '').toString();
    final id = (widget.userMap['id'] ?? '').toString();

    await _viewModel.fetchSessionAndGroups(
      activeMilestone: _activeMilestone,
      activeFilter: _activeFilter,
      searchQuery: _searchQuery,
      userRole: role,
      userName: name,
      userId: id,
      fypType: widget.fypType,
    );

    if (mounted) setState(() {});
  }

  // Helper method to dispose all text field controllers when screen closes
  @override
  void dispose() {
    _marksControllers.forEach((_, map) {
      map.forEach((_, controller) => controller.dispose());
    });
    _remarksControllers.forEach((_, controller) => controller.dispose());
    super.dispose();
  }

  // Triggers loading group member cards and initializing form controllers
  Future<void> _onSelectGroup(Map<String, dynamic> group) async {
    final myUserId = (widget.userMap['id'] ?? '').toString();
    final myRole = (widget.userMap['role'] ?? '').toString();

    setState(() => _viewModel.isLoading = true);

    await _viewModel.selectGroupAndLoadMembers(group, myUserId, myRole, widget.fypType);

    // Build the text editing controllers for all members
    _marksControllers.clear();
    _remarksControllers.clear();

    for (var m in _viewModel.selectedGroupMembers) {
      final studentId = m['StudentID']?.toString() ?? '';
      if (studentId.isEmpty) continue;

      _marksControllers[studentId] = {};
      _remarksControllers[studentId] = TextEditingController(
        text: _viewModel.remarksInput[studentId] ?? '',
      );

      // Create controllers for each subparameter rubric
      final subParams = _viewModel.activeParameter?['subParameters'] as List? ?? [];
      for (var sp in subParams) {
        final spId = sp['id']?.toString() ?? '';
        final savedVal = _viewModel.marksInput[studentId]?[spId] ?? '';
        _marksControllers[studentId]![spId] = TextEditingController(text: savedVal);
      }
    }

    if (mounted) {
      setState(() => _viewModel.isLoading = false);
    }
  }

  // Triggers post-back for a single student's evaluation marks and remarks
  Future<void> _onSaveIndividualStudent(Map<String, dynamic> member) async {
    final studentId = member['StudentID']?.toString() ?? '';
    final myUserId = (widget.userMap['id'] ?? '').toString();
    final myRole = (widget.userMap['role'] ?? '').toString();

    // Copy controller values to our ViewModel inputs
    _remarksInputCopier(studentId);

    // Save individual marks
    setState(() => _viewModel.savingIndividualMap[studentId] = true);

    final errorMsg = await _viewModel.saveIndividualEvaluation(
      member: member,
      userId: myUserId,
      userRole: myRole,
      activeMilestone: _activeMilestone,
      fypType: widget.fypType,
    );

    if (mounted) {
      setState(() => _viewModel.savingIndividualMap[studentId] = false);
      if (errorMsg != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg), backgroundColor: Colors.redAccent),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Evaluation marks saved successfully for ${member['StudentName']}! ✅"),
            backgroundColor: Colors.green,
          ),
        );
        _loadData(); // Refresh list to update evaluated counts
      }
    }
  }

  // Copies text from controllers into the ViewModel maps
  void _remarksInputCopier(String studentId) {
    if (!_viewModel.marksInput.containsKey(studentId)) {
      _viewModel.marksInput[studentId] = {};
    }
    _marksControllers[studentId]?.forEach((spId, ctrl) {
      _viewModel.marksInput[studentId]![spId] = ctrl.text.trim();
    });
    _viewModel.remarksInput[studentId] = _remarksControllers[studentId]?.text.trim() ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Committee Task Evaluation (${widget.fypType})',
          style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18),
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
              // 1. Top Controls Bar (Milestone Buttons + Search)
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
  // TOP BAR: Milestone Buttons & Search Bar
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
          Row(
            children: [
              Expanded(
                child: _buildMilestoneButton("MidTask", "MidTask Evaluation"),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMilestoneButton("FinalTask", "Final Task Evaluation"),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            decoration: InputDecoration(
              hintText: "Search by Group ID, Project Name, or Supervisor...",
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

  Widget _buildMilestoneButton(String milestoneKey, String label) {
    final bool isSel = _activeMilestone == milestoneKey;
    return ElevatedButton(
      onPressed: () {
        setState(() {
          _activeMilestone = milestoneKey;
          _viewModel.selectedGroup = null;
        });
        _loadData();
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isSel ? Colors.deepPurple : Colors.grey.shade100,
        foregroundColor: isSel ? Colors.white : Colors.black87,
        elevation: isSel ? 2 : 0,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
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
                "No groups match the current milestone toggle and filter.",
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
              color: isSel ? Colors.deepPurple.withValues(alpha: 0.05) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSel ? Colors.deepPurple : Colors.grey.shade200,
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
                        const Icon(Icons.school_outlined, size: 14, color: Colors.deepPurple),
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
                "Primary Supervisor: ${_viewModel.selectedGroup!['supervisor'] ?? 'None Assigned'}",
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Mapped Criteria rubric outline
        if (_viewModel.activeParameter != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.deepPurple.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.deepPurple.withValues(alpha: 0.2)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${_viewModel.activeParameter!['name']} Rubric Active",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.deepPurple),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      "Weightage value: ${_viewModel.activeParameter!['percentage']}%",
                      style: TextStyle(fontSize: 11, color: Colors.grey[700]),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.deepPurple.withValues(alpha: 0.2)),
                  ),
                  child: Text(
                    "${(_viewModel.activeParameter!['subParameters'] as List?)?.length ?? 0} Parameters",
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.deepPurple),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 24),

        // List individual member grading cards
        if (_viewModel.selectedGroupMembers.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(child: Text("Loading members' enrollment cards...")),
          )
        else
          ..._viewModel.selectedGroupMembers.map((member) {
            return _buildStudentGradingCard(member);
          }),
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
                  color: Colors.deepPurple.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.collections_bookmark_outlined, color: Colors.deepPurple, size: 28),
              ),
              const SizedBox(width: 14),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Committee Evaluation Panel",
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
          _buildBulletPoint("Select appropriate milestone (MidTask vs Final Task) on top."),
          _buildBulletPoint("Filter list based on assigned status to search groups."),
          _buildBulletPoint("Tapping a group will pull its detailed criteria rubrics & subparameters."),
          _buildBulletPoint("Enter marks and qualitative remarks for each student and save."),

          const SizedBox(height: 24),
          if (_viewModel.activeParameter != null) ...[
            const Text(
              "Active criteria rubric settings:",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.deepPurple),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Rubric Title: ${_viewModel.activeParameter!['name']}",
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Rubric Weightage: ${_viewModel.activeParameter!['percentage']}%",
                    style: TextStyle(fontSize: 11, color: Colors.grey[700]),
                  ),
                  const Divider(height: 16),
                  const Text(
                    "Sub-Parameters Details:",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey),
                  ),
                  const SizedBox(height: 6),
                  ...(_viewModel.activeParameter!['subParameters'] as List? ?? []).map((sub) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4.0),
                      child: Text(
                        "• ${sub['name']} (${sub['percentage']}%)",
                        style: const TextStyle(fontSize: 11),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
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
          const Icon(Icons.brightness_1, size: 6, color: Colors.deepPurple),
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
    final studentId = student['StudentID']?.toString() ?? '';
    final subParams = _viewModel.activeParameter?['subParameters'] as List? ?? [];
    
    // Safety check in case controllers were not initialized
    if (!_remarksControllers.containsKey(studentId)) {
      _remarksControllers[studentId] = TextEditingController();
    }
    if (!_marksControllers.containsKey(studentId)) {
      _marksControllers[studentId] = {};
    }
    for (var sp in subParams) {
      final spId = sp['id']?.toString() ?? '';
      if (!_marksControllers[studentId]!.containsKey(spId)) {
        _marksControllers[studentId]![spId] = TextEditingController();
      }
    }

    final isSavingStudent = _viewModel.savingIndividualMap[studentId] == true;

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
                      student['StudentName'] ?? 'Unknown Student',
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Colors.deepPurple),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      "Reg ID: $studentId | CGPA: ${student['currentCGPA'] ?? 'N/A'}",
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

          // Subparameter marks forms
          const Text(
            "Subparameter Rubric Scores:",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black87),
          ),
          const SizedBox(height: 12),
          
          if (subParams.isEmpty)
            const Text(
              "No subparameters mapped for this parameter rubric.",
              style: TextStyle(fontSize: 11, color: Colors.grey),
            )
          else
            ...subParams.map((sp) {
              final spId = sp['id']?.toString() ?? '';
              final maxMarks = sp['percentage']?.toString() ?? '100';

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Expanded(
                      flex: 6,
                      child: Text(
                        "${sp['name']} (Max: $maxMarks)",
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    ),
                    Expanded(
                      flex: 4,
                      child: SizedBox(
                        height: 36,
                        child: TextField(
                          controller: _marksControllers[studentId]![spId],
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: const TextStyle(fontSize: 12),
                          decoration: InputDecoration(
                            hintText: "Obtained",
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          const SizedBox(height: 16),

          // Evaluation remarks
          const Text(
            "Evaluation Remarks:",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black87),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _remarksControllers[studentId],
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
                      backgroundColor: Colors.deepPurple,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}
