import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async'; // FOR LIVE CLOCK TIMER
import '../../viewmodels/comitteeviewmodel/committee_meeting_queue_view_model.dart';
import 'committee_evaluation_view.dart';
import 'group_detail_view.dart';
import 'project_allocation_view.dart';
import 'committee_supervisor_allocation_view.dart';

// ---------------------------------------------------------
// WHAT IS THIS FILE?
// This is the "View" (UI Screen) for regular Committee Members' Meeting Queue.
// It shows:
// - A list of meetings filtered by FYP-1 / FYP-2.
// - Filter chips by Meeting Title type.
// - **Live Clock Timer**: Updates every 10 seconds to show "Live Now", "Due now (10:30)", "In 15 min (10:30)", or "Done" matching React!
// - Group Details showing students and allocation status.
// - Direct supervisor allocation and project allocation controls.
// - Real-time student remarks saving and loading with dynamic fyp1-scores / fyp2-scores API.
// - **PPT File Downloader Helper**: Allows downloading presentation files uploaded by students from schedule details!
// ---------------------------------------------------------

class CommitteeMeetingQueueView extends StatefulWidget {
  final List<Map<String, dynamic>> userData;
  const CommitteeMeetingQueueView({super.key, required this.userData});

  @override
  State<CommitteeMeetingQueueView> createState() => _CommitteeMeetingQueueViewState();
}

class _CommitteeMeetingQueueViewState extends State<CommitteeMeetingQueueView> {
  // 1. Instantiate our Brain (ViewModel)
  final CommitteeMeetingQueueViewModel _viewModel = CommitteeMeetingQueueViewModel();
  
  // 2. Local State Variables managed via setState()
  String _activeFyp = "FYP-1"; // Holds whether we are viewing FYP-1 or FYP-2
  String? _activeType; // Holds filter matching the clicked Meeting Title type chip
  Map<String, dynamic>? _selectedMeeting; // Holds the currently tapped meeting card map
  
  // 3. Remarks state variables
  String? _openRemarkStudentId; // Keeps track of which student card's remark field is expanded
  final TextEditingController _remarkController = TextEditingController(); // Controller for typing text

  // 4. Live Clock Timer
  Timer? _timer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    // Fetch today's meetings when the screen loads
    _refreshMeetings();

