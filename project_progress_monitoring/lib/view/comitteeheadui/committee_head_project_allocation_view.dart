import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart' hide Border;
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../api_config.dart';
import '../../viewmodels/comitteeheadviewmodel/committee_head_project_allocation_view_model.dart';

// ---------------------------------------------------------
// WHAT IS THIS FILE?
// This is the "View" (UI Screen) for Committee Head Project Allocation.
// It allows:
// - Semester group toggle (FYP-1 / FYP-2).
// - Dropdown to select dynamic enrolled groups.
// - Group student details panel.
// - Discovery Panel of Offered Projects with custom categories & search text.
// - PREMIUM EXTRA: Pick and Parse an Excel sheet (.xlsx/.xls) to preview and bulk import project ideas!
// ---------------------------------------------------------

class CommitteeHeadProjectAllocationView extends StatefulWidget {
  final int? initialGroupId;
  final int? initialMeetingId;

  const CommitteeHeadProjectAllocationView({
    super.key,
    this.initialGroupId,
    this.initialMeetingId,
  });

  @override
  State<CommitteeHeadProjectAllocationView> createState() => _CommitteeHeadProjectAllocationViewState();
}

class _CommitteeHeadProjectAllocationViewState extends State<CommitteeHeadProjectAllocationView> {
  final CommitteeHeadProjectAllocationViewModel _viewModel = CommitteeHeadProjectAllocationViewModel();

  String _activeFYP = "FYP-1";
  String _selectedCategory = "All";
  String _searchText = "";
  bool _isBulkUploading = false;
  
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _remarksController = TextEditingController();

  final List<String> _categories = ["All", "Healthcare", "Education", "IoT", "Security"];

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    setState(() => _viewModel.isLoading = true);
    await _viewModel.fetchOfferedProjects();

