import 'package:flutter/material.dart';

import '../../viewmodels/comitteeviewmodel/supervisor_allocation_viewmodel.dart';

class SupervisorAllocationView extends StatefulWidget {
  const SupervisorAllocationView({Key? key}) : super(key: key);

  @override
  State<SupervisorAllocationView> createState() => _SupervisorAllocationViewState();
}

class _SupervisorAllocationViewState extends State<SupervisorAllocationView> {
  final SupervisorAllocationViewModel _viewModel = SupervisorAllocationViewModel();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _viewModel.isLoading = true);
    await _viewModel.fetchData();
    setState(() {}); // Rebuild UI
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Supervisor Allocation", style: TextStyle(color: Colors.black, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: _viewModel.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Info Box
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.people_alt_outlined, color: Colors.blue),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Supervisor Allocation", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text("Assign project groups automatically or manually with balanced load", style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                      ],
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Search & Group Checkboxes
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Search Groups", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextField(
                    decoration: InputDecoration(
                      hintText: "Type group name...",
                      isDense: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: Colors.grey.shade300)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 150, // scrollable area for checkboxes
                    child: ListView.builder(
                      itemCount: _viewModel.groups.length,
                      itemBuilder: (context, index) {
                        final group = _viewModel.groups[index];
                        final groupId = group['id'];
                        return CheckboxListTile(
                          title: Text("Group $groupId", style: const TextStyle(fontSize: 14)),
                          value: _viewModel.selectedGroupIds.contains(groupId),
                          controlAffinity: ListTileControlAffinity.leading,
                          contentPadding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                          onChanged: (bool? value) {
                            setState(() {
                              _viewModel.toggleGroupSelection(groupId);
                            });
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Load Balancing Mode Radio Buttons
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Load Balancing Mode", style: TextStyle(fontWeight: FontWeight.bold)),
                  Row(
                    children: [
                      Expanded(
                        child: RadioListTile<String>(
                          title: const Text("Auto Balanced\n(Algorithm)", style: TextStyle(fontSize: 12)),
                          value: "Auto Balanced (Algorithm)",
                          groupValue: _viewModel.allocationMode,
                          contentPadding: EdgeInsets.zero,
                          onChanged: (value) => setState(() => _viewModel.allocationMode = value!),
                        ),
                      ),
                      Expanded(
                        child: RadioListTile<String>(
                          title: const Text("Custom Manual\nAssignment", style: TextStyle(fontSize: 12)),
                          value: "Custom Manual Assignment",
                          groupValue: _viewModel.allocationMode,
                          contentPadding: EdgeInsets.zero,
                          onChanged: (value) => setState(() => _viewModel.allocationMode = value!),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Supervisors List
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Supervisors", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ..._viewModel.supervisors.map((s) => Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s['name'] ?? 'No Name', style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text("${s['designation']} • ${s['groupsCount']} groups", style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                        const Divider(),
                      ],
                    ),
                  )).toList(),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Action Button
            SizedBox(
              width: double.infinity,
              height: 45,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () {
                  print("Allocating ${_viewModel.selectedGroupIds.length} groups via ${_viewModel.allocationMode}");
                  // Call backend API to save here
                },
                child: const Text("Allocate Supervisors", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}