import 'package:flutter/material.dart';
import '../../viewmodels/queuehandlerviewmodel/queue_handler_profile_view_model.dart';

class QueueHandlerProfileView extends StatefulWidget {
  final Map<String, dynamic> userMap;
  const QueueHandlerProfileView({super.key, required this.userMap});

  @override
  State<QueueHandlerProfileView> createState() => _QueueHandlerProfileViewState();
}

class _QueueHandlerProfileViewState extends State<QueueHandlerProfileView> {
  final QueueHandlerProfileViewModel _viewModel = QueueHandlerProfileViewModel();
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
                      widget.userMap['id'].toString(),
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

  @override
  Widget build(BuildContext context) {
    final name = widget.userMap['name'] ?? "Staff";
    final id = widget.userMap['id'] ?? "No ID";

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text("Staff Profile"), elevation: 0),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 40,
              backgroundColor: Colors.blueGrey,
              child: Icon(Icons.person, size: 40, color: Colors.white),
            ),
            const SizedBox(height: 10),
            Text(name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text(widget.userMap['role'] ?? "Staff Member", style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 30),
            
            Card(
              child: ListTile(
                leading: const Icon(Icons.badge),
                title: const Text("Staff ID"),
                subtitle: Text(id.toString()),
              ),
            ),
            const SizedBox(height: 20),
            
            ElevatedButton.icon(
              onPressed: _showChangePasswordDialog,
              icon: const Icon(Icons.lock),
              label: const Text("Change Password"),
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () => _viewModel.logout(context),
              icon: const Icon(Icons.logout),
              label: const Text("Logout"),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                foregroundColor: Colors.red
              ),
            ),
          ],
        ),
      ),
    );
  }
}
