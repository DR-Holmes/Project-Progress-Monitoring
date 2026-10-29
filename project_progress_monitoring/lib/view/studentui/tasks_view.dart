import 'package:flutter/material.dart';
import 'package:project_progress_monitoring/view/studentui/task_deatils_view.dart';
import '../../viewmodels/studentviewmodel/tasks_view_model.dart';

// --- VIEW ---
// Newbie Note: This screen displays two tabs: Individual Tasks and Group Tasks.
// It helps the student track their progress and see what is due soon.
class TasksView extends StatefulWidget {
  final Map<String, dynamic> userMap;
  const TasksView({super.key, required this.userMap});

  @override
  State<TasksView> createState() => _TasksViewState();
} // End of TasksView class

class _TasksViewState extends State<TasksView> {
  // Connecting to the ViewModel for task logic.
  final TasksViewModel _viewModel = TasksViewModel();

  // Local state to store categorized tasks and loading status.
  bool _isLoading = true;
  List<Map<String, dynamic>> _individualTasks = [];
  List<Map<String, dynamic>> _groupTasks = [];

  @override
  void initState() {
    super.initState();
    // Load the tasks when the screen first opens.
    _loadTasks();
  } // End of initState method

  // --- LOGIC SECTION ---

  // Fetches tasks from the API and splits them into Individual and Group lists.
  Future<void> _loadTasks() async {
    setState(() => _isLoading = true);
    String studentId = widget.userMap['id'] ?? "";

    // Fetch the combined list of tasks.
    List<Map<String, dynamic>> allTasks = await _viewModel.fetchTasks(studentId);

    if (mounted) {
      // Update the UI with the filtered lists.
      setState(() {
        // FYP TALKING POINT: "We use simple list filtering to separate individual assignments from team-based project milestones."
        _individualTasks = allTasks.where((t) => t['assignedType']?.toString().toLowerCase() == 'individual').toList();
        _groupTasks = allTasks.where((t) => t['assignedType']?.toString().toLowerCase() == 'group').toList();
        _isLoading = false;
      }); // End of setState
    } // End of if (mounted)
  } // End of _loadTasks method

  // Helper function to pick a color based on task status.
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'overdue':
        return Colors.red;
      case 'pending':
      default:
        return Colors.orange;
    } // End of switch
  } // End of _getStatusColor method

  // Helper function to pick an icon based on task status.
  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Icons.check_circle;
      case 'overdue':
        return Icons.error;
      case 'pending':
      default:
        return Icons.pending;
    } // End of switch
  } // End of _getStatusIcon method

  // --- UI COMPONENTS ---

  // Builds a single task card showing title, due date, and progress bar.
  Widget _buildTaskCard(Map<String, dynamic> task) {
    String status = task['status'] ?? 'pending';
    int progress = task['progress'] ?? 0;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => TaskDetailsView(task: task)),
        ).then((_) => _loadTasks()), // Reload tasks when coming back from details (to show updated status/progress)
        child: Padding(
          padding: const EdgeInsets.all(15.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Status Icon
              Icon(_getStatusIcon(status), color: _getStatusColor(status), size: 30),
              const SizedBox(width: 15),
              
              // 2. Task Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task['title'] ?? task['description'] ?? "Untitled Task",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ), // End of Text
                    const SizedBox(height: 5),
                    Text(
                      "Due Date: ${task['dueDate'] ?? 'N/A'}",
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                    ), // End of Text
                    const SizedBox(height: 12),
                    
                    // 3. Progress Bar
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(5),
                            child: LinearProgressIndicator(
                              value: progress / 100, // Converts 75% to 0.75
                              backgroundColor: Colors.grey.shade200,
                              color: _getStatusColor(status),
                              minHeight: 8,
                            ), // End of LinearProgressIndicator
                          ), // End of ClipRRect
                        ), // End of Expanded
                        const SizedBox(width: 12),
                        Text(
                          "$progress%",
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                        ), // End of Text
                      ], // End of Row children
                    ), // End of Row
                  ], // End of Column children
                ), // End of Column
              ), // End of Expanded
            ], // End of Row children
          ), // End of Padding
        ), // End of InkWell
      ), // End of Card
    ); // End of widget
  } // End of _buildTaskCard method

  // Builds the scrolling list of tasks.
  Widget _buildTaskList(List<Map<String, dynamic>> tasks) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator()); // End of Center
    } // End of if (_isLoading)

    if (tasks.isEmpty) {
      // FYP TALKING POINT: "If there are no tasks, we provide a RefreshIndicator so the student can pull down to check for new assignments."
      return RefreshIndicator(
        onRefresh: _loadTasks,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 100),
            Center(
              child: Text(
                "No tasks found.",
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ), // End of Text
            ), // End of Center
          ], // End of children
        ), // End of ListView
      ); // End of RefreshIndicator
    } // End of if (tasks.isEmpty)

    return RefreshIndicator(
      onRefresh: _loadTasks,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: tasks.length,
        itemBuilder: (context, index) {
          return _buildTaskCard(tasks[index]);
        }, // End of itemBuilder
      ), // End of ListView.builder
    ); // End of RefreshIndicator
  } // End of _buildTaskList method

  @override
  Widget build(BuildContext context) {
    // DefaultTabController manages the switching between the two tabs.
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text("My Tasks", style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadTasks,
            ) // End of IconButton
          ], // End of actions
          bottom: const TabBar(
            labelColor: Colors.blue,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.blue,
            tabs: [
              Tab(text: "Individual"),
              Tab(text: "Group"),
            ], // End of tabs
          ), // End of TabBar
        ), // End of AppBar
        
        body: TabBarView(
          children: [
            _buildTaskList(_individualTasks), // Contents of Tab 1
            _buildTaskList(_groupTasks),      // Contents of Tab 2
          ], // End of TabBarView children
        ), // End of TabBarView
      ), // End of Scaffold
    ); // End of DefaultTabController
  } // End of build method
} // End of _TasksViewState class