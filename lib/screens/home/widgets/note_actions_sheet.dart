import 'package:flutter/material.dart';

import '../../../models/note.dart';
import '../../../theme/app_theme.dart';

/// Long-press action menu for a note card — the non-gesture fallback for
/// delete/favorite. Both of those otherwise only work via a horizontal
/// swipe on [SwipeableNoteCard], which has no fallback for a user who
/// can't perform (or reliably trigger) that gesture — a screen-reader or
/// switch-control user in particular. Every action a swipe reaches is
/// reachable through here too, via a long-press instead.
Future<void> showNoteActionsSheet(
  BuildContext context, {
  required Note note,
  required VoidCallback onOpen,
  required VoidCallback onToggleFavorite,
  required VoidCallback onDelete,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppTheme.surfaceHigh,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.open_in_new_rounded),
              title: const Text('Open'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                onOpen();
              },
            ),
            ListTile(
              leading: Icon(
                note.isFavorite
                    ? Icons.star_rounded
                    : Icons.star_border_rounded,
                color: note.isFavorite ? AppTheme.favoriteGold : null,
              ),
              title: Text(
                note.isFavorite ? 'Remove from favorites' : 'Add to favorites',
              ),
              onTap: () {
                Navigator.of(sheetContext).pop();
                onToggleFavorite();
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.delete_outline_rounded,
                color: AppTheme.destructive,
              ),
              title: const Text(
                'Delete',
                style: TextStyle(color: AppTheme.destructive),
              ),
              onTap: () {
                Navigator.of(sheetContext).pop();
                onDelete();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      );
    },
  );
}
