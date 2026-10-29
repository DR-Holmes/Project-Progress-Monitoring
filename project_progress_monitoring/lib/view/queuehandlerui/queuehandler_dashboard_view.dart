import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../../viewmodels/queuehandlerviewmodel/queuehandler_dashboard_viewmodel.dart';
import 'queue_handler_profile_view.dart';

class QueueHandlerDashboardView extends StatefulWidget {
  final List<Map<String, dynamic>> userData;
  const QueueHandlerDashboardView({super.key, required this.userData});

  @override
  State<QueueHandlerDashboardView> createState() => _QueueHandlerDashboardViewState();
}

class _QueueHandlerDashboardViewState extends State<QueueHandlerDashboardView> {
  // We use this ViewModel to talk to the backend without cluttering the UI code.
  final QueueHandlerDashboardViewModel _viewModel = QueueHandlerDashboardViewModel();

  // Basic variables for state management using setState()
  bool _isLoading = false; // Shows a loading spinner when true
  String _selectedFypType = "FYP-1"; // The current project type selected
  List<Map<String, dynamic>> _todayMeetings = []; // List of meetings happening today
  Map<String, dynamic>? _selectedMeeting; // The meeting the user has currently selected
  List<Map<String, dynamic>> _queueList = []; // The complete list of groups in the queue
  List<Map<String, dynamic>> _filteredQueue = []; // The list shown after searching
  final TextEditingController _searchController = TextEditingController(); // Controls the search box text
  Map<int, List<Map<String, String>>> _memberCache = {}; // Stores students so we can search by their name or ID

  // Timers to automatically refresh data without freezing the app
  Timer? _autoUpdateTimer; // Updates meeting times from the server automatically
  Timer? _clockTimer; // Updates the "minutes remaining" countdown on the screen
  DateTime _now = DateTime.now(); // Keeps track of the current time

  // Variables for Delay Management (if a meeting is running very late)
  bool _showDelayOptions = false; // Toggles the reschedule form
  DateTime _rescheduleDate = DateTime.now(); // The new date for a delayed group
  TimeOfDay _rescheduleStartTime = const TimeOfDay(hour: 10, minute: 0); // New start time
  TimeOfDay _rescheduleEndTime = const TimeOfDay(hour: 14, minute: 0); // New end time
  final TextEditingController _venueController = TextEditingController(); // The new venue

  @override
  void initState() {
    super.initState();
    // Load the meetings as soon as the screen opens
    _loadMeetings();
    
    // Set a timer to automatically ask the server for new times every 10 seconds.
    // This keeps the live queue "self-healing".
    _autoUpdateTimer = Timer.periodic(const Duration(seconds: 10), (timer) async {
      bool ok = await _viewModel.updateMeetingTimesDynamic();
      if (ok && _selectedMeeting != null) {
        // Refresh the queue list quietly (without showing a loading spinner)
        _loadQueue(_selectedMeeting!['id'], quiet: true);
      } else if (ok) {
        _loadMeetings(quiet: true);
      }
    });

    // Update our internal clock every 10 seconds so the "In X min" text changes live.
    _clockTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    // Always stop timers and controllers when leaving the screen to save memory.
    _autoUpdateTimer?.cancel();
    _clockTimer?.cancel();
    _searchController.dispose();
    _venueController.dispose();
    super.dispose();
  }

  /// -------------------------------------------------------------------------
  /// WHAT IT DOES: Fetches the big list of meetings happening today.
  /// HOW IT WORKS: It sets `_isLoading` to true, asks the ViewModel for data,
  /// and then groups them nicely to show in the dropdown.
  /// -------------------------------------------------------------------------
  Future<void> _loadMeetings({bool quiet = false}) async {
    if (!quiet) setState(() => _isLoading = true);
    final meetings = await _viewModel.fetchTodayMeetings(_selectedFypType);

    if (mounted) {
      setState(() {
        _todayMeetings = meetings;
        if (meetings.isNotEmpty) {
          // Remove duplicate meetings by their ID so the dropdown is clean
          final uniqueMeetings = <int, Map<String, dynamic>>{};
          for (var m in meetings) {
            uniqueMeetings[m['id']] = {
              'id': m['id'],
              'title': m['MeetingTitle'] ?? m['title']
            };
          }
          _todayMeetings = uniqueMeetings.values.toList();
          _selectedMeeting = _todayMeetings.first; // Pick the first meeting automatically
          _loadQueue(_selectedMeeting!['id']); // Load its groups
        } else {
          // If there are no meetings, empty the lists
          _queueList = [];
          _filteredQueue = [];
          _isLoading = false;
        }
      });
    }
  }

