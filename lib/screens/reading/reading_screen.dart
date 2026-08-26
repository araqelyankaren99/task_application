import 'package:flutter/material.dart';

import '../../routes.dart';
import '../../state/notes_scope.dart';
import '../../widgets/responsive_center.dart';

/// Frame 14 (Reading Note) — the read-only view a note opens into when
/// tapped from the home list or search results.
class ReadingScreen extends StatelessWidget {
  const ReadingScreen({super.key, required this.noteId});

  final String noteId;

  @override
  Widget build(BuildContext context) {
    final controller = NotesScope.of(context);
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final note = controller.byId(noteId);
        if (note == null) {
          return Scaffold(
            appBar: AppBar(),
            body: ResponsiveCenter(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'This note was deleted',
                        style: Theme.of(context).textTheme.titleMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Go back'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                tooltip: 'Edit note',
                onPressed: () {
                  Navigator.of(context).push(AppRoutes.editor(noteId: note.id));
                },
              ),
            ],
          ),
          body: ResponsiveCenter(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    note.title,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Figma frame 14 shows some words in the body italicized
                  // (e.g. "basics of design", "flawlessly"); notes are
                  // plain strings with no rich-text/markdown model in this
                  // app, so that styling is intentionally not replicated —
                  // rendered here as plain, unstyled text.
                  Text(
                    note.body,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.normal,
                      color: Colors.white70,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
