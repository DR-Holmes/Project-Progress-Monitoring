import 'package:flutter/material.dart';
import '../../viewmodels/comitteeheadviewmodel/fyp2_view_edit_criteria_view_model.dart';

// ---------------------------------------------------------
// WHAT IS THIS FILE?
// This is the "View Edit Criteria" screen for FYP-2.
// It allows you to see the rules and change them if you click "Edit".
// It matches your React code exactly!
// ---------------------------------------------------------

class Fyp2ViewEditCriteriaView extends StatefulWidget {
  const Fyp2ViewEditCriteriaView({super.key});

  @override
  State<Fyp2ViewEditCriteriaView> createState() => _Fyp2ViewEditCriteriaViewState();
}

class _Fyp2ViewEditCriteriaViewState extends State<Fyp2ViewEditCriteriaView> {
  // 1. Link to our "Brain" (ViewModel)
  final Fyp2ViewEditCriteriaViewModel _viewModel = Fyp2ViewEditCriteriaViewModel();

  // 2. Local variables (Folders for our data)
  List<Map<String, dynamic>> _criteria = []; // List of marking rules
  bool _isLoading = true;
  bool _editMode = false; // Is the "Edit" button clicked?
  int _sessionId = 13; // Hardcoded dynamic session ID matching React

  @override
  void initState() {
    super.initState();
    // Load the data when the screen starts
    _loadData();
  }

  // ---------------------------------------------------------
  // FUNCTION: _loadData
  // Fetches criteria from the server.
  // ---------------------------------------------------------
  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    final data = await _viewModel.fetchCriteria(_sessionId);

    if (mounted) {
      setState(() {
        _criteria = data;
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
  // CALCULATIONS
  // ---------------------------------------------------------
  int _totalMainPercentage() {
    int sum = 0;
    for (var p in _criteria) {
      sum += int.tryParse(p['percentage'].toString()) ?? 0;
    }
    return sum;
  }

  int _subTotal(Map<String, dynamic> param) {
    int sum = 0;
    List subs = param['subParameters'] ?? [];
    for (var s in subs) {
      sum += int.tryParse(s['percentage'].toString()) ?? 0;
    }
    return sum;
  }

  // ---------------------------------------------------------
  // ACTION: handleUpdate
  // Sends the edited data back to the server.
  // ---------------------------------------------------------
  Future<void> _handleUpdate() async {
    if (_totalMainPercentage() != 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Main percentage must be 100%")),
      );
      return;
    }

    // --- Sub-parameters Validation ---
    for (var p in _criteria) {
      List subParams = p['subParameters'] ?? [];
      if (subParams.isNotEmpty) {
        int pPercentage = int.tryParse(p['percentage'].toString()) ?? 0;
        int sTotal = _subTotal(p);
        if (sTotal != pPercentage) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Sub-parameters for '${p['name']}' must sum to $pPercentage%")),
          );
          return;
        }
      }
    }

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
    int totalMain = _totalMainPercentage();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("FYP-2 Criteria", style: TextStyle(color: Colors.black, fontSize: 18)),
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

                  const SizedBox(height: 16),

                  // --- TOTAL PERCENTAGE BOX ---
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: totalMain == 100 ? Colors.green[100] : Colors.red[100],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      "Total Main Percentage: $totalMain%",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: totalMain == 100 ? Colors.green[800] : Colors.red[800],
                      ),
                    ),
                  ),

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
    int sTotal = _subTotal(param);
    int pPercentage = int.tryParse(param['percentage'].toString()) ?? 0;

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
            decoration: const InputDecoration(border: InputBorder.none, hintText: "Parameter Name", isDense: true),
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
            decoration: const InputDecoration(border: InputBorder.none, hintText: "Percentage", isDense: true),
          ),

          // 3. Sub Parameters
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
                        decoration: const InputDecoration(hintText: "Sub parameter", border: OutlineInputBorder(), isDense: true, contentPadding: EdgeInsets.all(8)),
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
                        decoration: const InputDecoration(hintText: "%", border: OutlineInputBorder(), isDense: true, contentPadding: EdgeInsets.all(8)),
                        controller: TextEditingController(text: sub['percentage'].toString())..selection = TextSelection.collapsed(offset: sub['percentage'].toString().length),
                        onChanged: (val) => _updateSubParam(pid, sid, "percentage", val),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 5),

            // Sub Total Validator Text
            Text(
              "Sub Total: $sTotal%",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: sTotal == pPercentage ? Colors.green[700] : Colors.red[700],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
