import 'dart:async';
import 'package:flutter/material.dart';
import '../../viewmodels/comitteeheadviewmodel/committee_head_meeting_queue_view_model.dart';
import '../comitteeui/committee_evaluation_view.dart';
import 'committee_head_supervisor_allocation_view.dart';
import 'committee_head_project_allocation_view.dart';


class CommitteeHeadMeetingQueueView extends StatefulWidget {
  final List<Map<String, dynamic>>? userData;
  const CommitteeHeadMeetingQueueView({super.key, this.userData});

  @override
  State<CommitteeHeadMeetingQueueView> createState() => _CommitteeHeadMeetingQueueViewState();
}

class _CommitteeHeadMeetingQueueViewState extends State<CommitteeHeadMeetingQueueView> {
  final CommitteeHeadMeetingQueueViewModel _viewModel = CommitteeHeadMeetingQueueViewModel();

  String _activeFYP = "FYP-1";
  bool _isLoading = false;
  List<Map<String, dynamic>> _meetings = [];
  String? _activeMeetingType;

  // Selected meeting state
  bool _isDetailLoading = false;
  int? _selectedMeetingId;
  int? _selectedGroupId;
  Map<String, dynamic>? _meetingDetails;
  List<dynamic> _groupDetails = [];
  List<dynamic> _evalParameters = [];

  bool _isProjectAllocated = false;
  bool _isSupervisorAllocated = false;
  bool _isGraded = false;

  Map<String, String> _studentRemarks = {};
  String? _openRemarkStudent;
  bool _isSavingRemark = false;

  Timer? _timer;
  DateTime _currentTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadMeetings();

