import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';

/// What the user chose in [showUnsavedChangesDialog].
enum UnsavedChangesAction { save, discard }

/// Frames 12 ("Save Dialog") and 13 ("Discard Dialog") are, in the source
/// Figma file, two barely-distinguishable dialogs for the same situation —
/// leaving the editor with unsaved changes — with inconsistent copy and
/// inconsistent button semantics:
///   * frame 12: "Save changes ?"                              Discard (red) / Save (green)
///   * frame 13: "Are your sure you want discard your changes?" Discard (red) / Keep (green)
/// (frame 13's copy has a typo in the source design — missing "to", wrong
/// pronoun.) Rather than replicate that contradiction as two dialogs, this
/// merges them into a single one, using frame 12's cleaner title/button
/// semantics: red "Discard" pops without saving, green "Save" persists the
/// note then pops.
///
/// Returns the action the user picked, or `null` if they dismissed the
/// dialog (e.g. tapped outside it) without choosing either.
Future<UnsavedChangesAction?> showUnsavedChangesDialog(BuildContext context) {
  return showDialog<UnsavedChangesAction>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text('Save changes?'),
        content: const Text(
          'You have unsaved changes to this note. '
          'You can save them or discard them.',
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppTheme.destructive),
            onPressed: () =>
                Navigator.of(dialogContext).pop(UnsavedChangesAction.discard),
            child: const Text('Discard'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppTheme.affirmative),
            onPressed: () =>
                Navigator.of(dialogContext).pop(UnsavedChangesAction.save),
            child: const Text('Save'),
          ),
        ],
      );
    },
  );
}
