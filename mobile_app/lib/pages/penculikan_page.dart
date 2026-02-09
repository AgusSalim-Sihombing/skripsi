import 'package:flutter/material.dart';

class PenculikanPage extends StatelessWidget {
  const PenculikanPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Penculikan"),
        backgroundColor: Colors.red,
      ),
      body: Text("Penculikan"),
    );
  }
}