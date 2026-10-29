import 'package:flutter/material.dart';

// --- VIEW MODEL ---
// PRIMARY SCHOOLER NOTE: This is the "Brain" for the Edit Meeting screen.
// We keep it in a separate file to keep our View clean and easy to read.
// Right now, updating and canceling are just "Mock" (fake) actions.
class EditMeetingViewModel {
  // A simple switch to turn the loading spinner on or off
  bool isLoading = false;

  /// WHAT IT DOES: Fakes sending the updated meeting to the server.
  Future<void> updateMeeting(Map<String, dynamic> data) async {
    isLoading = true;
    
    // Simulate a network delay (pretend we are waiting for the server)
    await Future.delayed(const Duration(seconds: 1));
    
    debugPrint("Mock Update -> $data");
    
    isLoading = false;
  }

  /// WHAT IT DOES: Fakes telling the server to cancel a meeting.
  Future<void> cancelMeeting(String meetingId) async {
    isLoading = true;
    
    // Simulate a network delay
    await Future.delayed(const Duration(seconds: 1));
    
    debugPrint("Mock Cancel -> Meeting ID: $meetingId");
    
    isLoading = false;
  }
}
