import 'package:flutter/material.dart';
import '../../viewmodels/comitteeviewmodel/committee_member_profile_view_model.dart';

class CommitteeMemberProfileView extends StatefulWidget {
  final List<Map<String, dynamic>> userData;
  const CommitteeMemberProfileView({super.key, required this.userData});

  @override
  State<CommitteeMemberProfileView> createState() => _CommitteeMemberProfileViewState();
}

class _CommitteeMemberProfileViewState extends State<CommitteeMemberProfileView> {
  final CommitteeMemberProfileViewModel _viewModel = CommitteeMemberProfileViewModel();
  final TextEditingController _passwordController = TextEditingController();
  bool _isUpdatingPassword = false;

  void _showChangePasswordDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text("Change Password"),
              content: TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "New Password",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock_outline),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
                ElevatedButton(
                  onPressed: _isUpdatingPassword ? null : () async {
                    if (_passwordController.text.trim().isEmpty) return;
                    setDialogState(() => _isUpdatingPassword = true);
                    bool success = await _viewModel.updatePassword(
                      widget.userData[0]['id'].toString(),
                      _passwordController.text.trim()
                    );
                    setDialogState(() => _isUpdatingPassword = false);
                    if (mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(success ? "Password Updated!" : "Update Failed"),
                          backgroundColor: success ? Colors.green : Colors.red,
                        )
                      );
                      _passwordController.clear();
                    }
                  },
                  child: _isUpdatingPassword 
                      ? const SizedBox(width: 15, height: 15, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text("Save"),
                )
              ],
            );
          }
        );
      }
    );
  }

  Widget _infoCard(String label, String value, IconData icon) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
      child: ListTile(
        leading: Icon(icon, color: Colors.blueAccent),
        title: Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        subtitle: Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.userData[0]['name'] ?? "Committee Member";
    final email = widget.userData[0]['email'] ?? "Not Provided";
    final id = widget.userData[0]['id'] ?? "No ID";

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text("Profile"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 50,
              backgroundColor: Colors.blueAccent,
              child: Icon(Icons.person, size: 50, color: Colors.white),
            ),
            const SizedBox(height: 16),
            Text(name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            Text(widget.userData[0]['role'] == "Committee" ? "Committee Member" : widget.userData[0]['role'], style: const TextStyle(color: Colors.grey, fontSize: 16)),
            const SizedBox(height: 24),
            
            _infoCard("Staff ID", id.toString(), Icons.badge_outlined),
            _infoCard("Email", email, Icons.email_outlined),
            
            const SizedBox(height: 24),
            
            // Switch to Supervisor View
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                onPressed: () => _viewModel.switchToSupervisor(context, widget.userData[0]),
                icon: const Icon(Icons.swap_horiz),
                label: const Text("Switch to Supervisor View", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
              ),
            ),
            
            const SizedBox(height: 12),
            
            SizedBox(
              width: double.infinity,
              height: 55,
              child: OutlinedButton.icon(
                onPressed: _showChangePasswordDialog,
                icon: const Icon(Icons.lock_reset),
                label: const Text("Change Password"),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.blueAccent),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
              ),
            ),
            
            const SizedBox(height: 40),
            
            TextButton.icon(
              onPressed: () => _viewModel.logout(context),
              icon: const Icon(Icons.logout, color: Colors.red),
              label: const Text("Logout Session", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
