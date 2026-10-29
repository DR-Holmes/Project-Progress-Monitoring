import 'package:flutter/material.dart';
import '../../viewmodels/comitteeheadviewmodel/fyp1_view_edit_criteria_view_model.dart';

// ---------------------------------------------------------
// WHAT IS THIS FILE?
// This is the "View Edit Criteria" screen for FYP-1.
// It allows you to see the rules and change them if you click "Edit".
// It matches your React code exactly!
// ---------------------------------------------------------

class Fyp1ViewEditCriteriaView extends StatefulWidget {
  const Fyp1ViewEditCriteriaView({super.key});

  @override
  State<Fyp1ViewEditCriteriaView> createState() => _Fyp1ViewEditCriteriaViewState();
}

class _Fyp1ViewEditCriteriaViewState extends State<Fyp1ViewEditCriteriaView> {
  // 1. Link to our "Brain" (ViewModel)
  final Fyp1ViewEditCriteriaViewModel _viewModel = Fyp1ViewEditCriteriaViewModel();

  // 2. Local variables (Folders for our data)
  List<Map<String, dynamic>> _criteria = []; // List of marking rules
  List<Map<String, dynamic>> _committeeMembers = []; // List of people
  bool _isLoading = true;
  bool _editMode = false; // Is the "Edit" button clicked?
  int _sessionId = 13; // Hardcoded session ID matching React

  @override
  void initState() {
    super.initState();
    // Load the data when the screen starts
    _loadData();
  }

  // ---------------------------------------------------------
  // FUNCTION: _loadData
  // Fetches criteria and members from the server.
  // ---------------------------------------------------------
  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    // Get rules and members at the same time
    final criteriaData = await _viewModel.fetchCriteria(_sessionId);
    final membersData = await _viewModel.fetchCommitteeMembers();

    if (mounted) {
      setState(() {
        _criteria = criteriaData;
        _committeeMembers = membersData;
        _isLoading = false;
      });
    }
  }

  // ---------------------------------------------------------
  // HANDLER: updateParam
  // Changes a value in a big rule (like the Name or %)
  // ---------------------------------------------------------
  void _updateParam(int id, String field, dynamic value) {
    setState(() {
      for (var p in _criteria) {
        if (p['id'] == id) {
          p[field] = value;
        }
      }
    });
  }

  // ---------------------------------------------------------
  // HANDLER: updateSubParam
  // Changes a value in a small sub-rule
  // ---------------------------------------------------------
  void _updateSubParam(int pid, int sid, String field, dynamic value) {
    setState(() {
      for (var p in _criteria) {
        if (p['id'] == pid) {
          List subs = p['subParameters'] ?? [];
          for (var s in subs) {
            if (s['id'] == sid) {
              s[field] = value;
            }
          }
        }
      }
    });
  }

  // ---------------------------------------------------------
  // HANDLER: toggleMember
  // Adds or removes a person from the marking list
  // ---------------------------------------------------------
  void _toggleMember(int pid, dynamic mid) {
    setState(() {
      for (var p in _criteria) {
        if (p['id'] == pid) {
          List selected = p['selectedMembers'] ?? [];
          if (selected.contains(mid)) {
            selected.remove(mid);
          } else {
            selected.add(mid);
          }
          p['selectedMembers'] = selected;
        }
      }
    });
  }

  // ---------------------------------------------------------
  // ACTION: handleUpdate
  // Sends the edited data back to the server.
  // ---------------------------------------------------------
  Future<void> _handleUpdate() async {
    setState(() => _isLoading = true);
    final result = await _viewModel.updateCriteria(_sessionId, _criteria);
    setState(() => _isLoading = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'])),
      );
      if (result['success']) {
        setState(() => _editMode = false); // Go back to view mode
        _loadData(); // Refresh data
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("View/Edit Criteria", style: TextStyle(color: Colors.black, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // --- EDIT TOGGLE BUTTON ---
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => setState(() => _editMode = !_editMode),
                      icon: Icon(_editMode ? Icons.close : Icons.edit, size: 18),
                      label: Text(_editMode ? "Cancel Edit" : "Edit Criteria"),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _editMode ? Colors.red : Colors.deepPurple,
                        side: BorderSide(color: _editMode ? Colors.red : Colors.deepPurple),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // --- LIST OF CRITERIA ---
                  ..._criteria.map((param) => _buildCriteriaCard(param)),

                  const SizedBox(height: 20),

                  // --- UPDATE BUTTON (Only shows in edit mode) ---
                  if (_editMode)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _handleUpdate,
                        icon: const Icon(Icons.save),
                        label: const Text("Update Criteria"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  // ---------------------------------------------------------
  // WIDGET: _buildCriteriaCard
  // Draws one rule box with inputs.
  // ---------------------------------------------------------
  Widget _buildCriteriaCard(Map<String, dynamic> param) {
    int pid = param['id'] ?? 0;
    List subParams = param['subParameters'] ?? [];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Parameter Name Input
          const Text("Parameter Name", style: TextStyle(fontSize: 12, color: Colors.grey)),
          TextField(
            enabled: _editMode,
            controller: TextEditingController(text: param['name'])..selection = TextSelection.collapsed(offset: param['name'].toString().length),
            onChanged: (val) => _updateParam(pid, "name", val),
            decoration: const InputDecoration(border: InputBorder.none),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const Divider(),

          // 2. Percentage Input
          const Text("Weight (%)", style: TextStyle(fontSize: 12, color: Colors.grey)),
          TextField(
            enabled: _editMode,
            keyboardType: TextInputType.number,
            controller: TextEditingController(text: param['percentage'].toString())..selection = TextSelection.collapsed(offset: param['percentage'].toString().length),
            onChanged: (val) => _updateParam(pid, "percentage", val),
            decoration: const InputDecoration(border: InputBorder.none),
          ),

          // 3. Evaluators (Only if allowed)
          if (param['allowEvaluation'] == true) ...[
            const SizedBox(height: 10),
            const Row(
              children: [
                Icon(Icons.people, size: 14, color: Colors.grey),
                SizedBox(width: 5),
                Text("Evaluators", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 5),
            ..._committeeMembers.map((m) {
              bool isSelected = (param['selectedMembers'] as List).contains(m['id']);
              return CheckboxListTile(
                enabled: _editMode,
                title: Text(m['name'] ?? "", style: const TextStyle(fontSize: 13)),
                value: isSelected,
                dense: true,
                onChanged: (val) => _toggleMember(pid, m['id']),
              );
            }),
          ],

          // 4. Sub Parameters
          if (subParams.isNotEmpty) ...[
            const SizedBox(height: 10),
            const Text("Sub Parameters", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 5),
            ...subParams.map((sub) {
              int sid = sub['id'] ?? 0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextField(
                        enabled: _editMode,
                        decoration: const InputDecoration(hintText: "Name", border: OutlineInputBorder()),
                        controller: TextEditingController(text: sub['name'])..selection = TextSelection.collapsed(offset: sub['name'].toString().length),
                        onChanged: (val) => _updateSubParam(pid, sid, "name", val),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 1,
                      child: TextField(
                        enabled: _editMode,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(hintText: "%", border: OutlineInputBorder()),
                        controller: TextEditingController(text: sub['percentage'].toString())..selection = TextSelection.collapsed(offset: sub['percentage'].toString().length),
                        onChanged: (val) => _updateSubParam(pid, sid, "percentage", val),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}
