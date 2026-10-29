import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import '../../viewmodels/supervisorviewmodel/assign_task_viewmodel.dart';

class AssignTaskView extends StatefulWidget {
  final Map<String, dynamic> userMap;
  final int? initialGroupId;
  final String? initialFypType;
  final int? initialMeetingId; // NEW: The specific meeting we clicked on

  final String? initialStudentId;
  final String? initialStudentName;

  const AssignTaskView({
    super.key,
    required this.userMap,
    this.initialGroupId,
    this.initialFypType,
    this.initialMeetingId, // Add to constructor
    this.initialStudentId,
    this.initialStudentName,
  });

  @override
  State<AssignTaskView> createState() => _AssignTaskViewState();
}

class _AssignTaskViewState extends State<AssignTaskView> {
  final AssignTaskViewModel _viewModel = AssignTaskViewModel();
  final _formKey = GlobalKey<FormState>();

  String _activeTab = "FYP-1"; // Subject Type
  String _assigneeType = "group"; // group | individual
  bool _isLoading = false;
  bool _isLoadingDetails = false;

  // Selections
  int? _selectedGroupId;
  String? _selectedMemberId; // Registration Number
  int? _selectedMeetingId; // For auto-fill

  // Data Lists
  List<dynamic> _groups = [];
  List<dynamic> _members = [];
  List<dynamic> _meetings = [];

  // Controllers
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();