    // ==========================================
    // ⏰ AUTO-SYNC TIMER (Every 30 seconds)
    // ==========================================
    // This timer updates the time on the screen automatically.
    // It changes "In 5 min" to "In 4 min", "Due now", or "LIVE NOW" without the user refreshing.
    _timer = Timer.periodic(const Duration(seconds: 30), (timer) async {
      // 1. Stop if the screen is closed
      if (!mounted) return;
      
      // 2. Update the current time to trigger a rebuild
      setState(() {
        _currentTime = DateTime.now();
      });
      
      // 3. Ask the server to check for delayed meetings in the background
      await _viewModel.updateMeetingTimesDynamic();
      
      // 4. Fetch the latest list so if the server moved things around, we see it
      final list = await _viewModel.fetchMeetings(_activeFYP);
      if (mounted) {
        setState(() {
          _meetings = list;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  int? _calculateMinutesRemaining(String? meetingTime) {
    if (meetingTime == null || meetingTime.isEmpty) return null;
    try {
      final parts = meetingTime.split(":");
      final hours = int.parse(parts[0]);
      final minutes = int.parse(parts[1]);
      
      final now = _currentTime;
      final meetingDate = DateTime(now.year, now.month, now.day, hours, minutes, 0);
      
      final diffMs = meetingDate.millisecondsSinceEpoch - now.millisecondsSinceEpoch;
      return (diffMs / (1000 * 60)).floor();
    } catch (e) {
      return null;
    }
  }

  String _getTimeDisplay(Map<String, dynamic> meeting) {
    String status = meeting['Status'] ?? "";
    String meetingTime = meeting['MeetingTime'] ?? "";

    if (status == "Completed") return "Done";
    if (status == "In-Progress") return "LIVE NOW";
    
    final mins = _calculateMinutesRemaining(meetingTime);
    if (mins == null) return meetingTime;
    if (mins <= 0) return "Due now";
    return "In $mins min";
  }

  Future<void> _loadMeetings() async {
    setState(() {
      _isLoading = true;
      _resetSelection();
    });
    final list = await _viewModel.fetchMeetings(_activeFYP);
    if (mounted) {
      setState(() {
        _meetings = list;
        _isLoading = false;
      });
    }
  }

  void _resetSelection() {
    _selectedMeetingId = null;
    _selectedGroupId = null;
    _meetingDetails = null;
    _groupDetails = [];
    _evalParameters = [];
    _isGraded = false;
    _isProjectAllocated = false;
    _isSupervisorAllocated = false;
    _studentRemarks = {};
    _openRemarkStudent = null;
  }

  Future<void> _selectMeeting(Map<String, dynamic> meeting) async {
    int meetingId = meeting['id'] ?? meeting['meetingId'] ?? 0;
    int groupId = meeting['GroupIDs'] ?? meeting['groupId'] ?? 0;

    setState(() {
      _isDetailLoading = true;
      _selectedMeetingId = meetingId;
      _selectedGroupId = groupId;
      _meetingDetails = null;
      _groupDetails = [];
      _evalParameters = [];
      _isGraded = false;
    });

    final details = await _viewModel.fetchMeetingInfo(meetingId);
    final group = await _viewModel.fetchSpecificGroup(groupId);
    final isProjAlloc = await _viewModel.checkProjectAllocation(groupId);
    final isSupAlloc = await _viewModel.checkSupervisorAllocation(groupId);

    final params = await _viewModel.fetchEvaluationParameters(meetingId, _activeFYP);
    
    // Find matched param to check if it is graded (React logic)
    String mTitle = (meeting['MeetingTitle'] ?? "").toString().toLowerCase().trim();
    bool graded = false;
    List<Map<String, dynamic>> matchedParams = [];
    
    for (var p in params) {
      if ((p['ParameterName'] ?? "").toString().toLowerCase().trim() == mTitle) {
        if (p['IsGraded'] == true) {
          graded = true;
          matchedParams = params; // If one is graded, show all params
        }
      }
    }
    // Alternatively, if any is graded:
    if (!graded && params.any((p) => p['IsGraded'] == true)) {
      graded = true;
      matchedParams = params;
    }

    if (mounted) {
      setState(() {
        _meetingDetails = details;
        _groupDetails = group;
        _isProjectAllocated = isProjAlloc;
        _isSupervisorAllocated = isSupAlloc;
        _evalParameters = graded ? matchedParams : [];
        _isGraded = graded;
        _isDetailLoading = false;
      });
    }
  }

  Future<void> _loadStudentRemark(Map<String, dynamic> student) async {
    String studentId = student['studentID']?.toString() ?? "";
    if (_openRemarkStudent == studentId) {
      setState(() => _openRemarkStudent = null);
      return;
    }

    setState(() {
      _openRemarkStudent = studentId;
    });

    int enrollId = student['EnrollmentID'] ?? 0;
    int sessionId = student['sessionID'] ?? 2;
    String evaluatorId = widget.userData?[0]['id']?.toString() ?? "HEAD-001";

    final list = await _viewModel.fetchRemarks(enrollId, evaluatorId, sessionId);
    
    if (mounted) {
      String remarkText = "";
      if (list.isNotEmpty) {
        // Try to find the exact meeting remark, or just take the latest
        var selectedRemark = list.firstWhere(
          (r) => r['meetingID'] == _selectedMeetingId, 
          orElse: () => list.first
        );
        remarkText = selectedRemark['remarks'] ?? "";
      }

      setState(() {
        _studentRemarks[studentId] = remarkText;
      });
    }
  }

  Future<void> _saveStudentRemark(Map<String, dynamic> student) async {
    String studentId = student['studentID']?.toString() ?? "";
    String text = _studentRemarks[studentId] ?? "";

    if (text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please write remarks first")));
      return;
    }

    setState(() => _isSavingRemark = true);

    bool ok = await _viewModel.saveStudentRemark({
      "StudentEnrollID": student['EnrollmentID'] ?? 0,
      "MeetingID": _selectedMeetingId,
      "EvaluatorID": widget.userData?[0]['id']?.toString() ?? "HEAD-001",
      "SessionID": student['sessionID'] ?? 2,
      "Remarks": text,
    });

    setState(() {
      _isSavingRemark = false;
      if (ok) _openRemarkStudent = null;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ok ? "Remarks saved successfully" : "Failed to save remarks")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    Set<String> types = _meetings.map((m) => (m['MeetingTitle'] ?? "").toString()).toSet();
    List<String> meetingTypes = types.toList();

    List<Map<String, dynamic>> filteredMeetings = _activeMeetingType != null
        ? _meetings.where((m) => (m['MeetingTitle'] ?? "").toString() == _activeMeetingType).toList()
        : [];

    List<Map<String, dynamic>> inProgress = filteredMeetings.where((m) => m['Status'] == "In-Progress").toList();
    List<Map<String, dynamic>> waiting = filteredMeetings.where((m) => m['Status'] == "Scheduled" || m['Status'] == "Waiting").toList();
    List<Map<String, dynamic>> completed = filteredMeetings.where((m) => m['Status'] == "Completed").toList();

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text("Committee Meeting Queue", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(icon: const Icon(Icons.warning_amber_rounded, color: Colors.orange), onPressed: _showDelayHandlerDialog, tooltip: "Manage Delay"),
          IconButton(icon: const Icon(Icons.refresh, color: Colors.deepPurple), onPressed: _loadMeetings),
        ],
      ),
      body: Column(
        children: [
          // FYP Tabs
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: ['FYP-1', 'FYP-2'].map((fyp) {
                bool isSel = _activeFYP == fyp;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() => _activeFYP = fyp);
                      _loadMeetings();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isSel ? Colors.deepPurple : Colors.white,
                      foregroundColor: isSel ? Colors.white : Colors.black87,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      side: BorderSide(color: isSel ? Colors.deepPurple : Colors.grey.shade300),
                    ),
                    child: Text(fyp),
                  ),
                );
              }).toList(),
            ),
          ),

          // Meeting Types Filter
          if (!_isLoading)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: meetingTypes.map((type) {
                  bool isSel = _activeMeetingType == type;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _activeMeetingType = type;
                          _resetSelection();
                        });
                      },
                      style: OutlinedButton.styleFrom(
                        backgroundColor: isSel ? Colors.blue.shade50 : Colors.white,
                        side: BorderSide(color: isSel ? Colors.blue : Colors.grey.shade300),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text(type, style: TextStyle(color: isSel ? Colors.blue : Colors.black87)),
                    ),
                  );
                }).toList(),
              ),
            ),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _activeMeetingType == null
                    ? const Center(child: Text("Select a meeting type", style: TextStyle(color: Colors.grey)))
                    : ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          if (inProgress.isNotEmpty) ...[
                            const Text("In Progress", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                            const SizedBox(height: 8),
                            ...inProgress.map((m) => _buildMeetingCard(m)),
                            const SizedBox(height: 16),
                          ],
                          if (waiting.isNotEmpty) ...[
                            const Text("Waiting", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                            const SizedBox(height: 8),
                            ...waiting.map((m) => _buildMeetingCard(m)),
                            const SizedBox(height: 16),
                          ],
                          if (completed.isNotEmpty) ...[
                            const Text("Completed", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                            const SizedBox(height: 8),
                            ...completed.map((m) => _buildMeetingCard(m)),
                          ],
                        ],
                      ),
          ),
          
          if (_isDetailLoading) const LinearProgressIndicator(),
          if (_meetingDetails != null && !_isDetailLoading) _buildDetailPanel(),
        ],
      ),
    );
  }

  Widget _buildDetailPanel() {
    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.65),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            width: 40, height: 4,
            decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Meeting Actions", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => setState(() => _resetSelection()),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildMeetingDetailsBox(),
                const SizedBox(height: 16),
                if (_groupDetails.isNotEmpty) _buildGroupDetailsBox(),
                const SizedBox(height: 16),
                if (_isGraded) _buildEvaluationPanel(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMeetingCard(Map<String, dynamic> meeting) {
    bool isSelected = _selectedMeetingId == (meeting['id'] ?? meeting['meetingId']) && _selectedGroupId == (meeting['GroupIDs'] ?? meeting['groupId']);
    String status = meeting['Status'] ?? 'Scheduled';

    Color statusColor = Colors.grey;
    if (status == "Completed") statusColor = Colors.green;
    if (status == "In-Progress") statusColor = Colors.blue;
    if (status == "Waiting" || status == "Scheduled") statusColor = Colors.orange;

    return GestureDetector(
      onTap: () => _selectMeeting(meeting),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.deepPurple.shade50 : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? Colors.deepPurple : Colors.grey.shade200, width: isSelected ? 2 : 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Group ${meeting['GroupIDs'] ?? meeting['groupId'] ?? ''}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: statusColor)),
                  child: Text(status, style: TextStyle(fontSize: 10, color: statusColor, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(meeting['MeetingTitle'] ?? "Meeting", style: const TextStyle(fontSize: 13)),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.access_time, size: 12, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  "${meeting['MeetingDate']?.toString().split('T')[0] ?? ''} • ${_getTimeDisplay(meeting)}",
                  style: TextStyle(
                    fontSize: 11,
                    color: _getTimeDisplay(meeting) == "Due now" || _getTimeDisplay(meeting) == "LIVE NOW" 
                        ? Colors.red 
                        : Colors.grey.shade600,
                    fontWeight: _getTimeDisplay(meeting) == "Due now" || _getTimeDisplay(meeting) == "LIVE NOW" 
                        ? FontWeight.bold 
                        : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMeetingDetailsBox() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Meeting Details", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue, size: 18),
                    onPressed: () => _showEditMeetingDialog(),
                    tooltip: "Edit Meeting",
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red, size: 18),
                    onPressed: () => _confirmDeleteMeeting(),
                    tooltip: "Delete Meeting",
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _detailText("Description:", _meetingDetails?['meetingDescription'] ?? "N/A")),
              Expanded(child: _detailText("Venue:", _meetingDetails?['venue'] ?? "N/A")),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _detailText("Days:", _meetingDetails?['days'] ?? "N/A")),
              Expanded(child: _detailText("Time:", "${_meetingDetails?['startTime'] ?? ''} - ${_meetingDetails?['endTime'] ?? ''}")),
            ],
          ),
        ],
      ),
    );
  }

  void _showEditMeetingDialog() {
    if (_selectedMeetingId == null || _meetingDetails == null) return;
    
    String title = _meetingDetails!['meetingDescription'] ?? "Meeting";
    String venue = _meetingDetails!['venue'] ?? "";
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Edit Meeting"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(labelText: "Description"),
                controller: TextEditingController(text: title),
                onChanged: (v) => title = v,
              ),
              TextField(
                decoration: const InputDecoration(labelText: "Venue"),
                controller: TextEditingController(text: venue),
                onChanged: (v) => venue = v,
              ),
              const SizedBox(height: 8),
              const Text("Note: Basic info edit. To change dates/times fully, use the web portal.", style: TextStyle(fontSize: 10, color: Colors.grey)),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
              onPressed: () async {
                Navigator.pop(context);
                setState(() => _isDetailLoading = true);
                
                Map<String, dynamic> payload = Map<String, dynamic>.from(_meetingDetails!);
                payload['meetingDescription'] = title;
                payload['title'] = title;
                payload['venue'] = venue;
                payload['sessionID'] = payload['sessionID'] ?? 2;
                payload['selectedDays'] = (payload['days']?.toString().split(',')) ?? ['Mon'];

                bool ok = await _viewModel.updateMeeting(_selectedMeetingId!, _activeFYP, payload);
                if (ok) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Meeting updated")));
                  _loadMeetings();
                } else {
                  setState(() => _isDetailLoading = false);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to update meeting")));
                }
              },
              child: const Text("Save"),
            )
          ],
        );
      }
    );
  }

  void _confirmDeleteMeeting() {
    if (_selectedMeetingId == null) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Meeting"),
        content: const Text("Are you sure you want to delete this meeting? This will also remove the group schedules associated with it."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(context);
              setState(() => _isDetailLoading = true);
              bool ok = await _viewModel.deleteMeeting(_selectedMeetingId!);
              if (ok) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Meeting deleted")));
                _loadMeetings();
              } else {
                setState(() => _isDetailLoading = false);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to delete meeting")));
              }
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  Widget _detailText(String label, String value) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(fontSize: 13, color: Colors.black87),
        children: [
          TextSpan(text: "$label ", style: const TextStyle(fontWeight: FontWeight.bold)),
          TextSpan(text: value),
        ],
      ),
    );
  }

  Widget _buildGroupDetailsBox() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Group Students", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              OutlinedButton.icon(
                onPressed: _showRescheduleDialog,
                icon: const Icon(Icons.update, size: 14),
                label: const Text("Reschedule", style: TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0)),
              )
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _badge(_isProjectAllocated ? "Project Allocated" : "Project Not Allocated", _isProjectAllocated),
              const SizedBox(width: 8),
              _badge(_isSupervisorAllocated ? "Supervisor Allocated" : "Supervisor Not Allocated", _isSupervisorAllocated),
            ],
          ),
          const SizedBox(height: 16),
          if (_activeFYP == "FYP-2") ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Navigate to Assign Final Task
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Navigate to Assign Final Task")));
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple, foregroundColor: Colors.white),
                child: const Text("Assign Final Task"),
              ),
            ),
            const SizedBox(height: 16),
          ],
          
          Column(
            children: _groupDetails.map((student) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _buildStudentCard(student),
              );
            }).toList(),
          ),

          const SizedBox(height: 16),
          Row(
            children: [
              if (!_isProjectAllocated)
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      if (_selectedGroupId != null) {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (c) => CommitteeHeadProjectAllocationView(
                              initialGroupId: _selectedGroupId,
                            ),
                          ),
                        );
                        // Refresh the details card
                        if (mounted && _selectedMeetingId != null) {
                          final meeting = _meetings.firstWhere(
                            (m) => (m['id'] ?? m['meetingId']) == _selectedMeetingId,
                            orElse: () => <String, dynamic>{},
                          );
                          if (meeting.isNotEmpty) {
                            _selectMeeting(meeting);
                          }
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                    child: const Text("Allocate Project"),
                  ),
                ),
              if (!_isProjectAllocated && !_isSupervisorAllocated) const SizedBox(width: 8),
              if (!_isSupervisorAllocated)
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      if (_selectedGroupId != null) {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (c) => CommitteeHeadSupervisorAllocationView(groupId: _selectedGroupId!),
                          ),
                        );
                        // Refresh the meeting selection details to update allocation badges
                        if (mounted && _selectedMeetingId != null) {
                          // Find selected meeting map from meetings list
                          final meeting = _meetings.firstWhere(
                            (m) => (m['id'] ?? m['meetingId']) == _selectedMeetingId,
                            orElse: () => <String, dynamic>{},
                          );
                          if (meeting.isNotEmpty) {
                            _selectMeeting(meeting);
                          }
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                    child: const Text("Allocate Supervisor"),
                  ),
                ),
            ],
          )
        ],
      ),
    );
  }

  void _showDelayHandlerDialog() {
    // 1. Ensure we actually have meetings to handle delay for
    if (_meetings.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No meetings to delay.")));
      return;
    }

    // 2. Define our starting variables for the form
    String selectedAction = "merge"; // Can be 'merge' or 'new'
    DateTime newDate = DateTime.now().add(const Duration(days: 1)); // Tomorrow by default
    TimeOfDay newStartTime = const TimeOfDay(hour: 9, minute: 0);
    TimeOfDay newEndTime = const TimeOfDay(hour: 17, minute: 0);
    String venue = "Room 101";

    // 3. Show the interactive popup
    showDialog(
      context: context,
      builder: (context) {
        // StatefulBuilder allows us to use setState INSIDE the dialog so checkboxes and textfields update
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text("Manage Delay"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text("Select how to handle remaining groups:", style: TextStyle(fontSize: 12)),
                    
                    // Option A: Merge into next meeting
                    ListTile(
                      title: const Text("Merge into next meeting", style: TextStyle(fontSize: 13)),
                      leading: Radio(
                        value: "merge",
                        groupValue: selectedAction,
                        onChanged: (val) => setDialogState(() => selectedAction = val.toString()),
                      ),
                    ),
                    
                    // Option B: Create new meeting
                    ListTile(
                      title: const Text("Create new meeting", style: TextStyle(fontSize: 13)),
                      leading: Radio(
                        value: "new",
                        groupValue: selectedAction,
                        onChanged: (val) => setDialogState(() => selectedAction = val.toString()),
                      ),
                    ),

                    // 4. Show extra fields ONLY IF "new meeting" is selected
                    if (selectedAction == "new") ...[
                      const Divider(),
                      TextField(
                        decoration: const InputDecoration(labelText: "Venue", labelStyle: TextStyle(fontSize: 12)),
                        onChanged: (v) => venue = v,
                        controller: TextEditingController(text: venue),
                        style: const TextStyle(fontSize: 12),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () async {
                                final picked = await showDatePicker(context: context, initialDate: newDate, firstDate: DateTime.now(), lastDate: DateTime(2030));
                                if (picked != null) setDialogState(() => newDate = picked);
                              },
                              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 4)),
                              child: Text("Date: ${newDate.toString().split(' ')[0]}", style: const TextStyle(fontSize: 10)),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () async {
                                final picked = await showTimePicker(context: context, initialTime: newStartTime);
                                if (picked != null) setDialogState(() => newStartTime = picked);
                              },
                              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 4)),
                              child: Text("Start: ${newStartTime.format(context)}", style: const TextStyle(fontSize: 10)),
                            ),
                          ),
                        ],
                      ),
                    ]
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(context); // Close the dialog
                    setState(() => _isLoading = true); // Show loading spinner
                    
                    // 5. Ask ViewModel to tell the server about our delay choice
                    bool ok = await _viewModel.handleDelay({
                      "MeetingId": _meetings[0]['id'] ?? _meetings[0]['meetingId'],
                      "Action": selectedAction,
                      "NewDate": newDate.toIso8601String(),
                      "NewStartTime": "${newStartTime.hour.toString().padLeft(2, '0')}:${newStartTime.minute.toString().padLeft(2, '0')}:00",
                      "NewEndTime": "${newEndTime.hour.toString().padLeft(2, '0')}:${newEndTime.minute.toString().padLeft(2, '0')}:00",
                      "Venue": venue,
                      "SessionID": 2 // Default SessionID for beginner style
                    });
                    
                    if (ok) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Delay handled successfully")));
                      _loadMeetings(); // Refresh everything
                    } else {
                      setState(() => _isLoading = false);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to handle delay")));
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                  child: const Text("Apply"),
                )
              ],
            );
          }
        );
      }
    );
  }

  void _showRescheduleDialog() {
    if (_selectedMeetingId == null || _selectedGroupId == null) return;
    
    DateTime newDate = DateTime.now();
    TimeOfDay newTime = TimeOfDay.now();
    String studentId = "All";

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text("Reschedule Group"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      value: studentId,
                      items: [
                        const DropdownMenuItem(value: "All", child: Text("All Students (Whole Group)", style: TextStyle(fontSize: 12))),
                        ..._groupDetails.map((s) => DropdownMenuItem(value: s['studentID'].toString(), child: Text(s['studentName'], style: const TextStyle(fontSize: 12)))).toList(),
                      ],
                      onChanged: (v) => setDialogState(() => studentId = v!),
                      decoration: const InputDecoration(labelText: "Select Student", labelStyle: TextStyle(fontSize: 12)),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              final picked = await showDatePicker(context: context, initialDate: newDate, firstDate: DateTime.now(), lastDate: DateTime(2030));
                              if (picked != null) setDialogState(() => newDate = picked);
                            },
                            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 4)),
                            child: Text("Date: ${newDate.toString().split(' ')[0]}", style: const TextStyle(fontSize: 10)),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              final picked = await showTimePicker(context: context, initialTime: newTime);
                              if (picked != null) setDialogState(() => newTime = picked);
                            },
                            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 4)),
                            child: Text("Time: ${newTime.format(context)}", style: const TextStyle(fontSize: 10)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    setState(() => _isDetailLoading = true);
                    bool ok = await _viewModel.rescheduleMeeting({
                      "MeetingId": _selectedMeetingId,
                      "GroupId": _selectedGroupId,
                      "StudentId": studentId,
                      "NewDate": newDate.toIso8601String(),
                      "NewTime": "${newTime.hour.toString().padLeft(2, '0')}:${newTime.minute.toString().padLeft(2, '0')}:00",
                    });
                    if (ok) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Rescheduled successfully")));
                      _loadMeetings();
                    } else {
                      setState(() => _isDetailLoading = false);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to reschedule")));
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                  child: const Text("Reschedule"),
                )
              ],
            );
          }
        );
      }
    );
  }

  Widget _badge(String text, bool isSuccess) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isSuccess ? Colors.black : Colors.red,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildStudentCard(Map<String, dynamic> student) {
    String studentId = student['studentID']?.toString() ?? "";
    bool isRemarkOpen = _openRemarkStudent == studentId;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300)),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(student['studentName'] ?? "Unknown", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 4),
            Text("ID: ${student['studentID'] ?? ''}", style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            const SizedBox(height: 2),
            Text("CGPA: ${student['currentCGPA'] ?? ''}", style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("View Progress Clicked")));
                    },
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 0), textStyle: const TextStyle(fontSize: 11)),
                    child: const Text("View Progress"),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _loadStudentRemark(student),
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 0), textStyle: const TextStyle(fontSize: 11)),
                    child: Text(isRemarkOpen ? "Hide Remarks" : "Remarks"),
                  ),
                ),
              ],
            ),
            if (isRemarkOpen) ...[
              const SizedBox(height: 8),
              TextField(
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: "Write remarks...",
                  hintStyle: const TextStyle(fontSize: 12),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.all(8),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                ),
                style: const TextStyle(fontSize: 12),
                controller: TextEditingController.fromValue(TextEditingValue(
                  text: _studentRemarks[studentId] ?? "",
                  selection: TextSelection.collapsed(offset: (_studentRemarks[studentId] ?? "").length),
                )),
                onChanged: (v) => _studentRemarks[studentId] = v,
              ),
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerRight,
                child: SizedBox(
                  height: 24,
                  child: ElevatedButton(
                    onPressed: _isSavingRemark ? null : () => _saveStudentRemark(student),
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12)),
                    child: _isSavingRemark ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2)) : const Text("Save Remarks", style: TextStyle(fontSize: 10)),
                  ),
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildEvaluationPanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Evaluation Panel", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(16)),
                child: const Text("Graded", style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ..._evalParameters.map((param) {
            bool isCompleted = param['IsGraded'] == true;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade200)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(param['ParameterName'] ?? "Unknown", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      Text("Weight: ${param['Percentage']}%", style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                    ],
                  ),
                  ElevatedButton(
                    onPressed: () {
                      if (widget.userData == null || widget.userData!.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("User data missing")));
                        return;
                      }
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CommitteeEvaluationView(
                            userData: widget.userData!,
                            meetingId: _selectedMeetingId!,
                            groupId: _selectedGroupId!,
                            parameterId: param['ParameterID'] ?? param['id'] ?? 0,
                            parameterName: param['ParameterName'] ?? param['name'] ?? 'Unknown Parameter',
                            fypType: _activeFYP,
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isCompleted ? Colors.white : Colors.deepPurple,
                      foregroundColor: isCompleted ? Colors.deepPurple : Colors.white,
                      side: isCompleted ? const BorderSide(color: Colors.deepPurple) : BorderSide.none,
                    ),
                    child: Text(isCompleted ? "View Marks" : "Evaluate"),
                  )
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
