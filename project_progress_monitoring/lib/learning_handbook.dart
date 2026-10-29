/*
  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  📦 THE COMPONENT CODE LAB (Detailed Version)
  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  This file contains "Recipes" for every UI part in your project.
  You can copy these and change the colors or sizes!
  
  ----------------------------------------------------------------------------
  1. THE "MAGIC BOX" (Container with Shadow)
  ----------------------------------------------------------------------------
  Used in: Dashboard Cards, Meeting Cards.
  
  Container(
    padding: EdgeInsets.all(16),             // Space inside the box
    decoration: BoxDecoration(
      color: Colors.white,                   // Background color
      borderRadius: BorderRadius.circular(16),// Rounded corners
      boxShadow: [
        BoxShadow(
          color: Colors.black12,             // Subtle shadow
          blurRadius: 8,                     // How "fuzzy" the shadow is
          offset: Offset(0, 4),              // Shadow position (X, Y)
        )
      ],
    ),
    child: Text("I am a pretty box!"),
  )
  
  ----------------------------------------------------------------------------
  2. THE "SWITCHER" (FYP-1 / FYP-2 Tabs)
  ----------------------------------------------------------------------------
  Used in: View Meetings, Assign Task.
  
  Row(
    children: [
      // Button 1
      Expanded(
        child: GestureDetector(
          onTap: () { /* Change data to FYP-1 */ },
          child: Container(
            color: isActive ? Colors.blue : Colors.grey,
            child: Text("FYP-1"),
          ),
        ),
      ),
      // Button 2
      Expanded(
        child: GestureDetector(
          onTap: () { /* Change data to FYP-2 */ },
          child: Container(
            color: isActive ? Colors.blue : Colors.grey,
            child: Text("FYP-2"),
          ),
        ),
      ),
    ],
  )
  
  ----------------------------------------------------------------------------
  3. THE "SIFTER" (Filtered List Logic)
  ----------------------------------------------------------------------------
  Used in: View Meetings Search.
  
  // 1. Create a variable for the search text
  String _searchTerm = "";
  
  // 2. Filter the list
  List filtered = allItems.where((item) {
    // Check if the name contains what we typed
    return item['name'].toLowerCase().contains(_searchTerm.toLowerCase());
  }).toList();
  
  ----------------------------------------------------------------------------
  4. THE "PICKER" (Dropdown Menu)
  ----------------------------------------------------------------------------
  Used in: Assign Task (Selecting Groups).
  
  DropdownButtonFormField<String>(
    value: _selectedValue,
    items: ["Option A", "Option B"].map((val) {
      return DropdownMenuItem(value: val, child: Text(val));
    }).toList(),
    onChanged: (newVal) {
      setState(() { _selectedValue = newVal; });
    },
  )
  
  ----------------------------------------------------------------------------
  6. THE "GRID" (2x2 Dashboard Layout)
  ----------------------------------------------------------------------------
  Used in: Committee Dashboard, Student Dashboard.
  
  GridView.count(
    crossAxisCount: 2,           // 2 boxes per row
    crossAxisSpacing: 16,        // Space between side-by-side boxes
    mainAxisSpacing: 16,         // Space between top-and-bottom boxes
    shrinkWrap: true,            // Makes the grid only as big as it needs to be
    children: [
      Card1(), Card2(), Card3(), Card4()
    ],
  )
  
  ----------------------------------------------------------------------------
  7. THE "STAT CARD" (Number + Label)
  ----------------------------------------------------------------------------
  Used in: Student Dashboard stats.
  
  Container(
    child: Column(
      children: [
        Icon(Icons.event),       // The picture
        Text("12"),              // The big number
        Text("Total Tasks"),     // The label
      ],
    ),
  )
  
  ----------------------------------------------------------------------------
  8. THE "INVISIBLE BRICK" (SizedBox for Spacing)
  ----------------------------------------------------------------------------
  Used in: Everywhere!
  
  Column(
    children: [
      Text("Hello"),
      SizedBox(height: 20),      // This pushes the next text 20 pixels down
      Text("Goodbye"),
    ],
  )
  
  ----------------------------------------------------------------------------
  9. THE "PROFILE CIRCLE" (CircleAvatar)
  ----------------------------------------------------------------------------
  Used in: Profiles and Navigation Bars.
  
  CircleAvatar(
    radius: 30,                  // How big the circle is
    backgroundColor: Colors.blue,// The color inside the circle
    child: Text("TH"),           // Usually the user's initials
  )
  
  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
*/

import 'package:flutter/material.dart';

class ComponentLabView extends StatelessWidget {
  const ComponentLabView({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Component Lab")),
      body: const Center(child: Text("Read the 'Recipes' in the comments above!")),
    );
  }
}
