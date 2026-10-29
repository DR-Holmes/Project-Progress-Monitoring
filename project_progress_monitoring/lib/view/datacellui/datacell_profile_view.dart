import 'package:flutter/material.dart';
import '../queuehandlerui/queue_handler_profile_view.dart';

class DatacellProfileView extends StatelessWidget {
  final Map<String, dynamic> userMap;
  const DatacellProfileView({super.key, required this.userMap});

  @override
  Widget build(BuildContext context) {
    // Reusing the same simple style as Queue Handler as suggested by user
    return QueueHandlerProfileView(userMap: userMap);
  }
}
