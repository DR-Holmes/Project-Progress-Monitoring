import 'package:flutter/material.dart';

class GradesView extends StatefulWidget {
  const GradesView({super.key});

  @override
  State<GradesView> createState() => _GradesViewState();
}

class _GradesViewState extends State<GradesView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text("Supervisor grades")),
      body: Padding(padding: EdgeInsets.all(15),
      child: Column(
          children: [
          // ListView.builder(itemBuilder: itemBuilder)
        ],
      ),),
    );
  }
}
