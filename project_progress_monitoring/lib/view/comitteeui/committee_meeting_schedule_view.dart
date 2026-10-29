import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../viewmodels/comitteeviewmodel/committee_meeting_schedule_view_model.dart'; // Update path if needed

class CommitteeMeetingScheduleView extends StatefulWidget {
  // Pass FYP-1 or FYP-2 from the Dashboard
  final String fypType;
  final List<Map<String, dynamic>> userData;

  const CommitteeMeetingScheduleView({super.key, required this.fypType, required this.userData});

  @override
  State<CommitteeMeetingScheduleView> createState() => _CommitteeMeetingScheduleViewState();
}

class _CommitteeMeetingScheduleViewState extends State<CommitteeMeetingScheduleView> {
  final CommitteeMeetingScheduleViewModel _viewModel = CommitteeMeetingScheduleViewModel();
  int _bottomNavIndex = 1; // Default to 'Meetings' tab

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _viewModel.startDate = picked;
        } else {
          _viewModel.endDate = picked;
        }
      });
      _viewModel.loadPreview(widget.fypType).then((_) => setState(() {}));
    }
  }

  Future<void> _selectTime(BuildContext context, bool isStart) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _viewModel.startTime = picked;
        } else {
          _viewModel.endTime = picked;
        }
      });
    }
  }

  void _submitMeeting() async {
    setState(() => _viewModel.isLoading = true);

    String userId = widget.userData.isNotEmpty ? widget.userData[0]['id'].toString() : '';

    // Call the API via ViewModel
    final result = await _viewModel.scheduleMeeting(widget.fypType, context, userId);

    setState(() => _viewModel.isLoading = false);

    if (result != null && mounted) {
      showDialog(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text('✅ Meeting Scheduled'),
          content: Text(
            'Groups: ${result['totalGroups'] ?? 0}\n'
            'Days: ${result['totalDays'] ?? 0}\n'
            'Per Day: ${result['groupsPerDay'] ?? 0}',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(c); // close dialog
                Navigator.pop(context); // go back to dashboard
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Create Meeting (${widget.fypType})',
          style: const TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      // Fully scrollable body
      body: _viewModel.isLoading
          ? const Center(child: CircularProgressIndicator()) // Shows loader while saving
          : SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionLabel('Meeting Title'),
            _buildTextField('e.g., Weekly Project Review', (val) => _viewModel.title = val),

            const SizedBox(height: 16),
            _buildSectionLabel('Description'),
            _buildTextField('Enter key topics and objectives...', (val) => _viewModel.description = val, maxLines: 3),

            const SizedBox(height: 16),
            _buildSectionLabel('Location / Venue'),
            _buildTextField('e.g. Committee Room 1 / Online Link', (val) => _viewModel.location = val),

            const SizedBox(height: 20),
            Row(
              children: const [
                Icon(Icons.calendar_today_outlined, size: 18, color: Colors.grey),
                SizedBox(width: 8),
                Text('Recurrence Range', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildDatePicker('Start Date', _viewModel.startDate, () => _selectDate(context, true))),
                const SizedBox(width: 16),
                Expanded(child: _buildDatePicker('End Date', _viewModel.endDate, () => _selectDate(context, false))),
              ],
            ),

            const SizedBox(height: 20),
            Row(
              children: const [
                Icon(Icons.access_time_outlined, size: 18, color: Colors.grey),
                SizedBox(width: 8),
                Text('Daily Time Slot', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildTimePicker('Start Time', _viewModel.startTime, () => _selectTime(context, true))),
                const SizedBox(width: 16),
                Expanded(child: _buildTimePicker('End Time', _viewModel.endTime, () => _selectTime(context, false))),
              ],
            ),

            const SizedBox(height: 20),
            Row(
              children: const [
                Icon(Icons.repeat, size: 18, color: Colors.grey),
                SizedBox(width: 8),
                Text('Select Recurrence Days', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              ],
            ),
            const SizedBox(height: 12),
            const SizedBox(height: 12),
            _buildDaysSelector(),

            if (_viewModel.previewResult != null) ...[
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8)
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('📊 Distribution Preview', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('Total Groups: ${_viewModel.previewResult!['totalGroups']}'),
                    Text('Total Days: ${_viewModel.previewResult!['totalDays']}'),
                    Text('Groups / Day: ${_viewModel.previewResult!['groupsPerDay']}'),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),

            // --- Checkboxes ---
            Container(
              decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8)
              ),
              child: Column(
                children: [
                  CheckboxListTile(
                    title: const Text("Is this a Graded Meeting?", style: TextStyle(fontWeight: FontWeight.w500)),
                    secondary: const Icon(Icons.school_outlined, color: Colors.purple),
                    activeColor: Colors.blue,
                    value: _viewModel.isGraded,
                    onChanged: (val) {
                      setState(() => _viewModel.isGraded = val ?? false);
                      if (_viewModel.isGraded) {
                    _viewModel.fetchAvailableCriteria(widget.fypType).then((_) => setState(() {}));
                      }
                    },
                  ),
                  if (_viewModel.isGraded && _viewModel.availableCriteria.isNotEmpty) ...[
                    const Divider(height: 0),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Select Criteria", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          const SizedBox(height: 12),
                          ..._viewModel.availableCriteria.map((criteria) {
                            final int id = criteria['id'];
                            final bool isSelected = _viewModel.selectedParameterIds.contains(id);
                            return CheckboxListTile(
                              title: Text("${criteria['name']} (${criteria['percentage']}%)"),
                              subtitle: Text((criteria['subParameters'] as List).map((s) => "• ${s['name']}").join("\n")),
                              value: isSelected,
                              onChanged: (val) {
                                setState(() {
                                  if (val == true) {
                                    _viewModel.selectedParameterIds.add(id);
                                  } else {
                                    _viewModel.selectedParameterIds.remove(id);
                                  }
                                });
                              },
                              controlAffinity: ListTileControlAffinity.leading,
                              dense: true,
                            );
                          }).toList(),
                        ],
                      ),
                    ),
                  ],
                  const Divider(height: 0),
                  CheckboxListTile(
                    title: const Text("Is PPT/File Required?", style: TextStyle(fontWeight: FontWeight.w500)),
                    secondary: const Icon(Icons.insert_drive_file_outlined, color: Colors.blue),
                    activeColor: Colors.blue,
                    value: _viewModel.isFileRequired,
                    onChanged: (val) => setState(() => _viewModel.isFileRequired = val ?? false),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // --- Create Meeting Button ---
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _submitMeeting,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Create Meeting', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 40), // Extra padding at bottom to prevent scrolling clipping
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _bottomNavIndex,
        onTap: (index) {
          if (index == 0) Navigator.pop(context); // Go back to Dashboard
          setState(() => _bottomNavIndex = index);
        },
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'Meetings'),
          BottomNavigationBarItem(icon: Icon(Icons.check_box_outlined), label: 'Tasks'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }

  // --- Helper Widgets ---
  Widget _buildSectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
    );
  }

  Widget _buildTextField(String hint, Function(String) onChanged, {int maxLines = 1}) {
    return TextField(
      onChanged: onChanged,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.blue)),
      ),
    );
  }

  Widget _buildDatePicker(String label, DateTime? date, VoidCallback onTap) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 4),
        InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(date == null ? 'mm/dd/yyyy' : DateFormat('MM/dd/yyyy').format(date), style: TextStyle(color: date == null ? Colors.grey : Colors.black)),
                const Icon(Icons.calendar_today_outlined, size: 16, color: Colors.grey),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimePicker(String label, TimeOfDay? time, VoidCallback onTap) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 4),
        InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(time == null ? '--:--' : time.format(context), style: TextStyle(color: time == null ? Colors.grey : Colors.black)),
                const Icon(Icons.access_time, size: 16, color: Colors.grey),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDaysSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(7, (index) {
        bool isSelected = _viewModel.selectedDays[index];
        String dayText = _viewModel.dayLabels[index];
        return GestureDetector(
          onTap: () {
            setState(() => _viewModel.toggleDay(index));
            _viewModel.loadPreview(widget.fypType).then((_) => setState(() {}));
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
            decoration: BoxDecoration(
              color: isSelected ? Colors.blue : Colors.transparent,
              border: Border.all(color: isSelected ? Colors.blue : Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              dayText,
              style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : Colors.black87, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
            ),
          ),
        );
      }),
    );
  }
}