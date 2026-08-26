import 'package:flutter/material.dart';

/// Frame 14 (Reading Note) — the read-only view a note opens into.
class ReadingScreen extends StatelessWidget {
  const ReadingScreen({super.key, required this.noteId});

  final String noteId;

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('Reading — TODO')));
  }
}
