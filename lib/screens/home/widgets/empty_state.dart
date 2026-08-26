import 'package:flutter/material.dart';

/// Frame 01. The Figma file is view-only (no exported illustration asset),
/// so this uses a large muted icon instead of trying to recreate the
/// design's illustration pixel-for-pixel.
///
/// Shown both when there are no notes at all and when the "Favorite"
/// filter (frame 06) has nothing to show — those are two different
/// situations, so they get distinct copy.
class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.favoritesOnly});

  /// Whether the "Favorite" segment is currently selected. When true, an
  /// empty list means "no favorites yet", not "no notes at all".
  final bool favoritesOnly;

  @override
  Widget build(BuildContext context) {
    final icon = favoritesOnly
        ? Icons.star_outline_rounded
        : Icons.note_add_outlined;
    final message = favoritesOnly
        ? 'No favorite notes yet'
        // The design's copy was "Create your first note !" (note the
        // stray space before the "!") — normalized here to standard
        // punctuation; this is intentional, not a typo carried over.
        : 'Create your first note!';

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 88, color: Colors.white24),
            const SizedBox(height: 16),
            Flexible(
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w500,
                  color: Colors.white54,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
