import 'package:flutter/material.dart';
import '../../viewmodels/comitteeheadviewmodel/fyp1_setup_criteria_view_model.dart';

// ---------------------------------------------------------
// WHAT IS THIS FILE?
// This is the screen where the Committee Head can set rules for marking.
// They can add things like "Pitching" or "Report" and give them percentages.
// It matches the React code you provided!
// ---------------------------------------------------------

class Fyp1SetupCriteriaView extends StatefulWidget {
  const Fyp1SetupCriteriaView({super.key});

  @override
  State<Fyp1SetupCriteriaView> createState() => _Fyp1SetupCriteriaViewState();
}

class _Fyp1SetupCriteriaViewState extends State<Fyp1SetupCriteriaView> {
  // 1. Link to our "Brain" (ViewModel)
  final Fyp1SetupCriteriaViewModel _viewModel = Fyp1SetupCriteriaViewModel();

  // 2. Local variables (Folders for our data)
  List<Map<String, dynamic>> _committeeMembers = []; // List of people
  
  // This is our main list of marking rules (Parameters)
  // It starts with one empty rule just like your React code
  List<Map<String, dynamic>> _parameters = [
    {
      "id": DateTime.now().millisecondsSinceEpoch,
      "label": "Pitching",
      "percentage": "0",
      "allowEvaluation": false,
      "selectedMembers": [], // People picked to mark this
      "subParameters": [], // Small pieces of this rule
    }
  ];

  bool _isLoading = true; // Are we busy loading members?

  @override
  void initState() {
    super.initState();
    // When the screen opens, go get the committee members!
    _loadMembers();
  }

  // ---------------------------------------------------------
  // FUNCTION: _loadMembers
  // Gets the list of committee people from the ViewModel.
  // ---------------------------------------------------------
  Future<void> _loadMembers() async {
    final members = await _viewModel.fetchCommitteeMembers();
    if (mounted) {
      setState(() {
        _committeeMembers = members;
        _isLoading = false;
      });
    }
  }

  // ---------------------------------------------------------
  // CALCULATION: totalMainPercentage
  // Adds up all the big percentages to see if they reach 100.
  // ---------------------------------------------------------
  double get _totalMainPercentage {
    double sum = 0;
    for (var p in _parameters) {
      sum += double.tryParse(p['percentage'].toString()) ?? 0;
    }
    return sum;
  }

  // ---------------------------------------------------------
  // CALCULATION: subTotal
  // Adds up all the small percentages inside a big rule.
  // ---------------------------------------------------------
  double _subTotal(Map<String, dynamic> param) {
    double sum = 0;
    List subs = param['subParameters'] ?? [];
    for (var s in subs) {
      sum += double.tryParse(s['percentage'].toString()) ?? 0;
    }
    return sum;
  }

  // ---------------------------------------------------------
  // ACTION: handleSave
  // This checks if everything is correct, then sends it to the server.
  // ---------------------------------------------------------
  Future<void> _handleSave() async {
    // Check if main total is 100
    if (_totalMainPercentage != 100) {
      _showSnack("Main parameters must total exactly 100%");
      return;
    }

    // Check if sub-parameters for each rule total 100
    for (var p in _parameters) {
      List subs = p['subParameters'] ?? [];
      if (subs.isNotEmpty) {
        if (_subTotal(p) != 100) {
          _showSnack("Sub-parameters for \"${p['label']}\" must total 100%");
          return;
        }
      }
    }

    // Prepare the data to send (Payload)
    final payload = {
      "sessionID": 13, // Hardcoded like in React
      "parameters": _parameters.map((p) {
        return {
          "name": p['label'],
          "percentage": int.tryParse(p['percentage'].toString()) ?? 0,
          "allowEvaluation": p['allowEvaluation'],
          "evaluators": p['selectedMembers'], // IDs of picked members
          "subParameters": (p['subParameters'] as List).map((s) {
            return {
              "name": s['label'],
              "percentage": int.tryParse(s['percentage'].toString()) ?? 0
            };
          }).toList()
        };
      }).toList()
    };

    // Send it!
    setState(() => _isLoading = true);
    final result = await _viewModel.saveCriteria(payload);
    setState(() => _isLoading = false);

    if (mounted) {
      _showSnack(result['message']);
      if (result['success']) {
        Navigator.pop(context); // Go back if successful
      }
    }
  }

  // Helper to show a pop-up message at the bottom
  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // ---------------------------------------------------------
  // UI BUILDER: This draws the whole screen!
  // ---------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Set Evaluation Criteria", style: TextStyle(color: Colors.black, fontSize: 18)),
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
                  // --- LIST OF PARAMETERS ---
                  // This is like a factory that makes a card for each rule
                  ..._parameters.map((param) => _buildParameterCard(param)),

                  const SizedBox(height: 16),