  // Settings
  DateTime? _dueDate;
  bool _isPptRequired = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialFypType != null) {
      _activeTab = widget.initialFypType!;
    }
    _loadGroups();
  }

  Future<void> _loadGroups() async {
    setState(() => _isLoading = true);
    final data = await _viewModel.fetchGroups(widget.userMap['id'].toString(), _activeTab);
    if (mounted) {
      setState(() {
        _groups = data;
        _isLoading = false;
        // If we came from another screen with an ID, pick it!
        if (widget.initialGroupId != null) {
          _selectedGroupId = widget.initialGroupId;
          _loadGroupDetails(widget.initialGroupId!);
        }
      });
    }
  }

  Future<void> _loadGroupDetails(int groupId) async {
    setState(() => _isLoadingDetails = true);
    
    // 🏫 SCHOOL LESSON: We use Promise.all logic from React!
    // We fetch members AND meetings at the same time.
    final results = await Future.wait([
      _viewModel.fetchGroupMembers(groupId),
      _viewModel.fetchMeetings(widget.userMap['id'].toString(), _activeTab),
    ]);

    if (mounted) {
      setState(() {
        _members = results[0];
        
        // PRIMARY SCHOOLER NOTE: We filter the meetings so only the ones for THIS group show up!
        // We check for 'GroupId' and 'groupId' just to be safe.
        _meetings = (results[1] as List).where((m) {
          final mGroupId = m['GroupId'] ?? m['groupId'];
          return mGroupId == groupId;
        }).toList();
        
        // If we were sent a specific meeting ID, we select it automatically!
        if (widget.initialMeetingId != null) {
          _onMeetingSelected(widget.initialMeetingId);
        }

        // Pre-select student if passed from navigation
        if (widget.initialStudentId != null) {
          _assigneeType = "individual";
          _selectedMemberId = widget.initialStudentId;
        }

        _isLoadingDetails = false;
      });
    }
  }

  void _onMeetingSelected(int? meetingId) {
    if (meetingId == null) {
      setState(() => _selectedMeetingId = null);
      return;
    }
    
    final meeting = _meetings.firstWhere((m) => m['Id'] == meetingId, orElse: () => null);
    if (meeting != null) {
      setState(() {
        _selectedMeetingId = meetingId;
        _titleController.text = meeting['Title'] ?? "";
        _descController.text = meeting['Description'] ?? "";
        if (meeting['Date'] != null) {
          _dueDate = DateTime.tryParse(meeting['Date']);
        }
      });
    }
  }

  void _switchTab(String tab) {
    if (_activeTab == tab) return;
    setState(() => _activeTab = tab);
    _loadGroups();
  }

  Future<void> _selectDueDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime(DateTime.now().year + 2),
    );
    if (picked != null) {
      setState(() => _dueDate = picked);
    }
  }

  // Helper method to extract student regNum from "Name (RegNum)" format
  String _extractStudentId(String fullNameAndId) {
    try {
      return fullNameAndId.split('(')[1].replaceAll(')', '').trim();
    } catch (e) {
      return fullNameAndId;
    }
  }

  void _submitForm() async {
    if (_selectedGroupId == null || _titleController.text.isEmpty || _dueDate == null) {
      _showMsg("Group, Title and Due Date are required"); return;
    }

    if (_assigneeType == "individual" && _selectedMemberId == null) {
      _showMsg("Please select a student"); return;
    }

    setState(() => _isLoading = true);

    // 🏫 SCHOOL LESSON: Create the "Task Package" to send to the server!
    Map<String, dynamic> payload = {
      "Title": _titleController.text.trim(),
      "Description": _descController.text.trim(),
      "DueDate": _dueDate!.toIso8601String(),
      "SupervisorId": widget.userMap['id'].toString(),
      "GroupId": _selectedGroupId,
      "AssigneeType": _assigneeType,
      "StudentId": _assigneeType == "individual" ? _selectedMemberId : null,
      "IsPptRequired": _isPptRequired
    };

    bool success = await _viewModel.submitTask(payload);

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        _showMsg("Task Assigned Successfully ✅");
        Navigator.pop(context);
      } else {
        _showMsg("Failed to assign task ❌");
      }
    }
  }

  void _showMsg(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Assign New Task", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // FYP Type Tabs
                  _label("Subject Type"),
                  Row(
                    children: [
                      _tab("FYP-1"),
                      const SizedBox(width: 8),
                      _tab("FYP-2"),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Group Selector
                  _label("Select Group"),
                  DropdownButtonHideUnderline(
                    child: DropdownButton2<int>(
                      isExpanded: true,
                      hint: const Text("Choose group", style: TextStyle(fontSize: 13, color: Colors.grey)),
                      value: _selectedGroupId,
                      items: _groups.map<DropdownMenuItem<int>>((g) {
                        final id = g['GroupId'] ?? g['groupName'];
                        return DropdownMenuItem<int>(
                          value: id,
                          child: Text("Group $id", style: const TextStyle(fontSize: 13)),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedGroupId = val;
                          _selectedMemberId = null;
                          _selectedMeetingId = null;
                        });
                        if (val != null) _loadGroupDetails(val);
                      },
                      buttonStyleData: ButtonStyleData(
                        height: 50,
                        padding: const EdgeInsets.only(right: 14),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: Colors.grey.shade50,
                        ),
                      ),
                      dropdownStyleData: DropdownStyleData(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  if (_selectedGroupId != null) ...[
                    // Assign To (Toggle)
                    _label("Assign To"),
                    Row(
                      children: [
                        _assigneeTab("group", "Whole Group"),
                        const SizedBox(width: 8),
                        _assigneeTab("individual", "Individual"),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Individual Selector
                    if (_assigneeType == "individual") ...[
                      _label("Select Student"),
                      _isLoadingDetails
                          ? const LinearProgressIndicator()
                          : DropdownButtonFormField<String>(
                              value: _selectedMemberId,
                              decoration: _inputDeco("Choose student"),
                              items: _members.map<DropdownMenuItem<String>>((m) {
                                return DropdownMenuItem<String>(
                                  value: m['RegNum'],
                                  child: Text("${m['StudentName']} (${m['RegNum']})"),
                                );
                              }).toList(),
                              onChanged: (val) => setState(() => _selectedMemberId = val),
                            ),
                      const SizedBox(height: 20),
                    ],

                    // Auto-fill from Meeting
                    _label("Auto-fill from Meeting (Optional)"),
                    DropdownButtonFormField<int>(
                      value: _selectedMeetingId,
                      decoration: _inputDeco("Choose meeting"),
                      items: [
                        const DropdownMenuItem<int>(value: null, child: Text("None")),
                        ..._meetings.map<DropdownMenuItem<int>>((m) {
                          return DropdownMenuItem<int>(
                            value: m['Id'],
                            child: Text(m['Title'] ?? "Meeting ${m['Id']}"),
                          );
                        })
                      ],
                      onChanged: _onMeetingSelected,
                    ),
                    const SizedBox(height: 20),

                    // Title & Description
                    _label("Task Title"),
                    TextField(controller: _titleController, decoration: _inputDeco("Enter title")),
                    const SizedBox(height: 16),

                    _label("Task Description"),
                    TextField(controller: _descController, maxLines: 3, decoration: _inputDeco("Enter description")),
                    const SizedBox(height: 16),

                    // Due Date
                    _label("Due Date"),
                    _dateBtn(_dueDate, "Select Date", (d) => setState(() => _dueDate = d)),
                    const SizedBox(height: 16),

                    // PPT Toggle
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("PPT Required", style: TextStyle(fontWeight: FontWeight.w500)),
                        Switch(value: _isPptRequired, onChanged: (v) => setState(() => _isPptRequired = v), activeColor: Colors.blue),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submitForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text("Assign Task", style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _tab(String label) {
    bool active = _activeTab == label;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _activeTab = label;
            _selectedGroupId = null;
          });
          _loadGroups();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: active ? Colors.blue : Colors.white,
            border: Border.all(color: active ? Colors.blue : Colors.grey.shade200),
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(label, style: TextStyle(color: active ? Colors.white : Colors.black87, fontWeight: FontWeight.bold, fontSize: 13)),
        ),
      ),
    );
  }

  Widget _assigneeTab(String type, String label) {
    bool active = _assigneeType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          _assigneeType = type;
          _selectedMemberId = null;
        }),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: active ? Colors.blue.shade50 : Colors.white,
            border: Border.all(color: active ? Colors.blue : Colors.grey.shade200),
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(label, style: TextStyle(color: active ? Colors.blue : Colors.black87, fontWeight: FontWeight.bold, fontSize: 13)),
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87)),
    );
  }

  InputDecoration _inputDeco(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      filled: true,
      fillColor: Colors.grey.shade50,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
    );
  }

  Widget _dateBtn(DateTime? date, String label, Function(DateTime) onPick) {
    return InkWell(
      onTap: () async {
        final d = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime.now(), lastDate: DateTime(2030));
        if (d != null) onPick(d);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(10)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(date == null ? label : DateFormat('yyyy-MM-dd').format(date), style: TextStyle(fontSize: 13, color: date == null ? Colors.grey : Colors.black)),
            const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}