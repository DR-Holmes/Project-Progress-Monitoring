import 'package:flutter/material.dart';

// Importing all the screens we might navigate to after logging in.
import 'package:project_progress_monitoring/view/studentui/group_options_view.dart';
import 'package:project_progress_monitoring/view/studentui/lobby_view.dart';
import 'package:project_progress_monitoring/view/studentui/student_dashboard_view.dart';
import 'package:project_progress_monitoring/view/studentui/technologyselectiononetime.dart';
import 'package:project_progress_monitoring/view/supervisorui/supervisor_dashboard_view.dart';
import 'comitteeheadui/committee_head_dashboard_view.dart';
import '../viewmodels/login_view_model.dart';
import 'comitteeui/comittee_dashboard_view.dart';
import 'queuehandlerui/queuehandler_dashboard_view.dart';
import 'datacellui/datacell_dashboard_view.dart';


// This is the View for the Login screen.
// It's a StatefulWidget because the UI needs to update (like showing a loading spinner).
class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
} // End of LoginView class

// This is the State class for LoginView. All the changing logic and UI lives here.
class _LoginViewState extends State<LoginView> {
  // 1. Initialize the ViewModel
  // The ViewModel contains all the database/API logic. We separate it from the UI (VVM Architecture).
  final LoginViewModel _viewModel = LoginViewModel();

  // 2. Controllers for TextFields
  // These objects read the text that the user types into the input boxes.
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // 3. Loading State Variable
  // When this is true, we show a loading spinner instead of the login button.
  bool _isLoading = false;

  // 4. The Login Function
  // This is triggered when the user taps the Login button.
  void _handleLogin() async {
    // Tell Flutter to update the UI and show the loading spinner
    setState(() => _isLoading = true);

    // Read the text from the controllers and remove extra spaces (.trim())
    String id = _idController.text.trim();
    String password = _passwordController.text.trim();

    // Validation: Check if the fields are empty
    if (id.isEmpty || password.isEmpty) {
      // Show a temporary pop-up message (SnackBar) at the bottom
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter ID and Password")),
      );
      // Turn off the loading spinner
      setState(() => _isLoading = false);
      // Stop the function here so it doesn't try to log in
      return;
    } // End of validation if

    // Ask the ViewModel to perform the actual login logic
    // We wait (await) for it to finish and give us a map containing the results
    Map<String, dynamic> result = await _viewModel.login(id, password);

    // Turn off the loading spinner once we get the result
    setState(() => _isLoading = false);

    // Check if the ViewModel returned an error message
    if (result.containsKey('error')) {
      // If the widget is still on screen (mounted), show the error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['error'])),
        );
      } // End of mounted check
    } else {
      // Success! The ViewModel tells us which screen to go to next via the 'route' key.
      String route = result['route'];
      debugPrint("Navigating to: $route with data: $result");

      // Double-check if the widget is still on screen before navigating
      if (!mounted) return;



      // Navigate to the correct screen based on the route.
      // We use pushReplacement so the user can't press "Back" to return to the login screen.
      switch (route) {
        case 'SelectTech':
        case 'TechnologySelection':
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => TechnologySelectionView(userData: [result])));
          break;
        case 'GroupOptions':
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => GroupOptionsView(userData: [result])));
          break;
        case 'Lobby':
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => LobbyView(userData: [result])));
          break;
        case 'StudentDashboard':
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => StudentDashboardView(userData: [result])));
          break;
        case 'CommitteeDashboard':
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => CommitteeDashboardView(userData: [result])));
          break;
        case 'CommitteeHeadDashboard':
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => CommitteeHeadDashboardView(userData: [result])));
          break;
        case 'SupervisorDashboard':
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => SupervisorDashboardView(userData: [result])));
          break;
        case 'QueueHandlerDashboard':
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => QueueHandlerDashboardView(userData: [result])));
          break;
        case 'DataCellDashboard':
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => DatacellDashboardView(userData: [result])));
          break;
        default:
          // If we don't recognize the route, show an error
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Unknown Role or Route: $route")),
          );
      } // End of switch
    } // End of error check else
  } // End of _handleLogin method

  // 5. The Build Method
  // This is where we create the actual visual layout of the screen.
  @override
  Widget build(BuildContext context) {
    // Scaffold provides the basic page structure (AppBar, Body)
    return Scaffold(
      appBar: AppBar(title: const Text("Progress Monitoring Login")),
      
      // Body of the screen, with padding around the edges
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        
        // Column stacks widgets vertically
        child: Column(
          // Centers the items vertically in the middle of the screen
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            
            // --- User ID Field ---
            TextField(
              controller: _idController, // Connects to our controller above
              decoration: const InputDecoration(
                labelText: "Registration Number / ID",
                border: OutlineInputBorder(), // Draws a box around the field
                prefixIcon: Icon(Icons.person), // Adds an icon inside the box
              ),
            ), // End of ID TextField
            
            const SizedBox(height: 20), // Adds 20 pixels of empty space
            
            // --- Password Field ---
            TextField(
              controller: _passwordController,
              obscureText: true, // Hides the text with dots (for passwords)
              decoration: const InputDecoration(
                labelText: "Password",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock),
              ),
            ), // End of Password TextField
            
            const SizedBox(height: 30), // Adds 30 pixels of empty space
            
            // --- Login Button / Loading Indicator ---
            // If _isLoading is true, show the spinner. Otherwise, show the button.
            _isLoading
                ? const CircularProgressIndicator()
                : SizedBox(
                    width: double.infinity, // Makes the button stretch full width
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _handleLogin, // Calls our login function when pressed
                      child: const Text("Login", style: TextStyle(fontSize: 18)),
                    ), // End of ElevatedButton
                  ), // End of SizedBox
            
            const SizedBox(height: 10), // Spacing
            
            // --- Forgot Password Button ---
            TextButton(
              onPressed: () {
                // Add your forgot password logic here later
                debugPrint("Forgot Password clicked");
              },
              child: const Text(
                "Forgot Password?",
                style: TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.w500,
                ),
              ), // End of Text
            ), // End of TextButton
            
          ], // End of Column children
        ), // End of Column
      ), // End of Padding
    ); // End of Scaffold
  } // End of build method
} // End of _LoginViewState class