    // Start periodic timer to update live clock and refresh meetings every 10 seconds matching React!
    _timer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted) {
        setState(() {
          _now = DateTime.now();
        });
        // We can also background refresh meetings without showing a loading spinner
        _viewModel.fetchMeetings(_activeFyp).then((_) {
          if (mounted) setState(() {});
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _remarkController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------
  // FUNCTION: _refreshMeetings
  // Downloads meetings from the server and redraws the view.
  // ---------------------------------------------------------
  void _refreshMeetings() async {
    await _viewModel.fetchMeetings(_activeFyp);
    if (mounted) setState(() {});
  }

  // ---------------------------------------------------------
  // FUNCTION: _getMeetingsByStatus
  // Local list filter that returns in-progress, waiting, or completed meetings.
  // ---------------------------------------------------------
  List<Map<String, dynamic>> _getMeetingsByStatus(String status) {
    return _viewModel.meetings.where((m) {
      final matchesStatus = (m['Status'] ?? "") == status;
      final matchesType = _activeType == null || (m['MeetingTitle'] ?? "") == _activeType;
      return matchesStatus && matchesType;
    }).toList();
  }

  // ---------------------------------------------------------
  // LIVE TIMER HELPER FUNCTIONS (MATCHING REACT EXACTLY)
  // ---------------------------------------------------------
  int? _calculateMinutesRemaining(String? meetingTime, DateTime now) {
    if (meetingTime == null || meetingTime.isEmpty) return null;
    try {
      final parts = meetingTime.split(':');
      if (parts.length < 2) return null;
      final hours = int.tryParse(parts[0]) ?? 0;
      final minutes = int.tryParse(parts[1]) ?? 0;

      final meetingDate = DateTime(now.year, now.month, now.day, hours, minutes);
      final diffMs = meetingDate.difference(now).inMilliseconds;
      return (diffMs / (1000 * 60)).floor();
    } catch (_) {
      return null;
    }
  }

  String _getTimeDisplay(Map<String, dynamic> meeting, DateTime now) {
    final status = meeting['Status']?.toString() ?? "";
    if (status == "Completed") return "Done";
    if (status == "In-Progress") return "Live Now";

    final meetingTime = meeting['MeetingTime']?.toString();
    final mins = _calculateMinutesRemaining(meetingTime, now);
    final clockTime = meetingTime != null && meetingTime.length >= 5 ? meetingTime.substring(0, 5) : "N/A";

    if (mins == null) return clockTime;

    if (mins <= 0 && mins > -15) return "Due now ($clockTime)";
    return "In $mins min ($clockTime)";
  }

  // ---------------------------------------------------------
  // FUNCTION: _downloadPptFile
  // Copies the uploaded PPT presentation path to clipboard so committee members can open it easily!
  // ---------------------------------------------------------
  void _downloadPptFile(String? filePath) {
    if (filePath == null || filePath.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No PPT file has been uploaded for this meeting yet! ❌")),
      );
      return;
    }
    
    // Construct full download URL pointing to server
    final String fullUrl = filePath.startsWith("http") 
        ? filePath 
        : "http://localhost/ProgressMonitoringProject$filePath";
    
    // Copy to clipboard
    Clipboard.setData(ClipboardData(text: fullUrl));
    
    // Notify user
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("PPT File URL copied to Clipboard! 📋\n$fullUrl"),
        backgroundColor: Colors.purple.shade700,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Generate distinct meeting types for top chips
    final types = _viewModel.meetings.map((m) => m['MeetingTitle']?.toString() ?? "").toSet().toList();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Meeting Queue", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 18),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: Column(
        children: [
          // --- FYP Semester Selector Row ---
          _buildFypTabs(),
          // --- Meeting Type filter chips ---
          _buildTypeFilters(types),
          
          // --- Main Content Switcher ---
          Expanded(
            child: _selectedMeeting == null ? _buildQueueList() : _buildDetailsView(),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------
  // THE QUEUE LIST VIEW
  // Displays scheduled meetings split by In-Progress, Waiting, and Completed status.
  // ---------------------------------------------------------
  Widget _buildQueueList() {
    if (_viewModel.isLoading) return const Center(child: CircularProgressIndicator());
    
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildStatusSection("In-Progress", Colors.blue),
        _buildStatusSection("Waiting", Colors.orange),
        _buildStatusSection("Completed", Colors.green),
        if (_viewModel.meetings.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Text(
                "No meetings found for $_activeFyp", 
                style: TextStyle(color: Colors.grey[400]),
              ),
            ),
          ),
      ],
    );
  }

  // ---------------------------------------------------------
  // THE MEETING DETAILS VIEW
  // Displays the detailed overview cards once a meeting card is tapped.
  // ---------------------------------------------------------
  Widget _buildDetailsView() {
    if (_viewModel.isDetailsLoading) return const Center(child: CircularProgressIndicator());
    
    return WillPopScope(
      onWillPop: () async {
        setState(() => _selectedMeeting = null);
        return false;
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Navigation Back Button
          TextButton.icon(
            onPressed: () => setState(() => _selectedMeeting = null),
            icon: const Icon(Icons.arrow_back, size: 16),
            label: const Text("Back to Queue"),
          ),
          const SizedBox(height: 12),
          _buildMeetingHeader(),
          const SizedBox(height: 20),
          _buildGroupStudents(),
          const SizedBox(height: 20),
          // Check evaluationParams.isNotEmpty to ensure evaluation panel is available for grading matching React!
          if (_viewModel.evaluationParams.isNotEmpty) _buildEvaluationPanel(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildFypTabs() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: ["FYP-1", "FYP-2"].map((t) => Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: GestureDetector(
              onTap: () { 
                setState(() { 
                  _activeFyp = t; 
                  _selectedMeeting = null; 
                }); 
                _refreshMeetings(); 
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _activeFyp == t ? Colors.blueAccent : Colors.grey[100],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    t, 
                    style: TextStyle(
                      color: _activeFyp == t ? Colors.white : Colors.black, 
                      fontWeight: FontWeight.bold, 
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildTypeFilters(List<String> types) {
    if (types.isEmpty) return const SizedBox();
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.only(bottom: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: types.map((t) => Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(t, style: const TextStyle(fontSize: 11)),
              selected: _activeType == t,
              selectedColor: Colors.blue[100],
              onSelected: (s) => setState(() => _activeType = s ? t : null),
            ),
          )).toList(),
        ),
      ),
    );
  }

  Widget _buildStatusSection(String status, Color color) {
    final list = _getMeetingsByStatus(status);
    if (list.isEmpty) return const SizedBox();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12, top: 8),
          child: Row(
            children: [
              Container(width: 4, height: 16, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 8),
              Text(status, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
        ),
        ...list.map((m) => _buildMeetingCard(m)).toList(),
      ],
    );
  }

  Widget _buildMeetingCard(Map<String, dynamic> m) {
    final status = m['Status']?.toString() ?? "";
    final isCompleted = status == "Completed";

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Group ${m['GroupIDs']}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isCompleted ? Colors.green.shade50 : status == "In-Progress" ? Colors.blue.shade50 : Colors.orange.shade50,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                status,
                style: TextStyle(
                  color: isCompleted ? Colors.green : status == "In-Progress" ? Colors.blue : Colors.orange,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 6),
            Text(m['MeetingTitle'] ?? "", style: const TextStyle(fontSize: 13, color: Colors.blueAccent, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(children: [
                  Icon(Icons.calendar_today, size: 12, color: Colors.grey[400]),
                  const SizedBox(width: 4),
                  Text(m['MeetingDate']?.toString().split('T')[0] ?? "", style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                ]),
                Row(children: [
                  Icon(Icons.access_time, size: 12, color: isCompleted ? Colors.green : Colors.blue),
                  const SizedBox(width: 4),
                  Text(
                    _getTimeDisplay(m, _now), 
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isCompleted ? Colors.green : Colors.blue),
                  ),
                ]),
              ],
            ),
          ],
        ),
        onTap: () {
          setState(() => _selectedMeeting = m);
          _viewModel.fetchMeetingDetails(m, _activeFyp).then((_) => setState(() {}));
        },
      ),
    );
  }

  // ---------------------------------------------------------
  // CARD: MEETING DETAILS
  // Renders the meeting venue, description, times and **PPT File Link copy button**.
  // ---------------------------------------------------------
  Widget _buildMeetingHeader() {
    final d = _viewModel.selectedMeetingDetails;
    if (d == null) return const SizedBox();

    // Check if the schedule details has an uploaded presentation file path matching React!
    final String? pptPath = _viewModel.scheduleDetails?['filePath'] ?? _selectedMeeting?['isUploaded'];
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline, size: 18, color: Colors.blue),
              const SizedBox(width: 8),
              const Text("Meeting Information", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ],
          ),
          const Divider(height: 24),
          _infoLabel("Description", d['meetingDescription'] ?? "N/A"),
          _infoLabel("Venue", d['venue'] ?? "N/A"),
          _infoLabel("Days", d['days'] ?? "N/A"),
          _infoLabel("Time", "${d['startTime']} - ${d['endTime']}"),
          
          // --- PRESENTATION PPT FILE DOWNLOAD SECTION ---
          if (pptPath != null && pptPath.isNotEmpty) ...[
            const Divider(height: 24),
            Row(
              children: [
                const Icon(Icons.description, size: 18, color: Colors.purple),
                const SizedBox(width: 8),
                const Text("Presentation File", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.purple.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.purple.shade100),
              ),
              child: Row(
                children: [
                  const Icon(Icons.insert_drive_file, color: Colors.purple),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      "Student PPT is uploaded!",
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.purple),
                    ),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      foregroundColor: Colors.white,
                      elevation: 0,
                    ),
                    onPressed: () {
                      _downloadPptFile(pptPath);
                    },
                    icon: const Icon(Icons.download, size: 14),
                    label: const Text("Get PPT Link", style: TextStyle(fontSize: 10)),
                  ),
                ],
              ),
            ),
          ],

        ],
      ),
    );
  }

  Widget _infoLabel(String label, String val) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 80, child: Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500))),
          Expanded(child: Text(val, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  Widget _buildGroupStudents() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Group Students", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 12),
        Row(
          children: [
            _statusBadge(_viewModel.isProjectAllocated ? "Project Allocated" : "Project Pending", _viewModel.isProjectAllocated),
            const SizedBox(width: 8),
            _statusBadge(_viewModel.isSupervisorAllocated ? "Supervisor Set" : "Supervisor Pending", _viewModel.isSupervisorAllocated),
          ],
        ),
        const SizedBox(height: 12),
        ..._viewModel.groupStudents.map((s) => _buildStudentCard(s)).toList(),
        const SizedBox(height: 16),
        if (!_viewModel.isProjectAllocated || !_viewModel.isSupervisorAllocated)
          Row(
            children: [
              if (!_viewModel.isProjectAllocated)
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      final int? gid = _selectedMeeting != null ? _selectedMeeting!['GroupIDs'] : null;
                      final int? mid = _selectedMeeting != null ? _selectedMeeting!['id'] : null;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (c) => ProjectAllocationView(
                            initialGroupId: gid,
                            initialMeetingId: mid,
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
                    child: const Text("Allocate Project", style: TextStyle(fontSize: 11)),
                  ),
                ),
              if (!_viewModel.isProjectAllocated && !_viewModel.isSupervisorAllocated) const SizedBox(width: 8),
              if (!_viewModel.isSupervisorAllocated)
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      if (_selectedMeeting != null && _selectedMeeting!['GroupIDs'] != null) {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (c) => CommitteeSupervisorAllocationView(
                              groupId: _selectedMeeting!['GroupIDs'],
                            ),
                          ),
                        );
                        // Refresh the details view so the allocation badges get updated
                        if (mounted) {
                          _viewModel.fetchMeetingDetails(_selectedMeeting!, _activeFyp).then((_) => setState(() {}));
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.purple, foregroundColor: Colors.white),
                    child: const Text("Allocate Supervisor", style: TextStyle(fontSize: 11)),
                  ),
                ),
            ],
          ),
      ],
    );
  }

  Widget _statusBadge(String text, bool ok) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: ok ? Colors.green[50] : Colors.red[50], borderRadius: BorderRadius.circular(6)),
      child: Text(text, style: TextStyle(color: ok ? Colors.green : Colors.red, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildStudentCard(Map<String, dynamic> s) {
    final sId = (s['studentID'] ?? s['StudentID'])?.toString();
    final bool isRemarksOpen = _openRemarkStudentId == sId;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.blue[50], 
                radius: 18, 
                child: Text((s['studentName'] ?? s['StudentName'])?[0] ?? "?", style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 14))
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s['studentName'] ?? s['StudentName'] ?? "Unknown Student", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    Text("ID: ${s['studentID'] ?? s['StudentID']} • CGPA: ${s['currentCGPA']}", style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (c) => GroupDetailView(groupId: _selectedMeeting!['GroupIDs'])));
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, elevation: 0),
                  child: const Text("Group Details", style: TextStyle(fontSize: 11, color: Colors.white)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(child: OutlinedButton(onPressed: () => _toggleRemarks(s), style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.blueAccent)), child: Text(isRemarksOpen ? "Close Remarks" : "Remarks", style: const TextStyle(fontSize: 11)))),
            ],
          ),
          if (isRemarksOpen) ...[
            const SizedBox(height: 12),
            TextField(
               controller: _remarkController,
               maxLines: 3,
               decoration: InputDecoration(
                 hintText: "Enter meeting remarks...",
                 filled: true,
                 fillColor: Colors.grey[50],
                 border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
               ),
               style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 8),
            SizedBox(
               width: double.infinity,
               child: ElevatedButton(onPressed: () => _saveRemark(s), style: ElevatedButton.styleFrom(backgroundColor: Colors.black, elevation: 0), child: const Text("Save Remark", style: TextStyle(color: Colors.white, fontSize: 11))),
            ),
          ]
        ],
      ),
    );
  }

  // ---------------------------------------------------------
  // FUNCTION: _toggleRemarks
  // Expanded card loader that queries current/latest remark dynamically with activeFyp!
  // ---------------------------------------------------------
  void _toggleRemarks(Map<String, dynamic> s) async {
    final studentId = (s['studentID'] ?? s['StudentID'])?.toString();
    if (_openRemarkStudentId == studentId) {
      setState(() => _openRemarkStudentId = null);
    } else {
      final userId = widget.userData[0]['id'].toString();
      final meetingId = _selectedMeeting!['id'] ?? _selectedMeeting!['meetingId'] ?? 0;
      final remark = await _viewModel.fetchStudentRemarks(s['EnrollmentID'], userId, s['sessionID'], meetingId, _activeFyp);
      setState(() {
        _openRemarkStudentId = studentId;
        _remarkController.text = remark;
      });
    }
  }

  // ---------------------------------------------------------
  // FUNCTION: _saveRemark
  // Saves the edited remarks with dynamic activeFyp!
  // ---------------------------------------------------------
  void _saveRemark(Map<String, dynamic> s) async {
    final userId = widget.userData[0]['id'].toString();
    bool ok = await _viewModel.saveRemarks(s['EnrollmentID'], _selectedMeeting!['id'], userId, s['sessionID'], _remarkController.text, _activeFyp);
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Remarks saved successfully ✅")));
      setState(() => _openRemarkStudentId = null);
    }
  }

  Widget _buildEvaluationPanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.blue.shade100)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.assessment_outlined, color: Colors.blue, size: 18),
              const SizedBox(width: 8),
              const Text("Evaluation Panel", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const Spacer(),
              _statusBadge("Active", true),
            ],
          ),
          const Divider(height: 24),
          ..._viewModel.evaluationParams.map((p) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(10)),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p['ParameterName'] ?? "", style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                      Text("Weightage: ${p['Percentage']}%", style: const TextStyle(fontSize: 10, color: Colors.grey)),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (c) => CommitteeEvaluationView(
                          meetingId: _selectedMeeting!['id'],
                          groupId: _selectedMeeting!['GroupIDs'],
                          parameterId: p['ParameterID'],
                          parameterName: p['ParameterName'],
                          fypType: _activeFyp,
                          userData: widget.userData,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, padding: const EdgeInsets.symmetric(horizontal: 16)),
                  child: const Text("Evaluate", style: TextStyle(fontSize: 10, color: Colors.white)),
                ),
              ],
            ),
          )).toList(),
        ],
      ),
    );
  }
}