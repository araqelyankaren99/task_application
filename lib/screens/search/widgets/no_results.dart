import 'package:flutter/material.dart';

/// Frame 08 (Search No Results) — shown once the user has typed something
/// but nothing in title or body matches.
///
/// The Figma file is view-only (no Dev Mode), and the copy on this frame
/// was too small to read at the zoom level available without redlines,
/// so the message below is our own reasonable placeholder, not a
/// transcription of the source frame.
class NoResults extends StatelessWidget {
  const NoResults({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.search_off_rounded,
              size: 56,
              color: Colors.white38,
            ),
            const SizedBox(height: 16),
            Text(
              'No notes found',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Try a different title or word.',
              style: TextStyle(color: Colors.white54, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
