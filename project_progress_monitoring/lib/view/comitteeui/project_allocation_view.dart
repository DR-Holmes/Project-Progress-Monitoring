import 'package:flutter/material.dart';
import '../../viewmodels/comitteeviewmodel/project_allocation_viewmodel.dart';

// ---------------------------------------------------------
// WHAT IS THIS FILE?
// This is the "View" (UI Screen) for Project Allocation (Committee Member).
// It has:
// - A toggle to filter groups by FYP-1 / FYP-2.
// - An interactive Group Dropdown (or pre-selected group if deep-linked).
// - Dynamic Student Members Details display.
// - An offered projects discovery list with categories filter and text search.
// - A submission flow to allocate a project using PUT.
// ---------------------------------------------------------

class ProjectAllocationView extends StatefulWidget {
  final int? initialGroupId;
  final int? initialMeetingId;

  const ProjectAllocationView({
    Key? key,
    this.initialGroupId,
    this.initialMeetingId,
  }) : super(key: key);

  @override
  State<ProjectAllocationView> createState() => _ProjectAllocationViewState();
}

class _ProjectAllocationViewState extends State<ProjectAllocationView> {
  // 1. Instantiate our Brain (ViewModel)
  final ProjectAllocationViewModel _viewModel = ProjectAllocationViewModel();

  // 2. Local State Variables
  String _activeFYP = "FYP-1"; // Default semester toggle
  String _selectedCategory = "All"; // Active project category tab
  String _searchText = ""; // User typed search query
  
  // 3. Controllers
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _remarksController = TextEditingController();

  // 4. Offered categories
  final List<String> _categories = ["All", "Healthcare", "Education", "IoT", "Security"];

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  // ---------------------------------------------------------
  // FUNCTION: _initializeData
  // Loads all relevant items from the backend APIs.
  // ---------------------------------------------------------
  Future<void> _initializeData() async {
    setState(() => _viewModel.isLoading = true);

    // Fetch projects
    await _viewModel.fetchOfferedProjects();

    // If deep-linked (pre-selected group), fetch its members directly
    if (widget.initialGroupId != null) {
      _viewModel.selectedGroupId = widget.initialGroupId.toString();
      await _viewModel.fetchSpecificGroupMembers(_viewModel.selectedGroupId!);
    } else {
      // Load groups dropdown list for active FYP type
      await _viewModel.fetchEnrolledGroups(_activeFYP);
    }

    setState(() => _viewModel.isLoading = false);
  }

  // ---------------------------------------------------------
  // FUNCTION: _switchFYP
  // Switches between FYP-1 and FYP-2 groups.
  // ---------------------------------------------------------
  void _switchFYP(String type) async {
    if (_activeFYP == type) return;
    setState(() {
      _activeFYP = type;
      _viewModel.selectedGroupId = null;
      _viewModel.groupMembers = [];
    });
    setState(() => _viewModel.isLoading = true);
    await _viewModel.fetchEnrolledGroups(type);
    setState(() => _viewModel.isLoading = false);
  }

  // ---------------------------------------------------------
  // FUNCTION: _onGroupSelected
  // Loads members cards automatically when group is chosen.
  // ---------------------------------------------------------
  void _onGroupSelected(String? groupId) async {
    if (groupId == null) return;
    setState(() {
      _viewModel.selectedGroupId = groupId;
    });
    await _viewModel.fetchSpecificGroupMembers(groupId);
    setState(() {});
  }

  // ---------------------------------------------------------
  // FUNCTION: _handleAllocationSubmit
  // Save Project Allocation via PUT api request.
  // ---------------------------------------------------------
  void _handleAllocationSubmit() async {
    if (_viewModel.selectedGroupId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ Please select a Student Group first.")),
      );
      return;
    }

