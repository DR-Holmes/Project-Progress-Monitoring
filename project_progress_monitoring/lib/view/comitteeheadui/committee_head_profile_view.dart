import 'package:flutter/material.dart';
import '../../viewmodels/comitteeheadviewmodel/committee_head_profile_view_model.dart';

class CommitteeHeadProfileView extends StatefulWidget {
  final List<Map<String, dynamic>> userData;
  const CommitteeHeadProfileView({super.key, required this.userData});

  @override
  State<CommitteeHeadProfileView> createState() => _CommitteeHeadProfileViewState();
}

class _CommitteeHeadProfileViewState extends State<CommitteeHeadProfileView> {
  final CommitteeHeadProfileViewModel _viewModel = CommitteeHeadProfileViewModel();
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

  Widget _infoTile(IconData icon, String label, String value) {
    return ListTile(
      leading: Icon(icon, color: Colors.deepPurple),
      title: Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      subtitle: Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.userData[0]['name'] ?? "Head";
    final id = widget.userData[0]['id'] ?? "No ID";

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Committee Head Profile"),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 50,
              backgroundColor: Colors.deepPurple,
              child: Icon(Icons.account_balance, size: 50, color: Colors.white),
            ),
            const SizedBox(height: 20),
            Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
            const Text("Head of Committee", style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 30),
            
            _infoTile(Icons.assignment_ind, "Staff ID", id.toString()),
            _infoTile(Icons.verified_user, "Role", "Committee Head"),
            
            const SizedBox(height: 40),
            
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: _showChangePasswordDialog,
                icon: const Icon(Icons.vpn_key),
                label: const Text("Update Password"),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.deepPurple),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () => _viewModel.logout(context),
                icon: const Icon(Icons.logout),
                label: const Text("Sign Out"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
