import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../viewmodels/supervisorviewmodel/schedule_meeting_viewmodel.dart';


class ScheduleMeetingView extends StatefulWidget {
  final Map<String, dynamic> userMap;

  const ScheduleMeetingView({super.key, required this.userMap});

  @override
  State<ScheduleMeetingView> createState() => _ScheduleMeetingViewState();
}

class _ScheduleMeetingViewState extends State<ScheduleMeetingView> {
  final ScheduleMeetingViewModel _viewModel = ScheduleMeetingViewModel();
  final _formKey = GlobalKey<FormState>();

  String _mode = "group"; // group | individual
  String _activeFYP = "FYP-1"; // Toggle for FYP-1 / FYP-2
  
  final Map<String, bool> _selectedDays = {
    'mon': false, 'tue': false, 'wed': false, 'thu': false, 'fri': false, 'sat': false, 'sun': false,
  };

  // Selections
  int? _selectedGroupId;
  String? _selectedMemberId; // RegNum

  // Controllers
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _venueController = TextEditingController();

  // Date and Time
  DateTime? _startDate;
  DateTime? _endDate;
  TimeOfDay _time = const TimeOfDay(hour: 10, minute: 0);
  bool _pptRequired = false;

  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  Future<void> _loadGroups() async {
    setState(() => _viewModel.isLoadingGroups = true);
    await _viewModel.fetchGroupsForDropdown(widget.userMap['id'].toString(), _activeFYP);
    
    // Clear selections when changing FYP type
    _selectedGroupId = null;
    _selectedMemberId = null;
    _viewModel.students.clear();
    
    if (mounted) setState(() {});
  }

  Future<void> _loadStudents(int groupId) async {
    await _viewModel.fetchGroupStudents(groupId);
    if (mounted) setState(() {});
  }

  void _toggleDay(String day) {
    setState(() {
      _selectedDays[day] = !(_selectedDays[day] ?? false);
    });
  }

  String _getSelectedDaysString() {
    final map = {'mon': 'Mon', 'tue': 'Tue', 'wed': 'Wed', 'thu': 'Thu', 'fri': 'Fri', 'sat': 'Sat', 'sun': 'Sun'};
    return _selectedDays.entries
        .where((e) => e.value)
        .map((e) => map[e.key])
        .join(",");
  }