    if (_viewModel.selectedProjectId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ Please select a Project from the offered panel.")),
      );
      return;
    }

    final success = await _viewModel.allocateProjectToGroup(
      _viewModel.selectedGroupId!,
      int.parse(_viewModel.selectedProjectId!),
    );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("✅ Project allocated successfully!"),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Return to caller with success flag
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("❌ Failed to allocate project. Try again."),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // ---------------------------------------------------------
    // DYNAMIC FILTERING LOGIC
    // Filters projects based on the selected category tab and search text.
    // ---------------------------------------------------------
    List<dynamic> filteredProjects = _viewModel.projects.where((p) {
      final title = (p['Title'] ?? '').toString().toLowerCase();
      final objectives = (p['Objectives'] ?? '').toString().toLowerCase();
      final matchSearch = title.contains(_searchText.toLowerCase()) || 
                          objectives.contains(_searchText.toLowerCase());

      // If category is "All", only search match is required.
      if (_selectedCategory == "All") return matchSearch;

      // Otherwise match specific category scope
      final isCategoryMatch = title.contains(_selectedCategory.toLowerCase()) ||
                              objectives.contains(_selectedCategory.toLowerCase());
      return matchSearch && isCategoryMatch;
    }).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Project Allocation", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _viewModel.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Top Scrollable Form Body
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Semester Switch Toggle Row (Only visible if NOT deep-linked)
                        if (widget.initialGroupId == null) ...[
                          Row(
                            children: [
                              _fypToggleButton("FYP-1"),
                              const SizedBox(width: 10),
                              _fypToggleButton("FYP-2"),
                            ],
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Step 1: Select Group Section
                        const Text(
                          "Select Student Group",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
                        ),
                        const SizedBox(height: 8),

                        widget.initialGroupId != null
                            ? Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.grey.shade300),
                                ),
                                child: Text(
                                  "Selected Group: ${widget.initialGroupId}",
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.blue),
                                ),
                              )
                            : Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey.shade300),
                                  borderRadius: BorderRadius.circular(10),
                                  color: Colors.grey.shade50,
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    isExpanded: true,
                                    hint: Text("Select from $_activeFYP groups"),
                                    value: _viewModel.selectedGroupId,
                                    items: _viewModel.groups.map((g) {
                                      final idVal = g['groupName'] ?? g['GroupID'] ?? g['id'];
                                      final membersList = g['members'] as List?;
                                      final membersText = membersList != null ? membersList.join(', ') : '';
                                      return DropdownMenuItem<String>(
                                        value: idVal.toString(),
                                        child: Text("Group $idVal ($membersText)"),
                                      );
                                    }).toList(),
                                    onChanged: _onGroupSelected,
                                  ),
                                ),
                              ),
                        const SizedBox(height: 20),

                        // Render Group Members details
                        if (_viewModel.isMembersLoading) ...[
                          const Center(child: Padding(
                            padding: EdgeInsets.all(20.0),
                            child: CircularProgressIndicator(),
                          )),
                        ] else if (_viewModel.groupMembers.isNotEmpty) ...[
                          const Text(
                            "Team Members",
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
                          ),
                          const SizedBox(height: 8),
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _viewModel.groupMembers.length,
                            itemBuilder: (context, idx) {
                              final student = _viewModel.groupMembers[idx];
                              return _buildMemberCard(student);
                            },
                          ),
                          const SizedBox(height: 20),
                        ],

                        // Step 2: Offered Projects Panel (Search, Category, Discovery List)
                        const Divider(height: 30),
                        const Text(
                          "Offered Projects Discovery Panel",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black),
                        ),
                        const SizedBox(height: 12),

                        // Search Text Field
                        TextField(
                          controller: _searchController,
                          onChanged: (val) {
                            setState(() => _searchText = val);
                          },
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.search, color: Colors.grey, size: 20),
                            hintText: "Search offered projects...",
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: Colors.grey.shade200),
                            ),
                          ),
                          style: const TextStyle(fontSize: 13),
                        ),
                        const SizedBox(height: 12),

                        // Category Filtering Tabs
                        SizedBox(
                          height: 36,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _categories.length,
                            itemBuilder: (context, idx) {
                              final catName = _categories[idx];
                              final isSelected = _selectedCategory == catName;
                              return GestureDetector(
                                onTap: () {
                                  setState(() => _selectedCategory = catName);
                                },
                                child: Container(
                                  margin: const EdgeInsets.only(right: 8),
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  decoration: BoxDecoration(
                                    color: isSelected ? Colors.blue : Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: isSelected ? Colors.blue : Colors.grey.shade300),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    catName,
                                    style: TextStyle(
                                      color: isSelected ? Colors.white : Colors.black87,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Discoverable Project list
                        if (filteredProjects.isEmpty) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 40),
                            alignment: Alignment.center,
                            child: Text(
                              "No matching projects found.",
                              style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                            ),
                          ),
                        ] else ...[
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: filteredProjects.length,
                            itemBuilder: (context, idx) {
                              final project = filteredProjects[idx];
                              final projId = (project['ProjectId'] ?? project['id']).toString();
                              final isSelected = _viewModel.selectedProjectId == projId;
                              return _buildProjectCard(project, isSelected, projId);
                            },
                          ),
                        ],

                        // Step 3: Optional Remarks Text Box
                        const SizedBox(height: 20),
                        const Text(
                          "Optional Objectives / Remarks",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _remarksController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            hintText: "Add specific instructions, objectives or requirements for this allocation...",
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: Colors.grey.shade200),
                            ),
                          ),
                          style: const TextStyle(fontSize: 13),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),

                // Absolute Sticky Bottom Action Button
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -2)),
                    ],
                    border: Border(top: BorderSide(color: Colors.grey.shade200)),
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                      onPressed: _viewModel.isSubmitting ? null : _handleAllocationSubmit,
                      child: _viewModel.isSubmitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Text(
                              "Allocate Selected Project",
                              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13),
                            ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  // Helper Toggle button for Semester filtering
  Widget _fypToggleButton(String label) {
    final isActive = _activeFYP == label;
    return Expanded(
      child: GestureDetector(
        onTap: () => _switchFYP(label),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? Colors.blue : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isActive ? Colors.blue : Colors.grey.shade300),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: isActive ? Colors.white : Colors.grey.shade700,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  // Student Member Details Card builder
  Widget _buildMemberCard(Map<String, dynamic> student) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.01), blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Name and Registration Number
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student['studentName'] ?? 'Unknown Name',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  student['studentID'] ?? student['regNum'] ?? '',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                ),
              ],
            ),
          ),

          // Tech & CGPA values
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  student['Tech'] ?? 'N/A',
                  style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 10),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "CGPA: ${student['currentCGPA'] ?? 'N/A'}",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.black87),
              ),
            ],
          )
        ],
      ),
    );
  }

  // Discovery Project Card builder
  Widget _buildProjectCard(Map<String, dynamic> project, bool isSelected, String projId) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _viewModel.selectedProjectId = projId;
          _viewModel.selectedProjectTitle = project['Title'] ?? '';
          _remarksController.text = project['Objectives'] ?? '';
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.shade50 : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isSelected ? Colors.blue : Colors.grey.shade200, width: isSelected ? 1.5 : 1.0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    project['Title'] ?? 'Untitled Project Idea',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: isSelected ? Colors.blue.shade900 : Colors.black87,
                    ),
                  ),
                ),
                if (isSelected) const Icon(Icons.check_circle, color: Colors.blue, size: 20),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              project['Objectives'] ?? 'No scope details loaded.',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}