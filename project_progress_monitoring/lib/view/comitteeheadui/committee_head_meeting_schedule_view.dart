import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../viewmodels/comitteeheadviewmodel/committee_head_meeting_schedule_view_model.dart';

class CommitteeHeadMeetingScheduleView extends StatefulWidget {
  final String fypType;
  const CommitteeHeadMeetingScheduleView({super.key, required this.fypType});

  @override
  State<CommitteeHeadMeetingScheduleView> createState() => _CommitteeHeadMeetingScheduleViewState();
}

class _CommitteeHeadMeetingScheduleViewState extends State<CommitteeHeadMeetingScheduleView> {
  final CommitteeHeadMeetingScheduleViewModel _viewModel = CommitteeHeadMeetingScheduleViewModel();

  Future<void> _pickDate(bool isStart) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        if (isStart) _viewModel.startDate = picked;
        else _viewModel.endDate = picked;
      });
    }
  }

  Future<void> _pickTime(bool isStart) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        if (isStart) _viewModel.startTime = picked;
        else _viewModel.endTime = picked;
      });
    }
  }

  void _submit() async {
    setState(() => _viewModel.isLoading = true);
    bool success = await _viewModel.scheduleMeeting(widget.fypType, context);
    setState(() => _viewModel.isLoading = false);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Meeting Scheduled!'), backgroundColor: Colors.indigo),
      );
      Navigator.pop(context);
    } else if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to schedule meeting'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Schedule Meeting (${widget.fypType})',
            style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: _viewModel.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _label('Meeting Title'),
                  _textField('e.g., Weekly Review', (v) => _viewModel.title = v),
                  const SizedBox(height: 14),

                  _label('Description'),
                  _textField('Topics and objectives...', (v) => _viewModel.description = v, maxLines: 3),
                  const SizedBox(height: 14),

                  _label('Venue'),
                  _textField('e.g. Committee Room 1', (v) => _viewModel.location = v),
                  const SizedBox(height: 20),

                  // Dates
                  Row(
                    children: [
                      Expanded(child: _datePicker('Start Date', _viewModel.startDate, () => _pickDate(true))),
                      const SizedBox(width: 12),
                      Expanded(child: _datePicker('End Date', _viewModel.endDate, () => _pickDate(false))),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Times
                  Row(
                    children: [
                      Expanded(child: _timePicker('Start Time', _viewModel.startTime, () => _pickTime(true))),
                      const SizedBox(width: 12),
                      Expanded(child: _timePicker('End Time', _viewModel.endTime, () => _pickTime(false))),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Days
                  _label('Recurrence Days'),
                  const SizedBox(height: 8),
                  _buildDaysSelector(),
                  const SizedBox(height: 20),

                  // Graded toggle
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      children: [
                        SwitchListTile(
                          title: const Text("Graded Meeting", style: TextStyle(fontWeight: FontWeight.w500)),
                          secondary: const Icon(Icons.school_outlined, color: Colors.indigo),
                          value: _viewModel.isGraded,
                          activeColor: Colors.indigo,
                          onChanged: (val) {
                            setState(() => _viewModel.isGraded = val);
                            if (val) {
                              _viewModel.fetchAvailableCriteria(widget.fypType).then((_) => setState(() {}));
                            } else {
                              setState(() {
                                _viewModel.availableCriteria = [];
                                _viewModel.selectedParameterIds = [];
                              });
                            }
                          },
                        ),

                        // Show criteria selector only when isGraded = true
                        if (_viewModel.isGraded) ...[
                          const Divider(height: 1),
                          if (_viewModel.isCriteriaLoading)
                            const Padding(
                              padding: EdgeInsets.all(16),
                              child: Center(child: CircularProgressIndicator()),
                            )
                          else if (_viewModel.availableCriteria.isEmpty)
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Text(
                                "No criteria set for ${widget.fypType}. Ask Committee Head to create them first.",
                                style: const TextStyle(color: Colors.grey, fontSize: 13),
                              ),
                            )
                          else
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text("Select Evaluation Parameters",
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                  const SizedBox(height: 8),
                                  ..._viewModel.availableCriteria.map((criteria) {
                                    int id = criteria['id'] ?? 0;
                                    bool isSel = _viewModel.selectedParameterIds.contains(id);
                                    List subParams = criteria['subParameters'] ?? [];
                                    return CheckboxListTile(
                                      contentPadding: EdgeInsets.zero,
                                      title: Text(
                                        "${criteria['name']} (${criteria['percentage']}%)",
                                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                                      ),
                                      subtitle: subParams.isNotEmpty
                                          ? Text(
                                              subParams.map((s) => "• ${s['name']}").join("\n"),
                                              style: const TextStyle(fontSize: 11, color: Colors.grey),
                                            )
                                          : null,
                                      value: isSel,
                                      activeColor: Colors.indigo,
                                      onChanged: (val) {
                                        setState(() {
                                          if (val == true) {
                                            _viewModel.selectedParameterIds.add(id);
                                          } else {
                                            _viewModel.selectedParameterIds.remove(id);
                                          }
                                        });
                                      },
                                    );
                                  }).toList(),
                                ],
                              ),
                            ),
                        ],

                        const Divider(height: 1),
                        SwitchListTile(
                          title: const Text("PPT/File Required", style: TextStyle(fontWeight: FontWeight.w500)),
                          secondary: const Icon(Icons.insert_drive_file_outlined, color: Colors.blue),
                          value: _viewModel.isFileRequired,
                          activeColor: Colors.indigo,
                          onChanged: (val) => setState(() => _viewModel.isFileRequired = val),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Create Meeting',
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
      );

  Widget _textField(String hint, Function(String) onChange, {int maxLines = 1}) {
    return TextField(
      onChanged: onChange,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
      ),
    );
  }

  Widget _datePicker(String label, DateTime? date, VoidCallback onTap) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 4),
        InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  date == null ? 'Select' : DateFormat('MM/dd/yyyy').format(date),
                  style: TextStyle(color: date == null ? Colors.grey : Colors.black, fontSize: 13),
                ),
                const Icon(Icons.calendar_today_outlined, size: 16, color: Colors.grey),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _timePicker(String label, TimeOfDay? time, VoidCallback onTap) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 4),
        InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  time == null ? 'Select' : time.format(context),
                  style: TextStyle(color: time == null ? Colors.grey : Colors.black, fontSize: 13),
                ),
                const Icon(Icons.access_time_outlined, size: 16, color: Colors.grey),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDaysSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(7, (i) {
        bool isSel = _viewModel.selectedDays[i];
        String day = _viewModel.dayLabels[i].substring(0, 1).toUpperCase() +
            _viewModel.dayLabels[i].substring(1);
        return GestureDetector(
          onTap: () => setState(() => _viewModel.toggleDay(i)),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSel ? Colors.indigo : Colors.transparent,
              border: Border.all(color: isSel ? Colors.indigo : Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              day,
              style: TextStyle(
                fontSize: 12,
                color: isSel ? Colors.white : Colors.black87,
                fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        );
      }),
    );
  }
}