    if (widget.initialGroupId != null) {
      _viewModel.selectedGroupId = widget.initialGroupId.toString();
      await _viewModel.fetchSpecificGroupMembers(_viewModel.selectedGroupId!);
    } else {
      await _viewModel.fetchEnrolledGroups(_activeFYP);
    }
    setState(() => _viewModel.isLoading = false);
  }

  void _switchFYP(String type) async {
    if (_activeFYP == type) return;
    setState(() {
      _activeFYP = type;
      _viewModel.selectedGroupId = null;
      _viewModel.groupMembers = [];
    });
    setState(() => _viewModel.isLoading = true);
    await _viewModel.fetchEnrolledGroups(type);
    setState(() => _viewModel.isLoading = false);
  }

  void _onGroupSelected(String? groupId) async {
    if (groupId == null) return;
    setState(() {
      _viewModel.selectedGroupId = groupId;
    });
    await _viewModel.fetchSpecificGroupMembers(groupId);
    setState(() {});
  }

  // ---------------------------------------------------------
  // FUNCTION: _importExcelFile
  // Opens file picker, decodes sheet rows using excel package,
  // and launches the beautiful bulk preview dialog.
  // ---------------------------------------------------------
  Future<void> _importExcelFile() async {
    try {
      debugPrint("--> [Committee Head] Opening File Picker for xlsx/xls spreadsheet...");
      FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
      );
      if (result == null || result.files.isEmpty || result.files.single.path == null) {
        debugPrint("--> [Committee Head] Excel selection cancelled.");
        return;
      }
      
      final filePath = result.files.single.path!;
      final bytes = File(filePath).readAsBytesSync();
      var excel = Excel.decodeBytes(bytes);
      
      List<Map<String, dynamic>> parsedProjects = [];
      
      for (var table in excel.tables.keys) {
        var sheet = excel.tables[table];
        if (sheet == null || sheet.maxRows <= 1) continue;
        
        // Find column indices
        var headerRow = sheet.rows[0];
        int titleIdx = -1;
        int objectivesIdx = -1;
        int suggestedByIdx = -1;
        int statusIdx = -1;
        
        for (int i = 0; i < headerRow.length; i++) {
          final colName = (headerRow[i]?.value?.toString() ?? '').toLowerCase().trim();
          if (colName.contains("title")) {
            titleIdx = i;
          } else if (colName.contains("objective") || colName.contains("description") || colName.contains("remark")) {
            objectivesIdx = i;
          } else if (colName.contains("suggested") || colName.contains("by")) {
            suggestedByIdx = i;
          } else if (colName.contains("status") || colName.contains("active")) {
            statusIdx = i;
          }
        }
        
        // Fallback default index mappings
        if (titleIdx == -1) {
          titleIdx = 0;
        }
        if (suggestedByIdx == -1 && sheet.maxColumns > 1) {
          suggestedByIdx = 1;
        }
        if (statusIdx == -1 && sheet.maxColumns > 2) {
          statusIdx = 2;
        }
        if (objectivesIdx == -1 && sheet.maxColumns > 3) {
          objectivesIdx = 3;
        }
        
        for (int rowIdx = 1; rowIdx < sheet.maxRows; rowIdx++) {
          var row = sheet.rows[rowIdx];
          if (row.isEmpty || row.length <= titleIdx || row[titleIdx]?.value == null) continue;
          
          final title = row[titleIdx]?.value?.toString() ?? '';
          final suggestedBy = (suggestedByIdx != -1 && suggestedByIdx < row.length) ? row[suggestedByIdx]?.value?.toString() : null;
          final statusVal = (statusIdx != -1 && statusIdx < row.length) ? (row[statusIdx]?.value?.toString() ?? 'true') : 'true';
          final objectives = (objectivesIdx != -1 && objectivesIdx < row.length) ? (row[objectivesIdx]?.value?.toString() ?? '') : '';
          
          parsedProjects.add({
            "title": title,
            "suggestedBy": (suggestedBy == null || suggestedBy.trim().isEmpty) ? null : suggestedBy.trim(),
            "projectStatus": statusVal.toLowerCase() == 'true' || statusVal == '1',
            "objectives": objectives,
          });
        }
      }
      
      if (parsedProjects.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("⚠️ Excel parsed successfully, but no valid projects were found.")),
          );
        }
        return;
      }
      
      _showImportPreviewDialog(parsedProjects);
    } catch (e) {
      debugPrint("!!! [Committee Head Error] Failed to parse Excel: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ Failed to parse Excel file: $e")),
        );
      }
    }
  }

  // Shows beautiful preview list of excel rows with bulk upload trigger
  void _showImportPreviewDialog(List<Map<String, dynamic>> projectsList) {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  const Icon(Icons.table_chart, color: Colors.green, size: 24),
                  const SizedBox(width: 10),
                  Text("Import Preview (${projectsList.length})", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                height: 350,
                child: _isBulkUploading
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(color: Colors.green),
                            SizedBox(height: 16),
                            Text("Uploading projects to database...", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: projectsList.length,
                        itemBuilder: (context, idx) {
                          final p = projectsList[idx];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            color: Colors.grey.shade50,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(color: Colors.grey.shade200),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(p['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
                                  const SizedBox(height: 4),
                                  Text("Objectives: ${p['objectives'] ?? 'N/A'}", style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                                  if (p['suggestedBy'] != null) ...[
                                    const SizedBox(height: 4),
                                    Text("Suggested By: ${p['suggestedBy']}", style: const TextStyle(fontSize: 10, color: Colors.blue, fontWeight: FontWeight.bold)),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
              actions: [
                TextButton(
                  onPressed: _isBulkUploading ? null : () => Navigator.pop(context),
                  child: const Text("Cancel", style: TextStyle(color: Colors.red)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, elevation: 0),
                  onPressed: _isBulkUploading ? null : () async {
                    final messenger = ScaffoldMessenger.of(context);
                    final nav = Navigator.of(context);

                    setDialogState(() => _isBulkUploading = true);
                    final success = await _executeBulkUpload(projectsList);
                    setDialogState(() => _isBulkUploading = false);

                    if (mounted) {
                      nav.pop();
                      if (success) {
                        messenger.showSnackBar(
                          const SnackBar(content: Text("✅ Bulk Excel upload completed! Offered projects updated."), backgroundColor: Colors.green),
                        );
                        _initializeData(); // Reload projects discovery list
                      } else {
                        messenger.showSnackBar(
                          const SnackBar(content: Text("❌ Failed to complete bulk upload. Some items errored."), backgroundColor: Colors.red),
                        );
                      }
                    }
                  },
                  child: const Text("Bulk Upload", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Executes sequential POST requests for all Excel projects
  Future<bool> _executeBulkUpload(List<Map<String, dynamic>> projectsList) async {
    try {
      // 1. Fetch Latest Session ID
      final sessionUrl = Uri.parse("${ApiConfig.baseUrl}/grading-analysis/session-wise");
      final sessionResponse = await http.get(sessionUrl);
      int latestSessionId = 1;
      if (sessionResponse.statusCode == 200) {
        final List sessionsList = json.decode(sessionResponse.body);
        if (sessionsList.isNotEmpty) {
          sessionsList.sort((a, b) => (b['SessionId'] as int).compareTo(a['SessionId'] as int));
          latestSessionId = sessionsList[0]['SessionId'] ?? 1;
        }
      }

      // 2. Loop and POST each project
      for (final p in projectsList) {
        final projUrl = Uri.parse("${ApiConfig.baseUrl}/projects");
        final response = await http.post(
          projUrl,
          headers: {"Content-Type": "application/json"},
          body: json.encode(p),
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          final Map<String, dynamic> created = json.decode(response.body);
          final int newId = created['id'] ?? 0;

          // Link in Offered Projects table
          final offerUrl = Uri.parse("${ApiConfig.baseUrl}/offered-projects");
          await http.post(
            offerUrl,
            headers: {"Content-Type": "application/json"},
            body: json.encode({
              "sessionID": latestSessionId,
              "projectID": newId,
            }),
          );
        }
      }
      return true;
    } catch (e) {
      debugPrint("!!! [Committee Head Bulk Error] $e");
      return false;
    }
  }

  void _handleAllocationSubmit() async {
    if (_viewModel.selectedGroupId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ Please select a student group first.")),
      );
      return;
    }

    if (_viewModel.selectedProjectId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ Please select a project from the offered list.")),
      );
      return;
    }

    final success = await _viewModel.allocateProjectToGroup(
      _viewModel.selectedGroupId!,
      int.parse(_viewModel.selectedProjectId!),
    );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Project allocated successfully!"), backgroundColor: Colors.green),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("❌ Failed to allocate project. Try again."), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    List<dynamic> filteredProjects = _viewModel.projects.where((p) {
      final title = (p['Title'] ?? '').toString().toLowerCase();
      final objectives = (p['Objectives'] ?? '').toString().toLowerCase();
      final matchSearch = title.contains(_searchText.toLowerCase()) || objectives.contains(_searchText.toLowerCase());

      if (_selectedCategory == "All") return matchSearch;
      final isCategoryMatch = title.contains(_selectedCategory.toLowerCase()) || objectives.contains(_selectedCategory.toLowerCase());
      return matchSearch && isCategoryMatch;
    }).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Project Allocation (Head)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (widget.initialGroupId == null) ...[
                          Row(
                            children: [
                              _fypToggleButton("FYP-1"),
                              const SizedBox(width: 10),
                              _fypToggleButton("FYP-2"),
                            ],
                          ),
                          const SizedBox(height: 16),
                        ],

                        const Text("Select Student Group", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
                        const SizedBox(height: 8),

                        widget.initialGroupId != null
                            ? Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey.shade300)),
                                child: Text("Selected Group: ${widget.initialGroupId}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.blue)),
                              )
                            : Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(10), color: Colors.grey.shade50),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    isExpanded: true,
                                    hint: Text("Select from $_activeFYP groups"),
                                    value: _viewModel.selectedGroupId,
                                    items: _viewModel.groups.map((g) {
                                      final idVal = g['groupName'] ?? g['GroupID'] ?? g['id'];
                                      final membersList = g['members'] as List?;
                                      final membersText = membersList != null ? membersList.join(', ') : '';
                                      return DropdownMenuItem<String>(
                                        value: idVal.toString(),
                                        child: Text("Group $idVal ($membersText)"),
                                      );
                                    }).toList(),
                                    onChanged: _onGroupSelected,
                                  ),
                                ),
                              ),
                        const SizedBox(height: 20),

                        if (_viewModel.isMembersLoading) ...[
                          const Center(child: Padding(padding: EdgeInsets.all(20.0), child: CircularProgressIndicator())),
                        ] else if (_viewModel.groupMembers.isNotEmpty) ...[
                          const Text("Team Members", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
                          const SizedBox(height: 8),
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _viewModel.groupMembers.length,
                            itemBuilder: (context, idx) {
                              final student = _viewModel.groupMembers[idx];
                              return _buildMemberCard(student);
                            },
                          ),
                          const SizedBox(height: 20),
                        ],

                        const Divider(height: 30),

                        // Section Header with Excel Import Button
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Offered Projects Discovery", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black)),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green.shade50,
                                foregroundColor: Colors.green,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: Colors.green.shade200)),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                              onPressed: _importExcelFile,
                              icon: const Icon(Icons.file_upload, size: 16),
                              label: const Text("Import Excel", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        TextField(
                          controller: _searchController,
                          onChanged: (val) => setState(() => _searchText = val),
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.search, color: Colors.grey, size: 20),
                            hintText: "Search offered projects...",
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade200)),
                          ),
                          style: const TextStyle(fontSize: 13),
                        ),
                        const SizedBox(height: 12),

                        SizedBox(
                          height: 36,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _categories.length,
                            itemBuilder: (context, idx) {
                              final catName = _categories[idx];
                              final isSelected = _selectedCategory == catName;
                              return GestureDetector(
                                onTap: () => setState(() => _selectedCategory = catName),
                                child: Container(
                                  margin: const EdgeInsets.only(right: 8),
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  decoration: BoxDecoration(
                                    color: isSelected ? Colors.blue : Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: isSelected ? Colors.blue : Colors.grey.shade300),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(catName, style: TextStyle(color: isSelected ? Colors.white : Colors.black87, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, fontSize: 12)),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 16),

                        if (filteredProjects.isEmpty) ...[
                          Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 40), alignment: Alignment.center, child: Text("No matching projects found.", style: TextStyle(color: Colors.grey.shade500, fontSize: 13))),
                        ] else ...[
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: filteredProjects.length,
                            itemBuilder: (context, idx) {
                              final project = filteredProjects[idx];
                              final projId = (project['ProjectId'] ?? project['id']).toString();
                              final isSelected = _viewModel.selectedProjectId == projId;
                              return _buildProjectCard(project, isSelected, projId);
                            },
                          ),
                        ],

                        const SizedBox(height: 20),
                        const Text("Optional Objectives / Remarks", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _remarksController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            hintText: "Add specific instructions, objectives or requirements for this allocation...",
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade200)),
                          ),
                          style: const TextStyle(fontSize: 13),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -2))], border: Border(top: BorderSide(color: Colors.grey.shade200))),
                  child: SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), elevation: 0),
                      onPressed: _viewModel.isSubmitting ? null : _handleAllocationSubmit,
                      child: _viewModel.isSubmitting
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text("Allocate Selected Project", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13)),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _fypToggleButton(String label) {
    final isActive = _activeFYP == label;
    return Expanded(
      child: GestureDetector(
        onTap: () => _switchFYP(label),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? Colors.blue : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isActive ? Colors.blue : Colors.grey.shade300),
          ),
          alignment: Alignment.center,
          child: Text(label, style: TextStyle(color: isActive ? Colors.white : Colors.grey.shade700, fontWeight: FontWeight.bold, fontSize: 13)),
        ),
      ),
    );
  }

  Widget _buildMemberCard(Map<String, dynamic> student) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey.shade200), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.01), blurRadius: 4, offset: const Offset(0, 2))]),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(student['studentName'] ?? 'Unknown Name', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 4),
                Text(student['studentID'] ?? student['regNum'] ?? '', style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(6)),
                child: Text(student['Tech'] ?? 'N/A', style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 10)),
              ),
              const SizedBox(height: 4),
              Text("CGPA: ${student['currentCGPA'] ?? 'N/A'}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.black87)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildProjectCard(Map<String, dynamic> project, bool isSelected, String projId) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _viewModel.selectedProjectId = projId;
          _viewModel.selectedProjectTitle = project['Title'] ?? '';
          _remarksController.text = project['Objectives'] ?? '';
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.shade50 : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isSelected ? Colors.blue : Colors.grey.shade200, width: isSelected ? 1.5 : 1.0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(project['Title'] ?? 'Untitled Project Idea', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isSelected ? Colors.blue.shade900 : Colors.black87)),
                ),
                if (isSelected) const Icon(Icons.check_circle, color: Colors.blue, size: 20),
              ],
            ),
            const SizedBox(height: 8),
            Text(project['Objectives'] ?? 'No scope details loaded.', style: TextStyle(color: Colors.grey.shade600, fontSize: 11), maxLines: 2, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}
