import 'package:flutter/material.dart';

class PencurianPage extends StatelessWidget {
  const PencurianPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Pencurian"),
        backgroundColor: Colors.blue,
      ),
      body: Text("Pencurian"),
    );
  }
}