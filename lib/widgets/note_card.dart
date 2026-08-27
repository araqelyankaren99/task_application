import 'package:flutter/material.dart';

import '../models/note.dart';
import '../theme/note_colors.dart';

/// The colored card used everywhere a note is shown as a list item (home
/// list, search results). Only the title is shown — the design never
/// shows a body preview on a card, just the title on a flat color.
///
/// Deliberately dumb: it knows nothing about swiping, deleting or
/// favoriting. `home_screen.dart` wraps this in its own gesture layer for
/// swipe-to-delete / swipe-to-favorite; this widget only renders + taps
/// (+ optionally long-presses — see [onLongPress]).
class NoteCard extends StatelessWidget {
  const NoteCard({
    super.key,
    required this.note,
    required this.onTap,
    this.onLongPress,
  });

  final Note note;
  final VoidCallback onTap;

  /// Optional long-press handler. `SwipeableNoteCard` (home screen) uses
  /// this to open a non-gesture action menu — the horizontal swipe is the
  /// only way to delete/favorite a note otherwise, which has no fallback
  /// for a screen-reader or switch-control user. Search results pass
  /// nothing here; a plain tap-only card is fine there.
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final title = note.title.trim().isEmpty ? 'Untitled' : note.title;
    return Material(
      color: colorForNote(note.id),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: kNoteCardForeground,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (note.isFavorite) ...[
                const SizedBox(width: 8),
                const Icon(
                  Icons.star_rounded,
                  color: kNoteCardForeground,
                  size: 20,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
