import 'package:flutter/material.dart';

/// Frames 01/02/03/04/06 (Home Empty / Home Notes List / Swipe to Delete /
/// Swipe to Favorite / Filter View).
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('Home — TODO')));
  }
}
