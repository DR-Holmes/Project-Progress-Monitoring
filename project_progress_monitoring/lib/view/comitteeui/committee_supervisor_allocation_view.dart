import 'package:flutter/material.dart';
import '../../viewmodels/comitteeviewmodel/committee_supervisor_allocation_view_model.dart';

// ---------------------------------------------------------
// WHAT IS THIS FILE?
// This is the "View" (UI Screen) for regular Committee Member Supervisor Allocation.
// It allows a Committee member to assign a supervisor to a group.
// It features:
// - A toggle for FYP-1 / FYP-2 (active when selecting groups manually).
// - A Group Selection Dropdown populated based on the chosen FYP toggle.
// - A Supervisor Selection Dropdown (in manual assignment mode).
// - Clean VVM styling and primary schooler comments.
// ---------------------------------------------------------

class CommitteeSupervisorAllocationView extends StatefulWidget {
  // We make the groupId parameter OPTIONAL (nullable) now!
  // If null or <= 0, the user will select the fyp and group from the dropdowns.
  final int? groupId;

  const CommitteeSupervisorAllocationView({super.key, this.groupId});

  @override
  State<CommitteeSupervisorAllocationView> createState() => _CommitteeSupervisorAllocationViewState();
}

class _CommitteeSupervisorAllocationViewState extends State<CommitteeSupervisorAllocationView> {
  // 1. Instantiate the Brain (ViewModel)
  final CommitteeSupervisorAllocationViewModel _viewModel = CommitteeSupervisorAllocationViewModel();

  // 2. State variables managed purely via setState()
  String _mode = "auto"; // "auto" (Auto balanced workload) or "manual" (Manual dropdown pick)
  String _selectedFyp = "FYP-1"; // Toggle choice: "FYP-1" or "FYP-2"
  int? _selectedGroupId; // Holds the ID of the group we want to allocate
  String? _selectedSupervisorId; // Holds the ID of the chosen supervisor
  String? _allocatedTo; // Name of the supervisor successfully allocated to

  @override
  void initState() {
    super.initState();
    // If the widget passed a groupId, auto-select it immediately!
    if (widget.groupId != null && widget.groupId! > 0) {
      _selectedGroupId = widget.groupId;
    }
    // Load supervisors and groups when the screen starts
    _loadData();
  }

  // ---------------------------------------------------------
  // FUNCTION: _loadData
  // Simply runs the ViewModel function and updates the screen.
  // ---------------------------------------------------------
  Future<void> _loadData() async {
    await _viewModel.loadAllData(_selectedFyp);
    if (mounted) {
      setState(() {});
    }
  }

  // ---------------------------------------------------------
  // FUNCTION: _handleFypToggle
  // Changes the active fyp, resets the selected group, and fetches fresh groups.
  // ---------------------------------------------------------
  Future<void> _handleFypToggle(String fyp) async {
    if (_selectedFyp == fyp) return;
    setState(() {
      _selectedFyp = fyp;
      _selectedGroupId = null; // Clear chosen group ID so dropdown resets
    });
    await _loadData();
  }

  // ---------------------------------------------------------
  // FUNCTION: _handleAllocation
  // Performs the actual allocation when the big button is clicked.
  // ---------------------------------------------------------
  Future<void> _handleAllocation() async {
    // 1. Validation check: Did they select a group?
    if (_selectedGroupId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a project group first!")),
      );
      return;
    }

    Map<String, dynamic>? targetSupervisor;

    // 2. Figure out who we are assigning
    if (_mode == "auto") {
      targetSupervisor = _viewModel.autoAllocateSupervisor();
    } else {
      // Find the supervisor matching the selected dropdown value ID
      for (var s in _viewModel.supervisors) {
        if (s['SupervisorId'] == _selectedSupervisorId) {
          targetSupervisor = s;
          break;
        }
      }
    }

