import 'package:flutter/material.dart';
import '../../viewmodels/comitteeheadviewmodel/fyp2_setup_criteria_view_model.dart';

// ---------------------------------------------------------
// WHAT IS THIS FILE?
// This is the "Setup Criteria" screen for FYP-2.
// It allows the committee head to assign marking percentages
// to main parameters and sub-parameters, making sure they
// total 100%. It completely mirrors your React code.
// ---------------------------------------------------------

class Fyp2SetupCriteriaView extends StatefulWidget {
  const Fyp2SetupCriteriaView({super.key});

  @override
  State<Fyp2SetupCriteriaView> createState() => _Fyp2SetupCriteriaViewState();
}

class _Fyp2SetupCriteriaViewState extends State<Fyp2SetupCriteriaView> {
  // 1. Link to our "Brain" (ViewModel)
  final Fyp2SetupCriteriaViewModel _viewModel = Fyp2SetupCriteriaViewModel();

  // 2. Local variables
  List<Map<String, dynamic>> _parameters = [];
  bool _isLoading = true;
  int _sessionId = 13; // Hardcoded dynamic session ID matching React

  @override
  void initState() {
    super.initState();
    _loadCriteria();
  }

  // ---------------------------------------------------------
  // FUNCTION: _loadCriteria
  // Fetches criteria from the server. If empty, starts fresh.
  // ---------------------------------------------------------
  Future<void> _loadCriteria() async {
    setState(() => _isLoading = true);

    final data = await _viewModel.fetchCriteria(_sessionId);

    if (mounted) {
      setState(() {
        if (data.isNotEmpty) {
          // Map backend data to frontend structure
          _parameters = data.map((p) {
            List subParams = p['subParameters'] ?? [];
            return {
              'id': p['id'],
              'label': p['name'],
              'percentage': p['percentage'].toString(),
              'subParameters': subParams.map((s) => {
                'id': s['id'],
                'label': s['name'],
                'percentage': s['percentage'].toString(),
              }).toList(),
            };
          }).toList();
        } else {
          // Default empty state
          _parameters = [
            {
              'id': DateTime.now().millisecondsSinceEpoch,
              'label': "",
              'percentage': "",
              'subParameters': <Map<String, dynamic>>[],
            }
          ];
        }
        _isLoading = false;
      });
    }
  }

  // ---------------------------------------------------------
  // HANDLERS: Modify parameters
  // ---------------------------------------------------------
  void _updateParam(int id, String field, dynamic value) {
    setState(() {
      for (var p in _parameters) {
        if (p['id'] == id) {
          p[field] = value;
        }
      }
    });
  }

  void _addParameter() {
    setState(() {
      _parameters.add({
        'id': DateTime.now().millisecondsSinceEpoch,
        'label': "",
        'percentage': "",
        'subParameters': <Map<String, dynamic>>[],
      });
    });
  }

  void _removeParameter(int id) {
    setState(() {
      _parameters.removeWhere((p) => p['id'] == id);
    });
  }

  // ---------------------------------------------------------
  // HANDLERS: Modify Sub-parameters
  // ---------------------------------------------------------
  void _addSubParameter(int paramId) {
    setState(() {
      for (var p in _parameters) {
        if (p['id'] == paramId) {
          List subs = p['subParameters'];
          subs.add({
            'id': DateTime.now().millisecondsSinceEpoch,
            'label': "",
            'percentage': "",
          });
        }
      }
    });
  }

  void _updateSubParam(int paramId, int subId, String field, dynamic value) {
    setState(() {
      for (var p in _parameters) {
        if (p['id'] == paramId) {
          List subs = p['subParameters'];
          for (var s in subs) {
            if (s['id'] == subId) {
              s[field] = value;
            }
          }
        }
      }
    });
  }

  void _removeSubParam(int paramId, int subId) {
    setState(() {
      for (var p in _parameters) {
        if (p['id'] == paramId) {
          List subs = p['subParameters'];
          subs.removeWhere((s) => s['id'] == subId);
        }
      }
    });
  }

