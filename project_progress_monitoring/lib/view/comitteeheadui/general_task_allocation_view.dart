import 'package:flutter/material.dart';
import '../../viewmodels/comitteeheadviewmodel/general_task_allocation_viewmodel.dart';

// ============================================================================
// GENERAL TASK ALLOCATION DASHBOARD VIEW (The Face / UI)
// ============================================================================
// What is this file?
// This is the "View" (the screen) where the Committee Head can assign tasks
// (MidTask and Final Task descriptions) to FYP-2 approved groups.
//
// Features:
// 1. Milestone Toggle: Switch between MidTask and Final Task modes.
// 2. Status Filters: View Unassigned vs. Assigned groups easily.
// 3. Live Search: Find groups by ID, Project Name, or Supervisor name instantly.
// 4. Detail Panel: Tap a group to view its members, supervisor, and project title.
// 5. Rich Task Input: An elegant multi-line field to type/edit task descriptions.
// 6. Beginner-Friendly: Highly commented, standard widgets only, simple setState!
// ============================================================================

class GeneralTaskAllocationDashboardView extends StatefulWidget {
  const GeneralTaskAllocationDashboardView({super.key});

  @override
  State<GeneralTaskAllocationDashboardView> createState() => _GeneralTaskAllocationDashboardViewState();
}

class _GeneralTaskAllocationDashboardViewState extends State<GeneralTaskAllocationDashboardView> {
  // -------------------------------------------------------------
  // VIEW MODEL INSTANCE (The Brain)
  // -------------------------------------------------------------
  final GeneralTaskAllocationViewModel _viewModel = GeneralTaskAllocationViewModel();