    // 3. Validation check: Did we find or select anyone?
    if (targetSupervisor == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a supervisor first!")),
      );
      return;
    }

    // 4. Send the allocation request to the internet
    setState(() => _viewModel.isLoading = true);
    bool success = await _viewModel.allocateSupervisorToGroup(
      _selectedGroupId!, 
      targetSupervisor['SupervisorId'].toString(),
    );

    if (mounted) {
      setState(() => _viewModel.isLoading = false);

      if (success) {
        // Show success state on UI
        setState(() {
          _allocatedTo = targetSupervisor?['SupervisorName'];
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Group $_selectedGroupId allocated successfully to ${targetSupervisor['SupervisorName']}!")),
        );

        // Refresh counts from the server so the load values are fresh
        _loadData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Oops! Allocation failed. Please try again.")),
        );
      }
    }
  }

  // ---------------------------------------------------------
  // THE BIG BUILD FUNCTION
  // Draws the layout on the screen.
  // ---------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    // Check if the page is loading
    bool pageIsLoading = _viewModel.isLoading;

    return Scaffold(
      backgroundColor: Colors.grey[50], // Nice clean light grey background
      appBar: AppBar(
        title: const Text("Allocate Supervisor", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 1,
      ),
      body: pageIsLoading
          ? const Center(child: CircularProgressIndicator()) // Spinner
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  
                  // 1. EXPLANATION HEADER
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.blue.shade100),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue.shade700),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            "Assign a supervisor to guide a project group. Choose to automatically balance workload or pick manually.",
                            style: TextStyle(fontSize: 13, height: 1.3),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 2. FYP TOGGLE SECTION (ONLY SHOW WHEN NOT PRE-SELECTED FROM QUEUE)
                  if (widget.groupId == null || widget.groupId! <= 0) ...[
                    const Text("SELECT FYP SEMESTER", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.all(4),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => _handleFypToggle("FYP-1"),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: _selectedFyp == "FYP-1" ? Colors.white : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: _selectedFyp == "FYP-1"
                                      ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))]
                                      : [],
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                child: Center(
                                  child: Text(
                                    "FYP - 1",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: _selectedFyp == "FYP-1" ? Colors.deepPurple : Colors.grey.shade700,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => _handleFypToggle("FYP-2"),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: _selectedFyp == "FYP-2" ? Colors.white : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: _selectedFyp == "FYP-2"
                                      ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))]
                                      : [],
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                child: Center(
                                  child: Text(
                                    "FYP - 2",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: _selectedFyp == "FYP-2" ? Colors.deepPurple : Colors.grey.shade700,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // 3. GROUP SELECTOR SECTION
                  const Text("PROJECT GROUP", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: widget.groupId != null && widget.groupId! > 0
                        ? Row(
                            children: [
                              const Icon(Icons.groups, color: Colors.deepPurple),
                              const SizedBox(width: 12),
                              Text(
                                "Auto-Selected Group: ${widget.groupId}",
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                              const Spacer(),
                              const Icon(Icons.lock_outline, color: Colors.grey, size: 18),
                            ],
                          )
                        : DropdownButtonFormField<int>(
                            value: _selectedGroupId,
                            hint: Text("Select Project Group for $_selectedFyp"),
                            decoration: const InputDecoration(
                              prefixIcon: Icon(Icons.groups, color: Colors.deepPurple),
                              border: InputBorder.none,
                            ),
                            items: _viewModel.groups.map((group) {
                              int id = group['groupName'] as int;
                              String title = group['projectTitle'] ?? "No Title";
                              return DropdownMenuItem<int>(
                                value: id,
                                child: Text("Group $id ($title)", overflow: TextOverflow.ellipsis),
                              );
                            }).toList(),
                            onChanged: (val) {
                              setState(() {
                                _selectedGroupId = val;
                              });
                            },
                          ),
                  ),
                  const SizedBox(height: 20),

                  // 4. ALLOCATION MODE SELECTOR RADIO BUTTONS
                  const Text("ALLOCATION MODE", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      children: [
                        // Radio button for "Auto Balanced"
                        RadioListTile<String>(
                          title: const Text("Auto Balanced (Least Load)", style: TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: const Text("System chooses supervisor with the lowest group count"),
                          value: "auto",
                          groupValue: _mode,
                          activeColor: Colors.deepPurple,
                          onChanged: (val) {
                            if (val != null) setState(() => _mode = val);
                          },
                        ),
                        const Divider(height: 1),
                        // Radio button for "Manual Pick"
                        RadioListTile<String>(
                          title: const Text("Manual Assignment", style: TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: const Text("Pick any supervisor from a dropdown list"),
                          value: "manual",
                          groupValue: _mode,
                          activeColor: Colors.deepPurple,
                          onChanged: (val) {
                            if (val != null) setState(() => _mode = val);
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 5. SUPERVISOR SELECTOR (DROPDOWN IF MANUAL, PREVIEW IF AUTO)
                  const Text("SUPERVISOR SELECTION", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: _mode == "auto"
                        ? Builder(
                            builder: (context) {
                              final autoSelected = _viewModel.autoAllocateSupervisor();
                              if (autoSelected == null) {
                                return const Text("No supervisors available", style: TextStyle(color: Colors.red));
                              }
                              return Row(
                                children: [
                                  const Icon(Icons.person_outline, color: Colors.deepPurple),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      "Auto-Balanced Supervisor: ${autoSelected['SupervisorName']} (Groups: ${autoSelected['TotalGroups']})",
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              );
                            },
                          )
                        : DropdownButtonFormField<String>(
                            value: _selectedSupervisorId,
                            hint: const Text("Select Supervisor"),
                            decoration: const InputDecoration(
                              prefixIcon: Icon(Icons.person, color: Colors.deepPurple),
                              border: InputBorder.none,
                            ),
                            items: _viewModel.supervisors.map((s) {
                              String id = s['SupervisorId'].toString();
                              String name = s['SupervisorName'] ?? "No Name";
                              int totalGroups = s['TotalGroups'] ?? 0;
                              return DropdownMenuItem<String>(
                                value: id,
                                child: Text("$name (Groups: $totalGroups)"),
                              );
                            }).toList(),
                            onChanged: (val) {
                              setState(() {
                                _selectedSupervisorId = val;
                              });
                            },
                          ),
                  ),
                  const SizedBox(height: 24),

                  // 6. ACTION BUTTON
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: _handleAllocation,
                      child: const Text(
                        "Confirm Allocation",
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),

                  // 7. ALLOCATED TO SUCCESS STATE CONTAINER
                  if (_allocatedTo != null) ...[
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Center(
                        child: Text(
                          "Allocated To: $_allocatedTo",
                          style: TextStyle(color: Colors.green.shade800, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),
                  
                  // 8. LOADS PREVIEW CARDS
                  const Text("CURRENT WORKLOADS (SUPERVISORS)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
                  const SizedBox(height: 8),
                  ..._viewModel.supervisors.map((s) {
                    final name = s['SupervisorName'] ?? "No Name";
                    final count = s['TotalGroups'] ?? 0;
                    return Card(
                      color: Colors.white,
                      margin: const EdgeInsets.only(bottom: 8),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      child: ListTile(
                        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        trailing: Chip(
                          label: Text("Groups: $count", style: const TextStyle(fontSize: 12)),
                          backgroundColor: Colors.deepPurple.shade50,
                        ),
                      ),
                    );
                  }).toList(),

                ],
              ),
            ),
    );
  }
}
