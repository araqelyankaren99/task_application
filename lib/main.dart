import 'package:flutter/material.dart';

import 'data/notes_repository.dart';
import 'screens/home/home_screen.dart';
import 'state/notes_controller.dart';
import 'state/notes_scope.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(NotesApp(controller: NotesController(JsonFileNotesRepository())));
}

class NotesApp extends StatefulWidget {
  const NotesApp({super.key, required this.controller});

  final NotesController controller;

  @override
  State<NotesApp> createState() => _NotesAppState();
}

class _NotesAppState extends State<NotesApp> {
  @override
  void initState() {
    super.initState();
    widget.controller.load();
  }

  @override
  Widget build(BuildContext context) {
    return NotesScope(
      controller: widget.controller,
      child: MaterialApp(
        title: 'Notes',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.theme,
        home: const HomeScreen(),
      ),
    );
  }
}