  // A controller to update the text box when the user selects a group!
  final TextEditingController _taskTextController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Fetch all the groups when the screen is opened
    _fetchAndRefresh();
  }

  @override
  void dispose() {
    _taskTextController.dispose();
    super.dispose();
  }

  // Helper method to load data and refresh the UI screen
  Future<void> _fetchAndRefresh() async {
    setState(() => _viewModel.isLoading = true);
    await _viewModel.fetchGroups();
    if (mounted) {
      setState(() {});
    }
  }

  // Helper method to apply search/filter updates instantly
  void _onFilterChanged() {
    setState(() {
      _viewModel.applyFilters();
      // If the currently selected group is no longer visible under the new filter, clear it
      if (_viewModel.selectedGroup != null) {
        final selectedId = _viewModel.selectedGroup!['groupName'] ?? _viewModel.selectedGroup!['id'];
        final isStillVisible = _viewModel.filteredGroups.any((g) => (g['groupName'] ?? g['id']) == selectedId);
        if (!isStillVisible) {
          _viewModel.selectedGroup = null;
          _taskTextController.clear();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50], // Soft gray premium background
      
      // -------------------------------------------------------------
      // APP BAR (Header)
      // -------------------------------------------------------------
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Task Allocation",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.white),
            ),
            Text(
              "FYP-2 MidTask & Final Task Assigning",
              style: TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
        backgroundColor: Colors.deepPurple,
        elevation: 4,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: "Refresh Groups List",
            onPressed: _fetchAndRefresh,
          ),
        ],
      ),

      // -------------------------------------------------------------
      // MAIN BODY
      // -------------------------------------------------------------
      body: _viewModel.isLoading
          ? _buildLoadingState()
          : Column(
              children: [
                // Top control bar (Milestone + Search + Status badges)
                _buildFilterControls(),
                
                // Content area (List of groups or details)
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      // Desktop/Tablet layout: Side-by-side splits
                      if (constraints.maxWidth > 720) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 4, child: _buildGroupsList(isCompact: true)),
                            VerticalDivider(width: 1, color: Colors.grey[300]),
                            Expanded(flex: 6, child: _buildDetailPanel()),
                          ],
                        );
                      }
                      
                      // Mobile layout: Single list, selection opens a sliding panel or bottom sheet
                      return _viewModel.selectedGroup == null
                          ? _buildGroupsList(isCompact: false)
                          : _buildMobileDetailScreen();
                    },
                  ),
                ),
              ],
            ),
    );
  }

  // -------------------------------------------------------------
  // BUILD STATE: Loading Panel
  // -------------------------------------------------------------
  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: Colors.deepPurple),
          const SizedBox(height: 16),
          Text(
            "Enriching groups and tasks information...",
            style: TextStyle(color: Colors.grey[600], fontSize: 14, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Text(
            "Checking MidTask & Final Task guidelines...",
            style: TextStyle(color: Colors.grey[400], fontSize: 12),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // SECTION: Filter and Search Controls
  // -------------------------------------------------------------
  Widget _buildFilterControls() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: [
          // 1. Milestone Toggle (MidTask vs FinalTask)
          Row(
            children: [
              Expanded(
                child: _buildMilestoneButton(
                  title: "MidTask Mode",
                  milestoneKey: "MidTask",
                  icon: Icons.hourglass_top,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMilestoneButton(
                  title: "Final Task Mode",
                  milestoneKey: "FinalTask",
                  icon: Icons.check_circle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // 2. Search Text Field
          TextField(
            onChanged: (val) {
              _viewModel.searchQuery = val;
              _onFilterChanged();
            },
            decoration: InputDecoration(
              hintText: "Search Group ID, Project Name or Supervisor...",
              prefixIcon: const Icon(Icons.search, color: Colors.deepPurple),
              filled: true,
              fillColor: Colors.grey[100],
              contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 10),

          // 3. Status Filters (Unassigned vs Assigned badges)
          Row(
            children: [
              _buildFilterBadge(
                label: "Unassigned Tasks (${_viewModel.groups.where((g) => !( (g[_viewModel.activeMilestone == "MidTask" ? "midTask" : "finalTask"] ?? "").toString().trim().isNotEmpty )).length})",
                badgeKey: "unassigned",
                activeColor: Colors.orange,
              ),
              const SizedBox(width: 10),
              _buildFilterBadge(
                label: "Assigned Tasks (${_viewModel.groups.where((g) => (g[_viewModel.activeMilestone == "MidTask" ? "midTask" : "finalTask"] ?? "").toString().trim().isNotEmpty).length})",
                badgeKey: "assigned",
                activeColor: Colors.green,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Milestone Selection button builder
  Widget _buildMilestoneButton({required String title, required String milestoneKey, required IconData icon}) {
    final bool isSelected = _viewModel.activeMilestone == milestoneKey;
    return GestureDetector(
      onTap: () {
        setState(() {
          _viewModel.activeMilestone = milestoneKey;
          // Clear current selection and reload filters
          _viewModel.selectedGroup = null;
          _taskTextController.clear();
          _viewModel.applyFilters();
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.deepPurple : Colors.grey[100],
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? Colors.deepPurple : Colors.grey[300]!,
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: Colors.deepPurple.withOpacity(0.2), blurRadius: 4, offset: const Offset(0, 2))]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? Colors.white : Colors.grey[600], size: 18),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[800],
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Filter Badge button builder
  Widget _buildFilterBadge({required String label, required String badgeKey, required Color activeColor}) {
    final bool isSelected = _viewModel.activeFilter == badgeKey;
    return GestureDetector(
      onTap: () {
        setState(() {
          _viewModel.activeFilter = badgeKey;
          _onFilterChanged();
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? activeColor : Colors.grey[300]!,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: isSelected ? activeColor : Colors.grey[400],
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? activeColor : Colors.grey[600],
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // SECTION: Groups List View
  // -------------------------------------------------------------
  Widget _buildGroupsList({required bool isCompact}) {
    if (_viewModel.filteredGroups.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search_off, size: 64, color: Colors.grey[300]),
              const SizedBox(height: 12),
              Text(
                "No Groups Found",
                style: TextStyle(color: Colors.grey[700], fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                "Try search query or toggle unassigned/assigned filter above.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: _viewModel.filteredGroups.length,
      padding: const EdgeInsets.all(12),
      itemBuilder: (context, index) {
        final group = _viewModel.filteredGroups[index];
        final groupId = group['groupName'] ?? group['id'];
        final String projTitle = group['projectTitle'] ?? "No Project Assigned";
        final String supervName = group['supervisor'] ?? "No Supervisor Assigned";
        final int membersCount = group['membersCount'] ?? 0;
        
        // Determine whether this group is currently selected
        final bool isSelected = _viewModel.selectedGroup != null &&
            (_viewModel.selectedGroup!['groupName'] ?? _viewModel.selectedGroup!['id']) == groupId;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: isSelected ? 4 : 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isSelected ? Colors.deepPurple : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            onTap: () {
              setState(() {
                _viewModel.selectGroup(group);
                _taskTextController.text = _viewModel.taskDescription;
              });
            },
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Group ID: $groupId",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                _buildMiniBadge(group),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.book, size: 14, color: Colors.grey),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        projTitle,
                        style: TextStyle(color: Colors.grey[800], fontSize: 13, fontWeight: FontWeight.w500),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.person, size: 14, color: Colors.grey),
                    const SizedBox(width: 6),
                    Text(
                      "Supervisor: $supervName",
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.group, size: 14, color: Colors.grey),
                    const SizedBox(width: 6),
                    Text(
                      "$membersCount Enrolled Members",
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
            trailing: isCompact ? const Icon(Icons.chevron_right, color: Colors.deepPurple) : null,
          ),
        );
      },
    );
  }

  // Simple mini badge helper to show assigned/unassigned status in list
  Widget _buildMiniBadge(Map<String, dynamic> group) {
    // Recheck status based on milestone selection
    final String desc = (_viewModel.activeMilestone == "MidTask") ? (group['midTask'] ?? "") : (group['finalTask'] ?? "");
    final bool isAssigned = desc.trim().isNotEmpty;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isAssigned ? Colors.green[50] : Colors.orange[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isAssigned ? Colors.green : Colors.orange, width: 0.5),
      ),
      child: Text(
        isAssigned ? "Assigned" : "Unassigned",
        style: TextStyle(
          color: isAssigned ? Colors.green[800] : Colors.orange[800],
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // SECTION: Task Detail and Allocation Panel (Tablet/Desktop)
  // -------------------------------------------------------------
  Widget _buildDetailPanel() {
    if (_viewModel.selectedGroup == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.assignment, size: 80, color: Colors.grey[200]),
              const SizedBox(height: 16),
              Text(
                "Select a Group to Allocate Tasks",
                style: TextStyle(color: Colors.grey[500], fontSize: 15, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                "Tap a group from the list on the left to allocate MidTask or Final Task guidelines.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[400], fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    final group = _viewModel.selectedGroup!;
    final groupId = group['groupName'] ?? group['id'];
    final String projTitle = group['projectTitle'] ?? "No Project Assigned";
    final String supervName = group['supervisor'] ?? "No Supervisor Assigned";
    final List members = group['members'] ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Header of the Panel
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Group Details (ID: $groupId)",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.deepPurple),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.grey),
                onPressed: () => setState(() => _viewModel.selectedGroup = null),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 2. Info Cards (Project and Supervisor)
          Card(
            color: Colors.white,
            elevation: 1,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.book, color: Colors.deepPurple, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Project Title", style: TextStyle(fontSize: 11, color: Colors.grey)),
                            Text(
                              projTitle,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  Row(
                    children: [
                      const Icon(Icons.school, color: Colors.teal, size: 20),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Primary Supervisor", style: TextStyle(fontSize: 11, color: Colors.grey)),
                          Text(
                            supervName,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 3. Enrolled Members Details
          const Text(
            "Group Members",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),
          members.isEmpty
              ? Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: const Text("No enrolled student names returned from database yet.", style: TextStyle(color: Colors.grey, fontSize: 12)),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: members.length,
                  itemBuilder: (context, idx) {
                    final m = members[idx];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.deepPurple.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 12,
                                backgroundColor: Colors.deepPurple[100],
                                child: Text(
                                  (m['name'] ?? "?").toString().substring(0, 1).toUpperCase(),
                                  style: const TextStyle(fontSize: 10, color: Colors.deepPurple, fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(m['name'] ?? "", style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          Text(
                            "${m['regNum'] ?? ""} | Sec ${m['section'] ?? ""}",
                            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    );
                  },
                ),
          const SizedBox(height: 16),

          // 4. Input Task Guidelines Panel
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.orange[200]!),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, color: Colors.orange[800], size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "You are assigning a ${_viewModel.activeMilestone} guideline. Students of Group $groupId will see this description in their dashboard task module to submit their progress.",
                    style: TextStyle(fontSize: 12, color: Colors.orange[900]),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          Text(
            "Enter ${_viewModel.activeMilestone} Guidelines / Instructions:",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _taskTextController,
            maxLines: 6,
            onChanged: (val) {
              _viewModel.taskDescription = val;
            },
            decoration: InputDecoration(
              hintText: "Type guidelines, milestones, topics, or tasks here...",
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              fillColor: Colors.white,
              filled: true,
            ),
          ),
          const SizedBox(height: 16),

          // 5. Submit Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              icon: _viewModel.isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.save, color: Colors.white),
              label: Text(
                _viewModel.isSaving ? "Saving Guidelines..." : "Save and Allocate Task",
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: _viewModel.isSaving
                  ? null
                  : () async {
                      if (_viewModel.taskDescription.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Please type a guidelines description first!")),
                        );
                        return;
                      }
                      
                      final success = await _viewModel.assignTask();
                      if (!mounted) return;
                      if (success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("${_viewModel.activeMilestone} guidelines assigned successfully!")),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Failed to assign guidelines. Please check network or try again.")),
                        );
                      }
                    },
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // SECTION: Mobile View (Detail panel inside a clean view)
  // -------------------------------------------------------------
  Widget _buildMobileDetailScreen() {
    return Column(
      children: [
        // Elegant bar to return back to groups list
        Container(
          color: Colors.deepPurple[50],
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.deepPurple),
                onPressed: () {
                  setState(() {
                    _viewModel.selectedGroup = null;
                    _taskTextController.clear();
                  });
                },
              ),
              const Text(
                "Back to Groups List",
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple, fontSize: 14),
              ),
            ],
          ),
        ),
        
        // Render detail panel vertically scrollable
        Expanded(
          child: _buildDetailPanel(),
        ),
      ],
    );
  }
}
