import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../viewmodels/datacellviewmodel/datacell_dashboard_view_model.dart';
import 'datacell_profile_view.dart';

class DatacellDashboardView extends StatefulWidget {
  final List<Map<String, dynamic>> userData;
  const DatacellDashboardView({super.key, required this.userData});

  @override
  State<DatacellDashboardView> createState() => _DatacellDashboardViewState();
}

class _DatacellDashboardViewState extends State<DatacellDashboardView> {
  final DatacellDashboardViewModel _viewModel = DatacellDashboardViewModel();
  
  bool _isStudentView = true;
  PlatformFile? _pickedFile;
  List<Map<String, String>> _previewData = []; // Using List<Map> as requested
  bool _isLoading = false;

  void _onToggle(bool isStudent) {
    setState(() {
      _isStudentView = isStudent;
      _pickedFile = null;
      _previewData = [];
    });
  }

  void _clearFile() {
    setState(() {
      _pickedFile = null;
      _previewData = [];
    });
  }

  Future<void> _pickFile() async {
    final file = await _viewModel.pickExcelFile();
    if (file != null) {
      setState(() {
        _pickedFile = file;
        _isLoading = true;
      });
      
      final type = _isStudentView ? "Student" : "Staff";
      final data = _viewModel.parseExcelForPreview(file.bytes!, type);
      
      setState(() {
        _previewData = data;
        _isLoading = false;
      });
    }
  }

  Future<void> _uploadData() async {
    if (_pickedFile == null) return;

    setState(() => _isLoading = true);
    
    final type = _isStudentView ? "Student" : "Staff";
    final result = await _viewModel.uploadExcel(
      _pickedFile!.bytes!, 
      _pickedFile!.name, 
      type
    );

    setState(() => _isLoading = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor: result['success'] ? Colors.green : Colors.red,
        ),
      );
      if (result['success']) {
        setState(() {
          _pickedFile = null;
          _previewData = [];
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Data Cell Dashboard"),
        backgroundColor: const Color(0xFF2C3E50),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (c) => DatacellProfileView(userMap: widget.userData[0])),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _viewModel.logout(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 20),
              _buildToggleSwitch(),
              const SizedBox(height: 20),
              _buildUploadCard(),
              if (_previewData.isNotEmpty) ...[
                const SizedBox(height: 24),
                _buildPreviewSection(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Welcome, ${widget.userData[0]['name']}",
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50)),
        ),
        const Text(
          "Manage student and staff records via Excel uploads",
          style: TextStyle(color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildToggleSwitch() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => _onToggle(true),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _isStudentView ? const Color(0xFF3498DB) : Colors.transparent,
                  borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), bottomLeft: Radius.circular(12)),
                ),
                child: Center(
                  child: Text(
                    "Student Data",
                    style: TextStyle(
                      color: _isStudentView ? Colors.white : Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => _onToggle(false),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: !_isStudentView ? const Color(0xFF3498DB) : Colors.transparent,
                  borderRadius: const BorderRadius.only(topRight: Radius.circular(12), bottomRight: Radius.circular(12)),
                ),
                child: Center(
                  child: Text(
                    "Staff Data",
                    style: TextStyle(
                      color: !_isStudentView ? Colors.white : Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  _isStudentView ? Icons.school : Icons.people,
                  color: const Color(0xFF3498DB),
                  size: 32,
                ),
                const SizedBox(width: 12),
                Text(
                  _isStudentView ? "Student Excel Upload" : "Staff / Users Excel Upload",
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _pickFile,
                      icon: const Icon(Icons.file_upload),
                      label: Text("Choose ${_isStudentView ? 'Student' : 'Staff'} Excel"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3498DB),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: OutlinedButton.icon(
                      onPressed: () => _viewModel.downloadSample(_isStudentView ? "Student" : "Staff"),
                      icon: const Icon(Icons.download),
                      label: const Text("Download Sample"),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF3498DB),
                        side: const BorderSide(color: Color(0xFF3498DB)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (_pickedFile != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.description, color: Colors.blue, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _pickedFile!.name,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.red, size: 20),
                      onPressed: _clearFile,
                      tooltip: "Remove file",
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: _isLoading 
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _uploadData,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF27AE60),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text("Upload", style: TextStyle(fontSize: 16)),
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewSection() {
    if (_previewData.isEmpty) return const SizedBox.shrink();

    final headers = _previewData.first.keys.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Data Preview (First 10 rows)",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            TextButton.icon(
              onPressed: _clearFile,
              icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
              label: const Text("Clear All", style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: headers.map((h) => DataColumn(label: Text(h, style: const TextStyle(fontWeight: FontWeight.bold)))).toList(),
              rows: _previewData.map((row) {
                return DataRow(
                  cells: headers.map((h) => DataCell(Text(row[h] ?? ""))).toList(),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}