  /// 🏫 SCHOOL LESSON: What happens when you click "Save Schedule"!
  void _submitForm() async {
    // 1. Check if they picked a group. If not, show a message and STOP.
    if (_selectedGroupId == null) {
      _showMsg("Select group"); return;
    }
    // 2. If they picked "Individual", they MUST pick a student too!
    if (_mode == "individual" && _selectedMemberId == null) {
      _showMsg("Select student"); return;
    }
    // 3. Make sure the Title, Start Date, and End Date are not empty.
    if (_titleController.text.isEmpty || _startDate == null || _endDate == null) {
      _showMsg("Fill required fields"); return;
    }
    
    // 4. Make sure at least one day (like Mon or Tue) is picked.
    String days = _getSelectedDaysString();
    if (days.isEmpty) {
      _showMsg("Select at least one day"); return;
    }

    // 5. Turn the clock time (like 10:00 AM) into a computer format (10:00:00).
    String timeStr = "${_time.hour.toString().padLeft(2, '0')}:${_time.minute.toString().padLeft(2, '0')}:00";

    // 6. Put all the information into a "Digital Box" (Map) to send to the server.
    Map<String, dynamic> data = {
      "SupervisorId": widget.userMap['id'].toString(),
      "GroupId": _selectedGroupId,
      "MemberId": _mode == "individual" ? _selectedMemberId : null,
      "Title": _titleController.text.trim(),
      "Description": _descController.text.trim(),
      "StartDate": _startDate!.toIso8601String(),
      "EndDate": _endDate!.toIso8601String(),
      "Time": timeStr,
      "Days": days,
      "Location": _venueController.text.trim(),
      "PptRequired": _pptRequired,
      "FilePath": "" // No file upload in this simple version
    };

    // 7. Hand the box to the ViewModel and wait for it to finish.
    var result = await _viewModel.scheduleMeeting(data);

    // 8. If the app is still open (mounted), show the result message!
    if (mounted) {
      _showMsg(result['message']);
      if (result['success']) {
        // If it worked, wait 1 second and then go back to the previous screen.
        Future.delayed(const Duration(seconds: 1), () => Navigator.pop(context));
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
        title: const Text("Schedule Meeting", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _viewModel.isLoadingGroups
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Mode Toggle (Group / Individual)
                  Row(
                    children: [
                      _modeTab("group", "Group"),
                      const SizedBox(width: 8),
                      _modeTab("individual", "Individual"),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // FYP Toggle
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      children: ["FYP-1", "FYP-2"].map((type) {
                        bool isActive = _activeFYP == type;
                        return Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() => _activeFYP = type);
                              _loadGroups(); // Reload groups for the new FYP
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: isActive ? Colors.white : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: isActive ? [const BoxShadow(color: Colors.black12, blurRadius: 2)] : [],
                              ),
                              child: Center(child: Text(type, style: TextStyle(fontWeight: FontWeight.bold, color: isActive ? Colors.blueAccent : Colors.grey))),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Group Dropdown
                  _label("Select Group"),
                  DropdownButtonFormField<int>(
                    value: _selectedGroupId,
                    decoration: _inputDeco("Select"),
                    items: _viewModel.groups.map<DropdownMenuItem<int>>((g) {
                      return DropdownMenuItem<int>(
                        value: g['groupName'], // Uses 'groupName' key from backend as the ID
                        child: Text("Group ${g['groupName']}"),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedGroupId = val;
                        _selectedMemberId = null;
                      });
                      if (_mode == "individual" && val != null) _loadStudents(val);
                    },
                  ),
                  const SizedBox(height: 16),

                  // Student Dropdown (Individual mode only)
                  if (_mode == "individual" && _selectedGroupId != null) ...[
                    _label("Select Student"),
                    _viewModel.isLoadingStudents
                        ? const LinearProgressIndicator()
                        : DropdownButtonFormField<String>(
                            value: _selectedMemberId,
                            decoration: _inputDeco("Select Student"),
                            items: _viewModel.students.map<DropdownMenuItem<String>>((s) {
                              return DropdownMenuItem<String>(
                                value: s['RegNum'],
                                child: Text(s['StudentName']),
                              );
                            }).toList(),
                            onChanged: (val) => setState(() => _selectedMemberId = val),
                          ),
                    const SizedBox(height: 16),
                  ],

                  // Title
                  _label("Title"),
                  TextField(controller: _titleController, decoration: _inputDeco("Enter title")),
                  const SizedBox(height: 16),

                  // Description
                  _label("Description"),
                  TextField(controller: _descController, maxLines: 3, decoration: _inputDeco("Enter description")),
                  const SizedBox(height: 16),

                  // Location
                  _label("Location"),
                  TextField(controller: _venueController, decoration: _inputDeco("Enter location")),
                  const SizedBox(height: 16),

                  // Date Range
                  _label("Schedule Dates"),
                  Row(
                    children: [
                      Expanded(child: _dateBtn(_startDate, "Start", (d) => setState(() => _startDate = d))),
                      const SizedBox(width: 8),
                      Expanded(child: _dateBtn(_endDate, "End", (d) => setState(() => _endDate = d))),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Time
                  _label("Meeting Time"),
                  InkWell(
                    onTap: () async {
                      final t = await showTimePicker(
                        context: context,
                        initialTime: _time,
                      );
                      if (t != null) setState(() => _time = t);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(10)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_time.format(context), style: const TextStyle(fontSize: 13, color: Colors.black)),
                          const Icon(Icons.access_time, size: 14, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Days Selector
                  _label("Select Days"),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 40,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: _selectedDays.keys.map((d) {
                        bool sel = _selectedDays[d]!;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(d.toUpperCase(), style: TextStyle(fontSize: 10, color: sel ? Colors.white : Colors.black)),
                            selected: sel,
                            onSelected: (_) => _toggleDay(d),
                            selectedColor: Colors.blue,
                            backgroundColor: Colors.grey.shade100,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // PPT Toggle
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("PPT Required", style: TextStyle(fontWeight: FontWeight.w500)),
                      Switch(value: _pptRequired, onChanged: (v) => setState(() => _pptRequired = v), activeColor: Colors.blue),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _viewModel.isSaving ? null : _submitForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                      child: _viewModel.isSaving
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text("Save Schedule", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _modeTab(String mode, String label) {
    bool active = _mode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          _mode = mode;
          _selectedMemberId = null;
        }),
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
        if (label.contains(":")) { // Time picker trigger
          return;
        }
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