import 'package:flutter/material.dart';
import '../../viewmodels/comitteeviewmodel/committee_evaluation_view_model.dart';

/// 🏫 SCHOOL LESSON: This view allows committee members to evaluate student groups.
/// It displays student details, lets you grade them on various sub-parameters,
/// and allows you to add/edit evaluator remarks for each student.
class CommitteeEvaluationView extends StatefulWidget {
  final int meetingId;
  final int groupId;
  final int parameterId;
  final String parameterName;
  final String fypType;
  final List<Map<String, dynamic>> userData;

  const CommitteeEvaluationView({
    super.key,
    required this.meetingId,
    required this.groupId,
    required this.parameterId,
    required this.parameterName,
    required this.fypType,
    required this.userData,
  });

  @override
  State<CommitteeEvaluationView> createState() => _CommitteeEvaluationViewState();
}

class _CommitteeEvaluationViewState extends State<CommitteeEvaluationView> {
  final CommitteeEvaluationViewModel _viewModel = CommitteeEvaluationViewModel();
  
  // 📝 Track which student's remark section is currently open
  String? _openRemarkKey;
  
  // 📝 Text controllers for remarks to make editing smooth
  final TextEditingController _remarkEditController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  void _refreshData() async {
    final userId = widget.userData[0]['id'].toString();
    await _viewModel.fetchData(widget.meetingId, widget.groupId, widget.parameterId, widget.fypType, userId);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Evaluation Panel", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _viewModel.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // --- Top Summary Card ---
                _buildHeaderCard(),
                
                // --- Students List ---
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _viewModel.students.length,
                    itemBuilder: (context, index) {
                      final student = _viewModel.students[index];
                      return _buildStudentCard(student);
                    },
                  ),
                ),
                
                // --- Bottom Save Button ---
                _buildBottomAction(),
              ],
            ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.parameterName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              Text("Type: ${widget.fypType.toUpperCase()}", style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(20)),
            child: Text("${_viewModel.parameter?['percentage'] ?? 0}% Weight", style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 11)),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentCard(Map<String, dynamic> student) {
    final key = _viewModel.getStudentKey(student);
    final bool isOpen = _openRemarkKey == key;
    final meta = _viewModel.remarkMeta[key];

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Student Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(student['studentName'] ?? student['StudentName'] ?? "Unknown", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  Text("CGPA: ${student['currentCGPA']}", style: const TextStyle(color: Colors.grey, fontSize: 11)),
                ],
              ),
              OutlinedButton(
                onPressed: () => _handleToggleRemark(student),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.blueAccent),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                child: Text(
                  isOpen ? "Hide Remarks" : (meta != null ? "Edit Remarks" : "Add Remarks"),
                  style: const TextStyle(fontSize: 10, color: Colors.blueAccent),
                ),
              ),
            ],
          ),
          
          const Divider(height: 32),
          
          // Sub-Parameters
          if (_viewModel.subParameters.isEmpty)
            const Text("No sub-parameters available", style: TextStyle(fontSize: 11, color: Colors.grey))
          else
            ..._viewModel.subParameters.map((sp) => _buildSubParamRow(key, sp)).toList(),
            
          // Remarks Section (Collapsible)
          if (isOpen) _buildRemarksSection(student, key),
        ],
      ),
    );
  }

  Widget _buildSubParamRow(String studentKey, Map<String, dynamic> sp) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text(sp['name'] ?? "", style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
          Expanded(flex: 1, child: Text("${sp['percentage']}%", style: const TextStyle(fontSize: 11, color: Colors.grey), textAlign: TextAlign.center)),
          Expanded(
            flex: 2,
            child: SizedBox(
              height: 40,
              child: TextField(
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  contentPadding: EdgeInsets.zero,
                  filled: true,
                  fillColor: Colors.grey[50],
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade200)),
                ),
                onChanged: (val) {
                  _viewModel.marks[studentKey]![sp['id']] = val;
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRemarksSection(Map<String, dynamic> student, String key) {
    final meta = _viewModel.remarkMeta[key];
    final lastUpdate = meta != null ? (meta['updatedAt'] ?? meta['createdAt']) : null;

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.only(top: 16),
      decoration: const BoxDecoration(border: Border(top: BorderSide(color: Colors.grey, width: 0.2))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Evaluator Remarks", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          if (lastUpdate != null)
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 8),
              child: Text("Last updated: ${lastUpdate.toString().replaceAll('T', ' ').substring(0, 16)}", style: const TextStyle(color: Colors.grey, fontSize: 10)),
            ),
          const SizedBox(height: 8),
          TextField(
            controller: _remarkEditController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: "Write remarks here...",
              filled: true,
              fillColor: Colors.grey[50],
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
            style: const TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: _viewModel.isSavingRemark ? null : () => _handleSaveRemark(student, key),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.black, elevation: 0),
              child: Text(_viewModel.isSavingRemark ? "Saving..." : "Save / Update", style: const TextStyle(color: Colors.white, fontSize: 11)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomAction() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -2))]),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          onPressed: _viewModel.isSubmitting ? null : _handleSaveMarks,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          child: _viewModel.isSubmitting 
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text("Save Evaluation Marks", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  // --- Logic Handlers ---

  void _handleToggleRemark(Map<String, dynamic> student) async {
    final key = _viewModel.getStudentKey(student);
    if (_openRemarkKey == key) {
      setState(() => _openRemarkKey = null);
    } else {
      setState(() => _viewModel.isLoading = true);
      final userId = widget.userData[0]['id'].toString();
      final remarkText = await _viewModel.fetchStudentRemarks(student, userId, widget.fypType, widget.meetingId);
      setState(() {
        _openRemarkKey = key;
        _remarkEditController.text = remarkText;
        _viewModel.isLoading = false;
      });
    }
  }

  void _handleSaveRemark(Map<String, dynamic> student, String key) async {
    final userId = widget.userData[0]['id'].toString();
    final remarkText = _remarkEditController.text;
    
    if (remarkText.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please write remarks first")));
      return;
    }

    final ok = await _viewModel.saveRemark(student, widget.meetingId, userId, widget.fypType, remarkText);
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Remarks saved successfully ✅")));
      setState(() => _openRemarkKey = null);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error saving remark ❌")));
    }
  }

  void _handleSaveMarks() async {
    final userId = widget.userData[0]['id'].toString();
    final ok = await _viewModel.submitAllMarks(widget.meetingId, widget.parameterId, userId, widget.fypType);
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Evaluation marks saved successfully ✅")));
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error saving marks ❌")));
    }
  }
}