  /// -------------------------------------------------------------------------
  /// WHAT IT DOES: Loads the queue of student groups for the selected meeting.
  /// HOW IT WORKS: It fetches the queue, then fetches the students in each group,
  /// caching their names so we can search them quickly later.
  /// -------------------------------------------------------------------------
  Future<void> _loadQueue(int meetingId, {bool quiet = false}) async {
    if (!quiet) setState(() => _isLoading = true);
    
    try {
      // Step 1: Fetch the queue for this meeting
      final queue = await _viewModel.fetchMeetingQueue(meetingId, _selectedFypType);

      // Step 2: Fetch and cache member details for all groups to enable fast search
      Map<int, List<Map<String, String>>> cache = {};
      for (var group in queue) {
        final groupId = group['GroupIDs'] ?? group['groupID'];
        if (groupId != null) {
          // Set a default groupName since the backend might not provide one
          group['groupName'] = group['groupName'] ?? "Group $groupId";

          // Fetch individual students in this group
          final students = await _viewModel.fetchGroupDetails(groupId);
          cache[groupId] = students.map((s) => {
            'name': (s['studentName'] ?? "").toString(),
            'id': (s['studentId'] ?? s['studentID'] ?? "").toString(), // Handle different casings
          }).toList();
        }
      }

      if (mounted) {
        setState(() {
          _queueList = queue;
          _memberCache = cache;
          _filterQueue(); // Apply search filters if any
        });
      }
    } catch (e) {
      debugPrint("Error loading queue: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error loading queue: $e")));
      }
    } finally {
      // Always stop loading, even if there was an error
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// -------------------------------------------------------------------------
  /// WHAT IT DOES: Filters the list of groups based on what the user types.
  /// HOW IT WORKS: If the search box is empty, it shows all groups. If there's text,
  /// it checks if the group name or any student name/ID contains that text.
  /// -------------------------------------------------------------------------
  void _filterQueue() {
    String query = _searchController.text.toLowerCase(); // Convert to lowercase so search isn't case-sensitive
    setState(() {
      if (query.isEmpty) {
        _filteredQueue = List.from(_queueList); // Copy all groups back
      } else {
        _filteredQueue = _queueList.where((q) {
          final groupName = (q['groupName'] ?? "Group ${q['GroupIDs'] ?? q['groupID']}").toString().toLowerCase();
          final groupId = q['GroupIDs'] ?? q['groupID'];
          
          // Look at the students we cached earlier to see if any match
          final members = _memberCache[groupId] ?? [];
          bool memberMatch = members.any((m) => 
            m['name']!.toLowerCase().contains(query) || 
            m['id']!.toLowerCase().contains(query)
          );
          
          // Return true if the group name matches OR a student matches
          return groupName.contains(query) || memberMatch;
        }).toList();
      }
    });
  }

  /// -------------------------------------------------------------------------
  /// WHAT IT DOES: Puts groups with female members at the top of the queue.
  /// -------------------------------------------------------------------------
  Future<void> _sortQueueByGender() async {
    if (_selectedMeeting == null) return;
    setState(() => _isLoading = true);
    final updatedQueue = await _viewModel.prioritizeFemaleMembers(_selectedMeeting!['id']);
    
    // Save this new order globally so it doesn't revert
    final orderedIds = updatedQueue.map((m) => m['scheduleId'] as int).toList();
    await _viewModel.updateQueueOrderGlobally(orderedIds);

    if (mounted) {
      setState(() {
        _queueList = updatedQueue;
        _filterQueue(); // Make sure the search filter still applies
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Sorted: Female groups prioritized.")));
    }
  }

  /// -------------------------------------------------------------------------
  /// WHAT IT DOES: Groups the queue so students with the same supervisor are together.
  /// -------------------------------------------------------------------------
  Future<void> _sortQueueBySupervisor() async {
    if (_selectedMeeting == null) return;
    setState(() => _isLoading = true);
    final updatedQueue = await _viewModel.prioritizeSupervisorMembers(_selectedMeeting!['id']);
    
    // Save this new order globally
    final orderedIds = updatedQueue.map((m) => m['scheduleId'] as int).toList();
    await _viewModel.updateQueueOrderGlobally(orderedIds);

    if (mounted) {
      setState(() {
        _queueList = updatedQueue;
        _filterQueue(); // Make sure the search filter still applies
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Sorted: Organized by Supervisor.")));
    }
  }

  /// -------------------------------------------------------------------------
  /// WHAT IT DOES: Lets the user drag and drop groups in the "Waiting List".
  /// -------------------------------------------------------------------------
  void _onReorder(int oldIndex, int newIndex) async {
    // If they are searching, we don't let them drag-and-drop to avoid mixing things up
    if (_searchController.text.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Reordering is disabled during search.")));
      return;
    }

    setState(() {
      if (newIndex > oldIndex) newIndex -= 1; // Basic math to move items correctly
      final item = _queueList.removeAt(oldIndex);
      _queueList.insert(newIndex, item); // Put it in its new spot
      _filterQueue();
    });
    
    // Send the new order to the backend
    bool success = await _viewModel.updateQueueOrder(_queueList);
    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to save new order.")));
    }
  }

  /// -------------------------------------------------------------------------
  /// WHAT IT DOES: Figures out how many minutes are left until a meeting starts.
  /// -------------------------------------------------------------------------
  int? _calculateMinutesRemaining(String? meetingTime) {
    if (meetingTime == null || meetingTime.isEmpty) return null;
    try {
      final parts = meetingTime.split(':'); // Break "14:30:00" into hours and minutes
      if (parts.length >= 2) {
        final hours = int.parse(parts[0]);
        final minutes = int.parse(parts[1]);
        // Compare the meeting time with the current time (_now)
        final meetingDate = DateTime(_now.year, _now.month, _now.day, hours, minutes);
        final diff = meetingDate.difference(_now).inMinutes;
        return diff;
      }
    } catch (e) {
      debugPrint("Error parsing time: $e");
    }
    return null;
  }



  /// -------------------------------------------------------------------------
  /// WHAT IT DOES: Opens a "Slide-Up" box (Bottom Sheet) showing group details.
  /// WHY IT EXISTS: To let the user mark attendance and change group status.
  /// HOW TO USE IT: Simply tap on any group card in the list!
  /// -------------------------------------------------------------------------
  void _openGroupDetails(Map<String, dynamic> group) async {
    // 1. Show a loading spinner so the user knows we are working
    setState(() => _isLoading = true);
    
    // 2. Get the Group ID and fetch the list of students in this group
    final groupId = group['GroupIDs'] ?? group['groupID'];
    final students = await _viewModel.fetchGroupDetails(groupId);
    
    // 3. Check if the WHOLE group is marked as attended
    bool groupAttended = await _viewModel.fetchGroupAttendance(groupId, _selectedMeeting!['id']);
    
    // 4. Check attendance for EACH student individually
    // This makes sure the checkboxes show the correct "checked" or "unchecked" state.
    for (var student in students) {
      final studentId = (student['studentId'] ?? student['studentID'] ?? "").toString();
      // Ask the server: "Is this specific student here?"
      student['isAttended'] = await _viewModel.fetchStudentAttendance(group['scheduleId'], studentId);
    }

    // 5. Hide the loading spinner
    setState(() => _isLoading = false);

    if (!mounted) return;

    // 6. THIS IS THE SLIDE-UP BOX: showModalBottomSheet makes a window pop up from the bottom.
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // This allows the box to grow if there are many students
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)) // Nice rounded corners at the top
      ),
      builder: (context) {
        // StatefulBuilder lets us update the checkboxes INSIDE the slide-up box
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                top: 20, left: 20, right: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          group['groupName'] ?? "Group Details",
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: _getStatusColor(group['Status']),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          group['Status'] ?? 'Waiting',
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  
                  const SizedBox(height: 10),
                  const Divider(),
                  const Text("Student Attendance", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  if (students.isEmpty)
                    const Padding(padding: EdgeInsets.all(20), child: Text("No students found.")),
                  ...students.map((student) {
                    final studentId = (student['studentId'] ?? student['studentID'] ?? "").toString();
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(student['studentName'] ?? 'Unknown Student'),
                      subtitle: Text(studentId),
                      /* 
                      // -------------------------------------------------------------------------
                      // ATTENDANCE CHECKBOX (COMMENTED OUT FOR NOW)
                      // Simply remove the /* and */ to enable it again!
                      // -------------------------------------------------------------------------
                      trailing: Checkbox(
                        value: student['isAttended'] ?? false,
                        onChanged: (bool? val) async {
                          if (val != null) {
                            setModalState(() => student['isAttended'] = val);
                            bool ok = await _viewModel.updateStudentAttendance(group['scheduleId'], studentId, val);
                            if (!ok) {
                              setModalState(() => student['isAttended'] = !val);
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to update attendance.")));
                            }
                          }
                        },
                      ),
                      */
                    );
                  }),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: () async {
                            final groupId = group['GroupIDs'] ?? group['groupID'];
                            await _viewModel.updateGroupStatus(groupId, _selectedMeeting!['id'], 'In-Progress');
                            Navigator.pop(context);
                            _loadQueue(_selectedMeeting!['id']);
                          },
                          child: const Text("Mark In-Progress", style: TextStyle(color: Colors.white)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: () async {
                            final groupId = group['GroupIDs'] ?? group['groupID'];
                            await _viewModel.updateGroupStatus(groupId, _selectedMeeting!['id'], 'Completed');
                            Navigator.pop(context);
                            _loadQueue(_selectedMeeting!['id']);
                          },
                          child: const Text("Mark Completed", style: TextStyle(color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'In-Progress': return Colors.blue;
      case 'Completed': return Colors.green;
      default: return Colors.orange;
    }
  }

  Widget _buildDelayManagementCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 24),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Delay Management", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.deepOrange)),
                  Text("Manage remaining groups for this meeting.", style: TextStyle(fontSize: 12, color: Colors.orange.shade800)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => setState(() => _showDelayOptions = !_showDelayOptions),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.orange, width: 1.5), 
                    foregroundColor: Colors.orange,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: Icon(_showDelayOptions ? Icons.expand_less : Icons.tune),
                  label: Text(_showDelayOptions ? "Hide Options" : "Manage Delay"),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _handleMergeMeeting,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange, 
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.merge_type),
                  label: const Text("Merge into Next"),
                ),
              ),
            ],
          ),
          if (_showDelayOptions) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextButton.icon(
                          onPressed: () async {
                            final date = await showDatePicker(context: context, initialDate: _rescheduleDate, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 60)));
                            if (date != null) setState(() => _rescheduleDate = date);
                          },
                          icon: const Icon(Icons.calendar_today, size: 16),
                          label: Text(_rescheduleDate.toString().substring(0, 10)),
                        ),
                      ),
                      Expanded(
                        child: TextButton.icon(
                          onPressed: () async {
                            final time = await showTimePicker(context: context, initialTime: _rescheduleStartTime);
                            if (time != null) setState(() => _rescheduleStartTime = time);
                          },
                          icon: const Icon(Icons.access_time, size: 16),
                          label: Text("Start: ${_rescheduleStartTime.format(context)}"),
                        ),
                      ),
                      Expanded(
                        child: TextButton.icon(
                          onPressed: () async {
                            final time = await showTimePicker(context: context, initialTime: _rescheduleEndTime);
                            if (time != null) setState(() => _rescheduleEndTime = time);
                          },
                          icon: const Icon(Icons.timer_outlined, size: 16),
                          label: Text("End: ${_rescheduleEndTime.format(context)}"),
                        ),
                      ),
                    ],
                  ),
                  TextField(
                    controller: _venueController,
                    decoration: const InputDecoration(labelText: "Venue", border: OutlineInputBorder(), isDense: true),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _handleCreateNewMeeting,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                      child: const Text("Confirm Reschedule"),
                    ),
                  )
                ],
              ),
            )
          ]
        ],
      ),
    );
  }

  /// -------------------------------------------------------------------------
  /// WHAT IT DOES: Pushes the leftover waiting groups to the very next meeting.
  /// -------------------------------------------------------------------------
  Future<void> _handleMergeMeeting() async {
    if (_selectedMeeting == null) return;
    setState(() => _isLoading = true);
    
    final result = await _viewModel.handleDelay({
      "meetingId": _selectedMeeting!['id'], // Changed to camelCase to match React
      "action": "merge" // Changed to camelCase to match React
    });
    
    if (result['success']) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Merged remaining groups into next meeting.")));
      _showDelayOptions = false; // Hide the options box
      _loadMeetings(); // Reload the whole page to see the new queue
    } else {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed: ${result['message']}")));
    }
  }

  /// -------------------------------------------------------------------------
  /// WHAT IT DOES: Creates a brand new meeting on a different day/time for leftover groups.
  /// -------------------------------------------------------------------------
  Future<void> _handleCreateNewMeeting() async {
    if (_selectedMeeting == null) return;
    setState(() => _isLoading = true);
    
    // Format the time picking into strings like "10:00:00"
    String sHour = _rescheduleStartTime.hour.toString().padLeft(2, '0');
    String sMin = _rescheduleStartTime.minute.toString().padLeft(2, '0');
    String eHour = _rescheduleEndTime.hour.toString().padLeft(2, '0');
    String eMin = _rescheduleEndTime.minute.toString().padLeft(2, '0');

    // Get the dynamic session ID from the server
    int? sessionId = await _viewModel.getCurrentSessionId();
    if (sessionId == null) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to fetch session ID.")));
      return;
    }

    final result = await _viewModel.handleDelay({
      "meetingId": _selectedMeeting!['id'],
      "action": "new",
      "newDate": _rescheduleDate.toIso8601String().split('T')[0],
      "newStartTime": "$sHour:$sMin:00",
      "newEndTime": "$eHour:$eMin:00",
      "venue": _venueController.text.isNotEmpty ? _venueController.text : "TBD",
      "sessionID": sessionId
    });

    if (result['success']) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Created new meeting for remaining groups.")));
      _showDelayOptions = false; // Hide the options box
      _loadMeetings(); // Reload everything
    } else {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed: ${result['message']}")));
    }
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }

  List<Widget> _buildStatusFilteredList(String status) {
    final list = _filteredQueue.where((g) => g['Status'] == status).toList();
    return list.map((group) => _buildGroupCard(group, _queueList.indexOf(group))).toList();
  }

  List<Map<String, dynamic>> _getWaitingGroups() {
    return _filteredQueue.where((g) => g['Status'] != 'In-Progress').toList();
  }

  /// -------------------------------------------------------------------------
  /// WHAT IT DOES: Formats the time display to match React's logic.
  /// Shows "Done", "Live Now", or "In X min (Time)".
  /// -------------------------------------------------------------------------
  String _formatTimeLabel(Map<String, dynamic> group) {
    final status = group['Status'];
    if (status == 'Completed') return "Done";
    if (status == 'In-Progress') return "Live Now";
    
    final timeStr = group['MeetingTime'] ?? group['time'];
    if (timeStr == null) return "--:--";

    try {
      // -------------------------------------------------------------------------
      // CLEAN MINUTE CALCULATION (Matching Visual Expectation)
      // We calculate minutes by comparing [HH:mm] to [HH:mm] directly, 
      // ignoring seconds to match the image: 13:16 - 12:58 = Exactly 18 min.
      // -------------------------------------------------------------------------
      final parts = timeStr.toString().split(':'); 
      final h = int.parse(parts[0]);
      final m = int.parse(parts[1]);

      final int meetingTotalMins = (h * 60) + m;
      final int nowTotalMins = (_now.hour * 60) + _now.minute;
      
      int diffMins = meetingTotalMins - nowTotalMins;

      // Handle midnight wrap-around if necessary (for "Today's" meetings)
      if (diffMins < -720) diffMins += 1440; // If it was supposed to be 23 hours ago, it's likely today
      if (diffMins > 720) diffMins -= 1440;  // If it's 23 hours in the future, it might be yesterday's record

      final clockTime = timeStr.toString().substring(0, 5);

      // Find the first group that is NOT completed and NOT in-progress
      final firstWaitingGroup = _filteredQueue.firstWhere(
        (g) => g['Status'] != 'Completed' && g['Status'] != 'In-Progress',
        orElse: () => {},
      );

      bool isFirstWaiting = firstWaitingGroup['scheduleId'] == group['scheduleId'];

      // React Logic: if (mins <= 0) return `Due now (${clockTime})`;
      if (isFirstWaiting && diffMins <= 0) {
        return "Due now ($clockTime)";
      }

      // React Logic: return `In ${mins} min (${clockTime})`;
      return "In $diffMins min ($clockTime)";
    } catch (e) {
      return timeStr.toString().substring(0, 5);
    }
  }

  Widget _buildGroupCard(Map<String, dynamic> group, int displayIndex) {
    final status = group['Status'] ?? 'Waiting';
    final timeDisplay = _formatTimeLabel(group);

    return Card(
      key: ValueKey(group['scheduleId']),
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        onTap: () => _openGroupDetails(group),
        leading: CircleAvatar(
          backgroundColor: _getStatusColor(status).withValues(alpha: 0.1),
          child: Text("${displayIndex + 1}", style: TextStyle(color: _getStatusColor(status), fontWeight: FontWeight.bold)),
        ),
        title: Text("Group ${group['GroupIDs'] ?? group['groupID']}", style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text("Supervisor: ${group['SupervisorName'] ?? 'No Supervisor'}"),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  timeDisplay, 
                  style: TextStyle(
                    fontWeight: FontWeight.bold, 
                    color: status == 'In-Progress' ? Colors.blue : (status == 'Completed' ? Colors.green : Colors.grey.shade700)
                  )
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(status, style: TextStyle(color: _getStatusColor(status), fontSize: 10)),
                ),
              ],
            ),
            const SizedBox(width: 8),
            if (status != 'In-Progress' && status != 'Completed')
              const Icon(Icons.drag_indicator, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Queue Handler Dashboard",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            Text(
              "Manage student evaluation queues and meeting schedules",
              style: TextStyle(
                fontSize: 12,
                color: Colors.black.withValues(alpha: 0.6),
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => QueueHandlerProfileView(userMap: widget.userData[0])),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _selectedMeeting != null ? _loadQueue(_selectedMeeting!['id']) : _loadMeetings(),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'FYP-1', label: Text('FYP-1')),
                    ButtonSegment(value: 'FYP-2', label: Text('FYP-2')),
                  ],
                  selected: {_selectedFypType},
                  onSelectionChanged: (Set<String> newSelection) {
                    setState(() {
                      _selectedFypType = newSelection.first;
                      _loadMeetings();
                    });
                  },
                ),
                const SizedBox(height: 16),
                if (_todayMeetings.isNotEmpty)
                  DropdownButtonFormField<Map<String, dynamic>>(
                    value: _selectedMeeting,
                    decoration: const InputDecoration(
                      labelText: "Select Active Meeting",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.meeting_room),
                    ),
                    items: _todayMeetings.map((m) => DropdownMenuItem(value: m, child: Text(m['title']))).toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedMeeting = val;
                        _loadQueue(val!['id']);
                      });
                    },
                  ),
                const SizedBox(height: 10),
                TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: "Search groups by name or project...",
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (val) => _filterQueue(),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _sortQueueByGender,
                        icon: const Icon(Icons.auto_awesome, color: Colors.white),
                        label: const Text("Sort by Gender", style: TextStyle(color: Colors.white, fontSize: 13)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepOrange,
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _sortQueueBySupervisor,
                        icon: const Icon(Icons.people, color: Colors.white),
                        label: const Text("Sort by Supervisor", style: TextStyle(color: Colors.white, fontSize: 13)),
                      ),
                    ),
                  ],
                ),
                if (_selectedMeeting != null) ...[
                  const SizedBox(height: 16),
                  _buildDelayManagementCard(),
                ],
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredQueue.isEmpty
                ? const Center(child: Text("No groups found."))
                : Column(
              children: [
                _buildSectionHeader("Currently Presenting", Icons.play_circle_fill, Colors.blue),
                ..._buildStatusFilteredList('In-Progress'),
                _buildSectionHeader("Waiting List", Icons.pause_circle_filled, Colors.orange),
                Expanded(
                  child: ReorderableListView.builder(
                    onReorder: _onReorder,
                    itemCount: _getWaitingGroups().length,
                    itemBuilder: (context, index) {
                      final group = _getWaitingGroups()[index];
                      return _buildGroupCard(group, _queueList.indexOf(group));
                    },
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