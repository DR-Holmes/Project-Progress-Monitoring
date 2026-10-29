import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../viewmodels/supervisorviewmodel/all_tasks_viewmodel.dart';
import 'assign_task_view.dart';

class AllTasksView extends StatefulWidget {
  final Map<String, dynamic> userMap;

  const AllTasksView({super.key, required this.userMap});

  @override
  State<AllTasksView> createState() => _AllTasksViewState();
}

class _AllTasksViewState extends State<AllTasksView> {
  final AllTasksViewModel _viewModel = AllTasksViewModel();
  String _activeTab = "FYP-1"; // Subject Type
  String _taskTab = "uncompleted"; // uncompleted | completed
  bool _isLoading = false;

  // Data
  List<dynamic> _tasks = [];
  Map<int, String> _localStatus = {}; // taskId -> initial|partial|complete
  Map<int, String> _localRemarks = {}; // taskId -> remarks
  Map<int, String> _localScores = {}; // taskId -> score

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final fetched = await _viewModel.fetchTasks(widget.userMap['id'].toString(), _activeTab);
    
    if (mounted) {
      setState(() {
        _tasks = fetched;
        _isLoading = false;
        
        // 🏫 SCHOOL LESSON: Map backend statuses to simple UI labels!
        for (var t in fetched) {
          final status = t['TaskStatus']?.toString().toLowerCase() ?? "";
          if (status.contains("complete")) _localStatus[t['Id']] = "complete";
          else if (status.contains("progress")) _localStatus[t['Id']] = "partial";
          else _localStatus[t['Id']] = "initial";
        }
      });
    }
  }

  void _switchTab(String tab) {
    setState(() {
      _activeTab = tab;
      _loadData();
    });
  }

  // 🏫 SCHOOL LESSON: Filter tasks like your friend's React code!
  List<dynamic> get _visibleTasks {
    return _tasks.where((t) {
      final status = _localStatus[t['Id']] ?? "initial";
      if (_taskTab == "completed") return status == "complete";
      return status != "complete";
    }).toList();
  }

  Future<void> _saveEvaluation(int taskId) async {
    setState(() => _isLoading = true);
    
    // Mapping back to what the backend expects
    final statusMap = {"initial": "Initial", "partial": "Partial", "complete": "Complete"};
    
    final payload = {
      "TaskId": taskId,
      "ProgressStatus": statusMap[_localStatus[taskId]] ?? "Initial",
      "Remarks": _localRemarks[taskId] ?? "",
      "Score": int.tryParse(_localScores[taskId] ?? "")
    };

    bool success = await _viewModel.evaluateTask(payload);
    
    if (mounted) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(success ? "Evaluation Saved ✅" : "Failed to save ❌"))
      );
      if (success) _loadData();
    }
  }

  Future<void> _deleteTask(int taskId) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Task?"),
        content: const Text("Are you sure you want to delete this task?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("No"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Yes, Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      bool success = await _viewModel.deleteTask(taskId);
      if (success) {
        await _loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Task Deleted"), backgroundColor: Colors.red),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Failed to delete task"), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<void> _showEditDialog(Map<String, dynamic> task) async {
    final titleController = TextEditingController(text: task['title']);
    final descController = TextEditingController(text: task['description'] ?? "");
    DateTime dueDate = DateTime.parse(task['dueDate']);
    bool isPptRequired = task['isPptRequired'] ?? false;
    int completionPercentage = (task['completionPercentage'] ?? 0) as int;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text("Edit Task"),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setDialogState) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(labelText: "Task Title"),
                    ),
                    TextField(
                      controller: descController,
                      maxLines: 3,
                      decoration: const InputDecoration(labelText: "Description"),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Text("Due Date: "),
                        TextButton(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: dueDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2030),
                            );
                            if (picked != null) {
                              setDialogState(() => dueDate = picked);
                            }
                          },
                          child: Text(DateFormat('yyyy-MM-dd').format(dueDate)),
                        ),
                      ],
                    ),
                    SwitchListTile(
                      title: const Text("PPT Required"),
                      value: isPptRequired,
                      onChanged: (val) => setDialogState(() => isPptRequired = val),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<int>(
                      decoration: const InputDecoration(labelText: "Task Status", border: OutlineInputBorder()),
                      value: completionPercentage,
                      items: const [
                        DropdownMenuItem(value: 0, child: Text("Initial (0%)")),
                        DropdownMenuItem(value: 50, child: Text("Partially Complete (50%)")),
                        DropdownMenuItem(value: 100, child: Text("Fully Complete (100%)")),
                      ],
                      onChanged: (val) => setDialogState(() => completionPercentage = val ?? 0),
                    ),
                  ],
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                final body = {
                  "Title": titleController.text,
                  "Description": descController.text,
                  "DueDate": dueDate.toIso8601String(),
                  "IsPptRequired": isPptRequired,
                  "CompletionPercentage": completionPercentage,
                  "TaskStatus": completionPercentage == 0 ? "Initial" : (completionPercentage == 100 ? "Fully Complete" : "Partially Complete")
                };

                Navigator.pop(dialogContext);

                bool success = await _viewModel.updateTask(task['id'], body);

                if (success) {
                  await _loadData();
                }

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(success ? "Task Updated" : "Update Failed"),
                      backgroundColor: success ? Colors.green : Colors.red,
                    ),
                  );
                }
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("Tasks (${_activeTab})", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios, size: 18), onPressed: () => Navigator.pop(context)),
      ),
      body: Column(
        children: [
          // FYP Toggle
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _fypTab("FYP-1"),
                const SizedBox(width: 8),
                _fypTab("FYP-2"),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Uncompleted / Completed Tabs
          Row(
            children: [
              _subTab("uncompleted", "Uncompleted"),
              _subTab("completed", "Completed"),
            ],
          ),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _visibleTasks.isEmpty
                    ? const Center(child: Text("No tasks found", style: TextStyle(color: Colors.grey)))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _visibleTasks.length,
                        itemBuilder: (context, index) {
                          final task = _visibleTasks[index];
                          return _taskCard(task);
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => AssignTaskView(userMap: widget.userMap))),
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _fypTab(String label) {
    bool active = _activeTab == label;
    return Expanded(
      child: GestureDetector(
        onTap: () => _switchTab(label),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: active ? Colors.blue : Colors.white,
            border: Border.all(color: active ? Colors.blue : Colors.grey.shade200),
            borderRadius: BorderRadius.circular(20),
          ),
          alignment: Alignment.center,
          child: Text(label, style: TextStyle(color: active ? Colors.white : Colors.black87, fontWeight: FontWeight.bold, fontSize: 12)),
        ),
      ),
    );
  }

  Widget _subTab(String key, String label) {
    bool active = _taskTab == key;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _taskTab = key),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: active ? Colors.blue : Colors.transparent, width: 2)),
          ),
          alignment: Alignment.center,
          child: Text(label, style: TextStyle(color: active ? Colors.blue : Colors.grey, fontWeight: active ? FontWeight.bold : FontWeight.normal)),
        ),
      ),
    );
  }

  Widget _taskCard(Map<String, dynamic> task) {
    final id = task['Id'];
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(task['StudentName'] ?? "Whole Group", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
              Text("Group ${task['GroupId']}", style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
            ],
          ),
          const SizedBox(height: 4),
          Text(task['Title'] ?? "No Title", style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          const Divider(height: 24),

          // Status Radios (Primary Schooler style)
          const Text("Evaluation Status", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          Row(
            children: ["initial", "partial", "complete"].map((s) => _statusRadio(id, s)).toList(),
          ),
          const SizedBox(height: 16),

          // Remarks
          _label("Supervisor Remarks"),
          TextField(
            onChanged: (v) => _localRemarks[id] = v,
            decoration: _inputDeco("Add feedback..."),
            maxLines: 2,
          ),
          const SizedBox(height: 12),

          // Score
          _label("Score (Optional)"),
          TextField(
            keyboardType: TextInputType.number,
            onChanged: (v) => _localScores[id] = v,
            decoration: _inputDeco("0-100"),
          ),
          const SizedBox(height: 20),

          // Save Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _saveEvaluation(id),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              child: const Text("Save Evaluation"),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusRadio(int taskId, String status) {
    bool selected = _localStatus[taskId] == status;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _localStatus[taskId] = status),
        child: Row(
          children: [
            Icon(selected ? Icons.radio_button_checked : Icons.radio_button_off, size: 16, color: selected ? Colors.blue : Colors.grey),
            const SizedBox(width: 4),
            Text(status, style: TextStyle(fontSize: 12, color: selected ? Colors.black : Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Padding(padding: const EdgeInsets.only(bottom: 6), child: Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87)));
  }

  InputDecoration _inputDeco(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 12, color: Colors.grey),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      filled: true,
      fillColor: Colors.grey.shade50,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
    );
  }
}
