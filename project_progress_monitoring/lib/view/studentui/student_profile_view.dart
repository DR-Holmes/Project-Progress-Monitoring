import 'package:flutter/material.dart';
import '../../viewmodels/studentviewmodel/student_profile_view_model.dart';

// --- VIEW ---
// Newbie Note: This screen displays the logged-in student's personal information.
// It also provides options to change their password or logout.
class StudentProfileView extends StatefulWidget {
  final Map<String, dynamic> userMap;
  const StudentProfileView({super.key, required this.userMap});

  @override
  State<StudentProfileView> createState() => _StudentProfileViewState();
} // End of StudentProfileView class

class _StudentProfileViewState extends State<StudentProfileView> {
  // Connecting to the ViewModel for profile actions.
  final StudentProfileViewModel _viewModel = StudentProfileViewModel();
  
  // Controller to capture the new password from the text field.
  final TextEditingController _passwordController = TextEditingController();
  
  // Loading state for the password update button.
  bool _isUpdatingPassword = false;

  // --- LOGIC SECTION ---

  // Opens a pop-up dialog to let the user type a new password.
  void _showChangePasswordDialog() {
    showDialog(
      context: context,
      builder: (context) {
        // StatefulBuilder allows us to use setState INSIDE the dialog.
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text("Change Password"),
              content: TextField(
                controller: _passwordController,
                obscureText: true, // Hides the password characters (•••••)
                decoration: const InputDecoration(
                  labelText: "New Password",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock_outline),
                ), // End of InputDecoration
              ), // End of TextField
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
                ElevatedButton(
                  onPressed: _isUpdatingPassword ? null : () async {
                    if (_passwordController.text.trim().isEmpty) return;
                    
                    // Show loading spinner on the button.
                    setDialogState(() => _isUpdatingPassword = true);
                    
                    // Call ViewModel to update the password in the database.
                    bool success = await _viewModel.updatePassword(
                      widget.userMap['id'].toString(),
                      _passwordController.text.trim()
                    );
                    
                    // Hide loading spinner.
                    setDialogState(() => _isUpdatingPassword = false);
                    
                    if (mounted) {
                      Navigator.pop(context); // Close the dialog.
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(success ? "Password Updated!" : "Update Failed"),
                          backgroundColor: success ? Colors.green : Colors.red,
                        ) // End of SnackBar
                      ); // End of showSnackBar
                      _passwordController.clear(); // Clear the text field.
                    } // End of if (mounted)
                  }, // End of onPressed
                  child: _isUpdatingPassword 
                      ? const SizedBox(width: 15, height: 15, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text("Save"),
                ) // End of ElevatedButton
              ], // End of actions
            ); // End of AlertDialog
          } // End of builder
        ); // End of StatefulBuilder
      } // End of builder
    ); // End of showDialog
  } // End of _showChangePasswordDialog method

  // --- UI SECTION ---

  // Helper widget to display a single row of info (like Email or ID).
  Widget _infoTile(IconData icon, String label, String value) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), shape: BoxShape.circle),
        child: Icon(icon, color: Colors.blue),
      ), // End of Container
      title: Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      subtitle: Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
    ); // End of ListTile
  } // End of _infoTile method

  @override
  Widget build(BuildContext context) {
    final name = widget.userMap['name'] ?? "Student";
    final email = widget.userMap['email'] ?? "Not Provided";
    final id = widget.userMap['id'] ?? "No ID";

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Profile", style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ), // End of AppBar
      
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Profile Picture Placeholder
            const CircleAvatar(
              radius: 45,
              backgroundColor: Colors.blue,
              child: Icon(Icons.person, size: 45, color: Colors.white),
            ), // End of CircleAvatar
            const SizedBox(height: 15),
            Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
            const Text("Final Year Student", style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 30),
            
            // Displaying Student Data
            _infoTile(Icons.badge, "Registration Number", id.toString()),
            _infoTile(Icons.email, "Email Address", email),
            
            const SizedBox(height: 30),
            
            // --- ACTION BUTTONS ---

            // Reset Password Button
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                onPressed: _showChangePasswordDialog,
                icon: const Icon(Icons.lock_reset),
                label: const Text("Reset Password", style: TextStyle(fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ), // End of styleFrom
              ), // End of ElevatedButton
            ), // End of SizedBox
            
            const SizedBox(height: 20),
            
            // Logout Button
            TextButton.icon(
              onPressed: () => _viewModel.logout(context),
              icon: const Icon(Icons.logout, color: Colors.red),
              label: const Text("Logout", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            ), // End of TextButton.icon
          ], // End of Column children
        ), // End of Column
      ), // End of body
    ); // End of Scaffold
  } // End of build method
} // End of _StudentProfileViewState class