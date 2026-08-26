import 'package:flutter/material.dart';

/// Frames 09/10/11 (New Note Editor / Editor with Content / Editor
/// Favorite) plus the save/discard dialogs from frames 12/13.
///
/// `noteId == null` means "creating a new note"; otherwise this edits the
/// existing note with that id.
class EditorScreen extends StatelessWidget {
  const EditorScreen({super.key, this.noteId});

  final String? noteId;

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('Editor — TODO')));
  }
}
