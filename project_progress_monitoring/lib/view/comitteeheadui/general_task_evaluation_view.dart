import 'package:flutter/material.dart';
import '../../viewmodels/comitteeheadviewmodel/general_task_evaluation_viewmodel.dart';

// ============================================================================
// WHAT IS THIS FILE?
// This is the "Face" or "View" of our General Task Evaluation Dashboard!
// It supports all three roles: Supervisor, Committee Member, and Committee Head (Director).
//
// DESIGN PHILOSOPHY (Primary Schooler Style):
// 1. Beautiful Cards: Everything has rounded corners, elegant shadows, and colorful icons.
// 2. Double-pane responsive layout: On wide screens (tablets/desktops), it shows the list on the
//    left and details on the right. On narrow screens (phones), selecting a group transitions
//    to a detailed full-screen modal or detailed view.
// 3. Super easy explanations: All functions, controllers, and visual components are documented
//    extensively to make it a breeze for beginners to read!
// ============================================================================

class GeneralTaskEvaluationView extends StatefulWidget {
  // Information of the logged-in user
  final Map<String, dynamic> userMap;
  final String fypType; // FYP-1 or FYP-2

  const GeneralTaskEvaluationView({super.key, required this.userMap, this.fypType = "FYP-2"});

  @override
  State<GeneralTaskEvaluationView> createState() => _GeneralTaskEvaluationViewState();
}

class _GeneralTaskEvaluationViewState extends State<GeneralTaskEvaluationView> {
  // 1. Instantiate our "Brain" (ViewModel)
  final GeneralTaskEvaluationViewModel _viewModel = GeneralTaskEvaluationViewModel();

  // 2. Local State Variables to handle toggle menus
  String _activeMilestone = "MidTask"; // Can be: MidTask or Final Task
  String _activeFilter = "unassigned";   // Can be: unassigned, assigned, evaluated
  String _searchQuery = "";

  // Controllers for editing individual marks & remarks
  // We keep them in state to avoid losing typing focus
  final Map<String, Map<String, TextEditingController>> _marksControllers = {};
  final Map<String, TextEditingController> _remarksControllers = {};

  // Controllers for custom final score overrides (Director suite)
  final Map<String, TextEditingController> _finalScoreControllers = {};
  final Map<String, TextEditingController> _finalGradeControllers = {};

  // Grades selected for each student dropdown (Director suite)
  final Map<String, String> _selectedGrades = {};
  final List<String> _gradesList = ["A+", "A", "A-", "B+", "B", "B-", "C+", "C", "C-", "D+", "D", "F"];

