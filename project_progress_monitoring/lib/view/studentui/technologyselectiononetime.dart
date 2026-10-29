import 'package:flutter/material.dart';
import '../../viewmodels/studentviewmodel/technologyselection_view_model.dart';
import 'group_options_view.dart';
import 'package:project_progress_monitoring/view/login_view.dart';

// ============================================================================
//               --- ONE-TIME TECHNOLOGY SELECTION SCREEN (VIEW) ---
// ============================================================================
// PRIMARY SCHOOLER NOTE:
// What does this screen do?
// This is a "One-Time" screen! A student only sees this the very first time they 
// log in, if they haven't picked a technology track (like Web, Flutter, AI) yet.
// Once they choose a tech, they are saved in the database and moved to the Group Options!
//
// Keep it simple! We use standard StatefulWidget state and setState() to redraw.
// ============================================================================
class TechnologySelectionView extends StatefulWidget {
  // Simple List of Maps to hold logged-in student details (like name, registration number).
  final List<Map<String, dynamic>> userData;

  const TechnologySelectionView({super.key, required this.userData});

  @override
  State<TechnologySelectionView> createState() => _TechnologySelectionViewState();
} // End of TechnologySelectionView class

class _TechnologySelectionViewState extends State<TechnologySelectionView> {
  // 1. Linking our brain file (ViewModel) here so we can ask it for available technologies!
  final TechnologySelectionViewModel _viewModel = TechnologySelectionViewModel();

  // 2. STATE VARIABLES:
  // - _technologies: List of all tech tracks (like AI, Flutter) fetched from the server.
  // - _selectedTechId: The specific ID number of the technology the student clicked on.
  // - _isLoading: True if we are fetching data from the internet, showing a spinner.
  // - _isSubmitting: True if we are sending their choice to the database (disables button).
  List<dynamic> _technologies = [];
  int? _selectedTechId;
  bool _isLoading = true;
  bool _isSubmitting = false;

  // --------------------------------------------------------------------------
  // initState: The startup bell!
  // Runs automatically the moment the screen loads to query all available technologies.
  // --------------------------------------------------------------------------
  @override
  void initState() {
    super.initState();
    _loadTechnologies();
  } // End of initState method

  // --------------------------------------------------------------------------
  // FUNCTION: Load available technologies from the database
  // --------------------------------------------------------------------------
  Future<void> _loadTechnologies() async {
    // A. Fetch tech options from our ViewModel brain
    List<dynamic> techs = await _viewModel.getTechnologies();
    
    // B. Save the list and turn off the loading spinner!
    setState(() {
      _technologies = techs;
      _isLoading = false;
    }); // End of setState
  } // End of _loadTechnologies method

  // --------------------------------------------------------------------------
  // FUNCTION: Save the chosen technology and go to Group Options screen
  // --------------------------------------------------------------------------
  Future<void> _submitSelection() async {
    // A. Validation: Make sure the student clicked at least one technology!
    if (_selectedTechId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a technology first.")),
      ); // End of showSnackBar
      return;
    } // End of if null

    // B. Turn on submit spinner to disable multiple rapid button clicks
    setState(() => _isSubmitting = true);

    // C. Get student's Arid registration number
    String regNum = widget.userData[0]['id']; 
    
    // D. Call ViewModel to save choice in the central database
    bool success = await _viewModel.updateTechnology(regNum, _selectedTechId!);

    // E. Turn off submit spinner
    setState(() => _isSubmitting = false);

    if (success) {
      if (!mounted) return;

      // F. Save the chosen Tech ID locally so other views know about it
      widget.userData[0]['selectedTech'] = _selectedTechId;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Technology updated successfully!")),
      ); // End of showSnackBar

      // G. Go to GroupOptionsView screen where they can Create a Group or Join an Existing Group!
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => GroupOptionsView(userData: widget.userData))
      ); // End of Navigator.pushReplacement

    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to update technology. Try again.")),
      ); // End of showSnackBar
    } // End of success check
  } // End of _submitSelection method

  // --------------------------------------------------------------------------
  // FUNCTION: Logout and go back to Login screen
  // --------------------------------------------------------------------------
  // WHAT IT DOES: Clears all navigation history and returns to the Login screen.
  // WHY IT EXISTS: The student may want to log out while choosing their technology track.
  void _logout() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginView()),
      (route) => false, // Remove every screen from the history stack
    ); // End of Navigator.pushAndRemoveUntil
  } // End of _logout method

  // --------------------------------------------------------------------------
  // BUILD METHOD: Painting the technology selection UI!
  // --------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Select Technology", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          // Logout Button
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            tooltip: "Logout",
            onPressed: _logout,
          ), // End of logout IconButton
        ], // End of actions
      ), // End of AppBar
      
      body: _isLoading
          ? const Center(child: CircularProgressIndicator()) // Shows a round spinning wheel while loading!
          : Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Header label text
            const Text(
              "Choose your specific technology:",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue),
            ), // End of Text
            const SizedBox(height: 5),
            const Text(
              "This will determine which project tracks you are eligible for.",
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ), // End of Text
            const SizedBox(height: 25),
            
            // 2. The Scrolling List of Options
            Expanded(
              child: _technologies.isEmpty
                  ? const Center(child: Text("No technologies available."))
                  : ListView.builder(
                itemCount: _technologies.length,
                itemBuilder: (context, index) {
                  final tech = _technologies[index];
                  
                  // RadioListTile allows only ONE technology to be selected at a time!
                  return Card(
                    elevation: 1,
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.grey.shade100),
                    ),
                    child: RadioListTile<int>(
                      activeColor: Colors.blue,
                      title: Text(
                        tech['name'] ?? "Unknown",
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ), // End of Text
                      value: tech['id'],
                      groupValue: _selectedTechId,
                      onChanged: (int? value) {
                        // When a technology is clicked, update state and redraw!
                        setState(() {
                          _selectedTechId = value;
                        }); // End of setState
                      }, // End of onChanged
                    ), // End of RadioListTile
                  ); // End of Card
                }, // End of itemBuilder
              ), // End of ListView.builder
            ), // End of Expanded
            
            const SizedBox(height: 20),
            
            // 3. Save & Continue Button
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitSelection,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ), // End of styleFrom
                child: _isSubmitting
                    ? const SizedBox(
                        height: 25, 
                        width: 25, 
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                      )
                    : const Text("Save & Continue", style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              ), // End of ElevatedButton
            ), // End of SizedBox
          ], // End of Column children
        ), // End of Padding
      ), // End of body
    ); // End of Scaffold
  } // End of build method
} // End of _TechnologySelectionViewState class