  // ---------------------------------------------------------
  // CALCULATIONS
  // ---------------------------------------------------------
  int _totalMainPercentage() {
    int sum = 0;
    for (var p in _parameters) {
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
  // ACTION: handleSave
  // Validates the totals and sends it to the server!
  // ---------------------------------------------------------
  Future<void> _handleSave() async {
    if (_totalMainPercentage() != 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Main parameters must total exactly 100%")),
      );
      return;
    }

    // Sub-parameter validation
    for (var p in _parameters) {
      List subs = p['subParameters'] ?? [];
      if (subs.isNotEmpty) {
        int tSub = _subTotal(p);
        if (tSub != 100) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Sub-parameters for "${p['label']}" must total 100%. Current: $tSub%')),
          );
          return;
        }
      }
    }

    setState(() => _isLoading = true);

    // Prepare exactly what React sends
    Map<String, dynamic> payload = {
      "sessionID": _sessionId,
      "parameters": _parameters.map((p) {
        List subs = p['subParameters'] ?? [];
        return {
          "name": p['label'],
          "percentage": int.tryParse(p['percentage'].toString()) ?? 0,
          "allowEvaluation": false,
          "evaluators": [],
          "subParameters": subs.map((s) => {
            "name": s['label'],
            "percentage": int.tryParse(s['percentage'].toString()) ?? 0,
          }).toList(),
        };
      }).toList(),
    };

    final result = await _viewModel.saveCriteria(payload);

    setState(() => _isLoading = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'])),
      );
      if (result['success']) {
        _loadCriteria();
      }
    }
  }

  // ---------------------------------------------------------
  // UI DRAWING
  // ---------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    int totalMain = _totalMainPercentage();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("FYP-2 Setup Criteria", style: TextStyle(color: Colors.black, fontSize: 18)),
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
                  ..._parameters.map((param) => _buildParameterCard(param)),

                  const SizedBox(height: 10),

                  // --- ADD PARAMETER BUTTON ---
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _addParameter,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text("Add Parameter"),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.deepPurple,
                        side: const BorderSide(color: Colors.deepPurple),
                      ),
                    ),
                  ),

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

                  const SizedBox(height: 16),

                  // --- SAVE BUTTON ---
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _handleSave,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text("Save Criteria", style: TextStyle(fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  // ---------------------------------------------------------
  // WIDGET: _buildParameterCard
  // Draws one main parameter box and its sub-parameters.
  // ---------------------------------------------------------
  Widget _buildParameterCard(Map<String, dynamic> param) {
    int paramId = param['id'];
    List subs = param['subParameters'] ?? [];
    int sTotal = _subTotal(param);
    int pPercentage = int.tryParse(param['percentage'].toString()) ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Parameter Name & Delete Button
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(hintText: "Parameter Name", isDense: true),
                  controller: TextEditingController(text: param['label'])..selection = TextSelection.collapsed(offset: param['label'].toString().length),
                  onChanged: (val) => _updateParam(paramId, "label", val),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                onPressed: () => _removeParameter(paramId),
              )
            ],
          ),
          const SizedBox(height: 10),

          // 2. Main Percentage
          TextField(
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(hintText: "Parameter %", isDense: true),
            controller: TextEditingController(text: param['percentage'].toString())..selection = TextSelection.collapsed(offset: param['percentage'].toString().length),
            onChanged: (val) => _updateParam(paramId, "percentage", val),
          ),
          const SizedBox(height: 16),

          // 3. Sub Parameters Section
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Sub Parameters", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    OutlinedButton.icon(
                      onPressed: () => _addSubParameter(paramId),
                      icon: const Icon(Icons.add, size: 14),
                      label: const Text("Add", style: TextStyle(fontSize: 12)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                        minimumSize: const Size(0, 30),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // List of Sub Parameters
                ...subs.map((sub) {
                  int subId = sub['id'];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextField(
                            decoration: const InputDecoration(hintText: "Sub parameter", border: OutlineInputBorder(), isDense: true, contentPadding: EdgeInsets.all(8)),
                            controller: TextEditingController(text: sub['label'])..selection = TextSelection.collapsed(offset: sub['label'].toString().length),
                            onChanged: (val) => _updateSubParam(paramId, subId, "label", val),
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 1,
                          child: TextField(
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(hintText: "%", border: OutlineInputBorder(), isDense: true, contentPadding: EdgeInsets.all(8)),
                            controller: TextEditingController(text: sub['percentage'].toString())..selection = TextSelection.collapsed(offset: sub['percentage'].toString().length),
                            onChanged: (val) => _updateSubParam(paramId, subId, "percentage", val),
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red, size: 18),
                          onPressed: () => _removeSubParam(paramId, subId),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        )
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
            ),
          ),
        ],
      ),
    );
  }
}