  @override
  void initState() {
    super.initState();
    
    // If user is Supervisor, they can ONLY evaluate MidTask as per React logic
    final role = (widget.userMap['role'] ?? '').toString().toLowerCase();
    if (role == "supervisor") {
      _activeMilestone = "MidTask";
    }

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

  // Helper method to dispose all text field controllers
  @override
  void dispose() {
    _marksControllers.forEach((_, map) {
      map.forEach((_, controller) => controller.dispose());
    });
    _remarksControllers.forEach((_, controller) => controller.dispose());
    _finalScoreControllers.forEach((_, controller) => controller.dispose());
    _finalGradeControllers.forEach((_, controller) => controller.dispose());
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
    _finalScoreControllers.clear();
    _finalGradeControllers.clear();

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

      // Final score controllers (Director)
      _finalScoreControllers[studentId] = TextEditingController();
      _finalGradeControllers[studentId] = TextEditingController();

      // Prefill Grade in dropdown state
      final existingGrade = (m['Grade'] ?? '').toString().trim();
      _selectedGrades[studentId] = _gradesList.contains(existingGrade) ? existingGrade : 'F';
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
    final error = await _viewModel.saveIndividualEvaluation(
      member: member,
      userId: myUserId,
      userRole: myRole,
      activeMilestone: _activeMilestone,
      fypType: widget.fypType,
    );

    if (!mounted) return;

    if (error != null) {
      // Show warning/error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("⚠️ $error"),
          backgroundColor: Colors.redAccent,
        ),
      );
    } else {
      // Success toast!
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("🎉 Saved evaluation marks for ${member['StudentName']} successfully!"),
          backgroundColor: const Color(0xFF10B981),
        ),
      );
      // Reload parent lists to update counts/badges
      await _loadData();
    }
  }

  // Director: calculate score for student
  Future<void> _onCalculateScore(Map<String, dynamic> student) async {
    final studentId = student['StudentID']?.toString() ?? '';
    final resultMsg = await _viewModel.calculateIndividualScore(student, widget.fypType);

    if (!mounted) return;

    if (resultMsg != null) {
      final scoreVal = _viewModel.calculatedScores[studentId]?['score']?.toString() ?? '';
      final gradeVal = _viewModel.calculatedScores[studentId]?['grade']?.toString() ?? '';

      _finalScoreControllers[studentId]?.text = scoreVal;
      _finalGradeControllers[studentId]?.text = gradeVal;

      final cleanGrade = gradeVal.trim();
      if (_gradesList.contains(cleanGrade)) {
        _selectedGrades[studentId] = cleanGrade;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("📐 Calculated: $resultMsg"),
          backgroundColor: Colors.blueAccent,
        ),
      );
      setState(() {});
    }
  }

  // Director: save final grade
  Future<void> _onSaveFinalGrade(Map<String, dynamic> student) async {
    final studentId = student['StudentID']?.toString() ?? '';
    final myUserId = (widget.userMap['id'] ?? '').toString();

    final typedScore = _finalScoreControllers[studentId]?.text.trim() ?? '';
    final typedGrade = _selectedGrades[studentId] ?? '';

    if (typedScore.isNotEmpty || typedGrade.isNotEmpty) {
      _viewModel.finalGrades[studentId] = {
        "score": typedScore,
        "grade": typedGrade,
      };
    }

    final error = await _viewModel.saveIndividualFinalGrade(
      student: student,
      userId: myUserId,
      fypType: widget.fypType,
    );

    if (!mounted) return;

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("⚠️ $error"),
          backgroundColor: Colors.redAccent,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("✅ Final grade for ${student['StudentName']} committed successfully!"),
          backgroundColor: Colors.teal,
        ),
      );
      await _loadData();
    }
  }

  // Helper method to copy typed values from controllers into ViewModel input structures
  void _remarksInputCopier(String studentId) {
    if (_remarksControllers.containsKey(studentId)) {
      _viewModel.remarksInput[studentId] = _remarksControllers[studentId]!.text;
    }
    
    final subParams = _viewModel.activeParameter?['subParameters'] as List? ?? [];
    if (_viewModel.marksInput[studentId] == null) {
      _viewModel.marksInput[studentId] = {};
    }
    for (var sp in subParams) {
      final spId = sp['id']?.toString() ?? '';
      if (_marksControllers[studentId]?.containsKey(spId) ?? false) {
        _viewModel.marksInput[studentId]![spId] = _marksControllers[studentId]![spId]!.text;
      }
    }
  }

  // -------------------------------------------------------------
  // BUILD WORKFLOW
  // -------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 900;
    final role = (widget.userMap['role'] ?? '').toString().toLowerCase();
    final isSupervisor = role == "supervisor";

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          "General Task Evaluation",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Column(
        children: [
          // 1. Top Settings row (milestones & search)
          _buildTopSettingsPanel(isSupervisor),
          
          // 2. Filter status rows
          _buildFilterBadgesRow(),

          // 3. Body layout (responsive dual pane vs mobile switch)
          Expanded(
            child: _viewModel.isLoading
                ? _buildProgressSpinner()
                : (isMobile 
                    ? _buildMobileLayout() 
                    : _buildDesktopLayout()),
          ),
        ],
      ),
    );
  }

  // Loading indicator with explanatory texts
  Widget _buildProgressSpinner() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: Colors.deepPurple),
          const SizedBox(height: 16),
          Text(
            "Fetching FYP-2 groups & criteria parameters...",
            style: TextStyle(color: Colors.grey[700], fontSize: 14, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Text(
            "Building grading cards and rubrics on-the-fly...",
            style: TextStyle(color: Colors.grey[400], fontSize: 12),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // PANEL COMPONENT: Top Panel (Milestones & Search)
  // -------------------------------------------------------------
  Widget _buildTopSettingsPanel(bool isSupervisorRestricted) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Milestone Toggle Pill Row
          Expanded(
            flex: 6,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildMilestonePill("MidTask", "MidTask Evaluation"),
                  const SizedBox(width: 8),
                  // React rule: Supervisors are strictly restricted to MidTask only
                  if (!isSupervisorRestricted)
                    _buildMilestonePill("FinalTask", "Final Task Evaluation"),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Search Field
          Expanded(
            flex: 4,
            child: TextField(
              decoration: InputDecoration(
                hintText: "Search group, project...",
                hintStyle: const TextStyle(fontSize: 12),
                prefixIcon: const Icon(Icons.search, size: 18),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                fillColor: Colors.grey[50],
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
              ),
              onChanged: (val) {
                setState(() {
                  _searchQuery = val;
                  _viewModel.applyFilters(_activeFilter, _searchQuery);
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMilestonePill(String key, String label) {
    final isSelected = _activeMilestone == key;
    return GestureDetector(
      onTap: () {
        setState(() {
          _activeMilestone = key;
          _viewModel.selectedGroup = null;
        });
        _loadData();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.deepPurple : Colors.grey[100],
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isSelected ? Colors.deepPurple : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // PANEL COMPONENT: Filter status count row
  // -------------------------------------------------------------
  Widget _buildFilterBadgesRow() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterButton(
              key: "unassigned",
              label: "Unassigned Tasks",
              color: Colors.redAccent,
              icon: Icons.assignment_late_outlined,
            ),
            const SizedBox(width: 8),
            _buildFilterButton(
              key: "assigned",
              label: "Assigned Tasks",
              color: Colors.amber.shade700,
              icon: Icons.play_circle_outline,
            ),
            const SizedBox(width: 8),
            _buildFilterButton(
              key: "evaluated",
              label: "Evaluated Milestones",
              color: const Color(0xFF10B981),
              icon: Icons.check_circle_outline,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterButton({
    required String key,
    required String label,
    required Color color,
    required IconData icon,
  }) {
    final isSelected = _activeFilter == key;
    return GestureDetector(
      onTap: () {
        setState(() {
          _activeFilter = key;
          _viewModel.selectedGroup = null;
          _viewModel.applyFilters(_activeFilter, _searchQuery);
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.1) : Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color.withValues(alpha: 0.4) : Colors.grey.shade200,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: isSelected ? color : Colors.grey[600]),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isSelected ? color : Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // LAYOUT WORKFLOWS: Responsive layouts
  // -------------------------------------------------------------
  Widget _buildDesktopLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // LEFT COL: Group listing
        Expanded(
          flex: 4,
          child: _buildGroupListContainer(),
        ),
        // RIGHT COL: Detailed grading card
        Expanded(
          flex: 6,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: _buildGradingPanel(),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    // If group is selected, show details. Otherwise show group list.
    if (_viewModel.selectedGroup != null) {
      return WillPopScope(
        onWillPop: () async {
          setState(() => _viewModel.selectedGroup = null);
          return false;
        },
        child: Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => setState(() => _viewModel.selectedGroup = null),
            ),
            title: Text("Group ${_viewModel.selectedGroup!['groupName']}"),
            backgroundColor: Colors.white,
            elevation: 0.5,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: _buildGradingPanel(),
          ),
        ),
      );
    }

    return _buildGroupListContainer();
  }

  // -------------------------------------------------------------
  // PANEL COMPONENT: Group listing builder
  // -------------------------------------------------------------
  Widget _buildGroupListContainer() {
    if (_viewModel.filteredGroups.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.group_off_outlined, size: 50, color: Colors.grey[400]),
            const SizedBox(height: 12),
            const Text(
              "No Groups Found",
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 6),
            Text(
              "There are no FYP-2 groups in this filter status.",
              style: TextStyle(color: Colors.grey[500], fontSize: 11),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _viewModel.filteredGroups.length,
      itemBuilder: (context, index) {
        final g = _viewModel.filteredGroups[index];
        final isSelected = _viewModel.selectedGroup?['groupName'] == g['groupName'];

        return GestureDetector(
          onTap: () => _onSelectGroup(g),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected ? Colors.deepPurple.withValues(alpha: 0.03) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? Colors.deepPurple : Colors.grey.shade200,
                width: isSelected ? 1.8 : 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Group ${g['groupName']}",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatusBadgeColor(g['evaluationStatus']).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Text(
                        (g['evaluationStatus'] ?? '').toString().toUpperCase(),
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: _getStatusBadgeColor(g['evaluationStatus']),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  g['projectTitle'] ?? 'No Project Assigned',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const Divider(height: 20),
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

    final role = (widget.userMap['role'] ?? '').toString().toLowerCase();
    final isDirector = role == "director" || role == "committeehead";

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
            return _buildStudentGradingCard(member, isDirector);
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
                    "FYP-2 Evaluation panel",
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
          _buildBulletPoint("Director/Committee Head can calculate & save final grades using the Director grading suite."),

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
  // PANEL COMPONENT: Student Grading card
  // -------------------------------------------------------------
  Widget _buildStudentGradingCard(Map<String, dynamic> student, bool isDirector) {
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
          
          // ==================================================================
          // DIRECTOR GRADING SUITE SECTION
          // ==================================================================
          if (isDirector) ...[
            const Divider(height: 32),
            _buildDirectorGradingSuite(student),
          ],
        ],
      ),
    );
  }

  // Builds the Director Special suite section
  Widget _buildDirectorGradingSuite(Map<String, dynamic> student) {
    final studentId = student['StudentID']?.toString() ?? '';
    final enrollmentId = student['EnrollmentID']?.toString() ?? '';

    if (!_finalScoreControllers.containsKey(studentId)) {
      _finalScoreControllers[studentId] = TextEditingController();
    }
    if (!_finalGradeControllers.containsKey(studentId)) {
      _finalGradeControllers[studentId] = TextEditingController();
    }

    final isExpandedHistory = _viewModel.expandedHistoryMap[enrollmentId] == true;
    final isLoadingHistory = _viewModel.loadingHistoryMap[enrollmentId] == true;
    final isCalculating = _viewModel.calculatingIndividualMap[studentId] == true;
    final isSavingGrade = _viewModel.savingGradeIndividualMap[studentId] == true;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.admin_panel_settings_outlined, color: Colors.blue, size: 20),
              const SizedBox(width: 6),
              const Text(
                "Director Final Grading Suite",
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Colors.blue),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 1. History Logs Button
          OutlinedButton.icon(
            onPressed: () {
              _viewModel.toggleHistory(student, widget.fypType);
              setState(() {});
            },
            icon: Icon(
              isExpandedHistory ? Icons.expand_less : Icons.history_edu_outlined,
              size: 14,
              color: Colors.blue,
            ),
            label: Text(
              isExpandedHistory ? "Collapse History Logs" : "View Student Evaluation History Logs",
              style: const TextStyle(fontSize: 11, color: Colors.blue),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.blue),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              minimumSize: const Size(double.infinity, 32),
            ),
          ),
          
          // History Expanded Log Display
          if (isExpandedHistory) ...[
            const SizedBox(height: 10),
            if (isLoadingHistory)
              const Center(child: Padding(
                padding: EdgeInsets.all(8.0),
                child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
              ))
            else if (_viewModel.historyData[enrollmentId]?.isEmpty ?? true)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 6.0),
                child: Text("No qualitative evaluation logs found from other panels.", style: TextStyle(fontSize: 10, color: Colors.grey)),
              )
            else
              Column(
                children: _viewModel.historyData[enrollmentId]!.map<Widget>((log) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade100),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Role/Evaluator: ${log['Evaluator'] ?? 'Evaluator'}",
                              style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.black87),
                            ),
                            Text(
                              (log['Date'] ?? '').toString().split('T')[0],
                              style: const TextStyle(fontSize: 8, color: Colors.grey),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          log['Remarks']?.toString() ?? '',
                          style: TextStyle(fontSize: 10, color: Colors.grey[700]),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
          ],
          
          const Divider(height: 20),

          // 2. include supervisor scores checkbox
          Row(
            children: [
              SizedBox(
                height: 24,
                width: 24,
                child: Checkbox(
                  value: _viewModel.includeSupervisorScore,
                  onChanged: (val) {
                    setState(() {
                      _viewModel.includeSupervisorScore = val ?? false;
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  "Include Supervisor Task score in calculations (80% / 20%)",
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.black87),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 3. Trigger Calculation Button
          isCalculating
              ? const Center(child: CircularProgressIndicator())
              : SizedBox(
                  width: double.infinity,
                  height: 34,
                  child: ElevatedButton.icon(
                    onPressed: () => _onCalculateScore(student),
                    icon: const Icon(Icons.calculate_outlined, size: 14, color: Colors.white),
                    label: const Text("Calculate Final Score & Grade", style: TextStyle(color: Colors.white, fontSize: 11)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
          const SizedBox(height: 14),

          // 4. Score overrides forms
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _finalScoreControllers[studentId],
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: "Final Score",
                    labelStyle: TextStyle(fontSize: 11),
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    border: OutlineInputBorder(),
                  ),
                  style: const TextStyle(fontSize: 11),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedGrades[studentId],
                  items: _gradesList.map((grade) {
                    return DropdownMenuItem<String>(
                      value: grade,
                      child: Text(grade, style: const TextStyle(fontSize: 11)),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedGrades[studentId] = val;
                        _viewModel.finalGrades[studentId] ??= {};
                        _viewModel.finalGrades[studentId]!['grade'] = val;
                      });
                    }
                  },
                  decoration: const InputDecoration(
                    labelText: "Final Grade",
                    labelStyle: TextStyle(fontSize: 11),
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    border: OutlineInputBorder(),
                  ),
                  style: const TextStyle(fontSize: 11, color: Colors.black87),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 5. Commit Grade Button
          isSavingGrade
              ? const Center(child: CircularProgressIndicator())
              : SizedBox(
                  width: double.infinity,
                  height: 34,
                  child: ElevatedButton.icon(
                    onPressed: () => _onSaveFinalGrade(student),
                    icon: const Icon(Icons.check_circle, size: 14, color: Colors.white),
                    label: const Text("Commit Final Grade to Database", style: TextStyle(color: Colors.white, fontSize: 11)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}