                  // --- ADD PARAMETER BUTTON ---
                  // Click this to add a new big rule
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        setState(() {
                          _parameters.add({
                            "id": DateTime.now().millisecondsSinceEpoch,
                            "label": "",
                            "percentage": "0",
                            "allowEvaluation": false,
                            "selectedMembers": [],
                            "subParameters": [],
                          });
                        });
                      },
                      icon: const Icon(Icons.add),
                      label: const Text("Add Parameter"),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // --- TOTAL DISPLAY ---
                  // Shows if you are at 100% yet
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _totalMainPercentage == 100 ? Colors.green[50] : Colors.red[50],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        "Total Main Percentage: ${_totalMainPercentage.toStringAsFixed(0)}%",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _totalMainPercentage == 100 ? Colors.green[700] : Colors.red[700],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // --- SAVE BUTTON ---
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _handleSave,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text("Save Criteria", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  // ---------------------------------------------------------
  // WIDGET: _buildParameterCard
  // This draws a single big rule card (like "Pitching").
  // ---------------------------------------------------------
  Widget _buildParameterCard(Map<String, dynamic> param) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Parameter Name and Delete Button
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(hintText: "Parameter Name", border: InputBorder.none),
                  controller: TextEditingController(text: param['label'])..selection = TextSelection.collapsed(offset: param['label'].length),
                  onChanged: (val) => param['label'] = val,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () {
                  setState(() {
                    _parameters.removeWhere((p) => p['id'] == param['id']);
                  });
                },
              ),
            ],
          ),
          const Divider(),

          // 2. Percentage Input
          const Text("Parameter Percentage (%)", style: TextStyle(fontSize: 12, color: Colors.grey)),
          TextField(
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(hintText: "Enter %", border: InputBorder.none),
            controller: TextEditingController(text: param['percentage'])..selection = TextSelection.collapsed(offset: param['percentage'].toString().length),
            onChanged: (val) {
              setState(() {
                param['percentage'] = val;
              });
            },
          ),

          const SizedBox(height: 10),

          // 3. Allow Committee Evaluation (Checkbox)
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(10)),
            child: Column(
              children: [
                Row(
                  children: [
                    Checkbox(
                      value: param['allowEvaluation'],
                      onChanged: (val) {
                        setState(() {
                          param['allowEvaluation'] = val;
                        });
                      },
                    ),
                    const Text("Allow Committee Evaluation", style: TextStyle(fontWeight: FontWeight.w500)),
                  ],
                ),
                
                // If checkbox is checked, show the members list!
                if (param['allowEvaluation']) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        Icon(Icons.people_outline, size: 16, color: Colors.grey),
                        SizedBox(width: 8),
                        Text("Select Evaluators", style: TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  // List of members to pick from
                  ..._committeeMembers.map((member) {
                    bool isSelected = (param['selectedMembers'] as List).contains(member['id']);
                    return CheckboxListTile(
                      title: Text(member['name'] ?? "No Name", style: const TextStyle(fontSize: 14)),
                      value: isSelected,
                      dense: true,
                      onChanged: (val) {
                        setState(() {
                          if (val == true) {
                            (param['selectedMembers'] as List).add(member['id']);
                          } else {
                            (param['selectedMembers'] as List).remove(member['id']);
                          }
                        });
                      },
                    );
                  }),
                ],
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 4. Sub Parameters Section
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.deepPurple[50]!.withOpacity(0.3), borderRadius: BorderRadius.circular(10)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Sub Parameters", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple)),
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          (param['subParameters'] as List).add({
                            "id": DateTime.now().millisecondsSinceEpoch,
                            "label": "",
                            "percentage": "0",
                          });
                        });
                      },
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text("Add"),
                    ),
                  ],
                ),
                
                // Draw each sub-parameter row
                ...(param['subParameters'] as List).map((sub) => _buildSubParamRow(param, sub)),

                const SizedBox(height: 10),
                Text(
                  "Sub Total: ${_subTotal(param).toStringAsFixed(0)}%",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: _subTotal(param) == 100 ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------
  // WIDGET: _buildSubParamRow
  // This draws a single row for a sub-parameter (Name + % + Delete).
  // ---------------------------------------------------------
  Widget _buildSubParamRow(Map<String, dynamic> parentParam, Map<String, dynamic> sub) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          // Sub Name
          Expanded(
            flex: 3,
            child: TextField(
              decoration: const InputDecoration(hintText: "Sub Name", border: OutlineInputBorder()),
              controller: TextEditingController(text: sub['label'])..selection = TextSelection.collapsed(offset: sub['label'].length),
              onChanged: (val) => sub['label'] = val,
              style: const TextStyle(fontSize: 13),
            ),
          ),
          const SizedBox(width: 8),
          // Sub Percentage
          Expanded(
            flex: 1,
            child: TextField(
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(hintText: "%", border: OutlineInputBorder()),
              controller: TextEditingController(text: sub['percentage'])..selection = TextSelection.collapsed(offset: sub['percentage'].toString().length),
              onChanged: (val) {
                setState(() {
                  sub['percentage'] = val;
                });
              },
              style: const TextStyle(fontSize: 13),
            ),
          ),
          // Delete Sub
          IconButton(
            icon: const Icon(Icons.close, color: Colors.red, size: 20),
            onPressed: () {
              setState(() {
                (parentParam['subParameters'] as List).removeWhere((s) => s['id'] == sub['id']);
              });
            },
          ),
        ],
      ),
    );
  }
}
