import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';

/// The two-segment "All / Favorite" control from frame 06 — the filter
/// approach chosen over frame 05's sectioned list (see home_screen.dart
/// for why). Selecting "Favorite" flips [NotesController.favoritesOnly],
/// and the list underneath just renders `visibleNotes`, which already
/// respects that flag.
class FavoritesFilter extends StatelessWidget {
  const FavoritesFilter({
    super.key,
    required this.favoritesOnly,
    required this.onChanged,
  });

  final bool favoritesOnly;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: SegmentedButton<bool>(
        segments: const [
          ButtonSegment(value: false, label: Text('All')),
          ButtonSegment(value: true, label: Text('Favorite')),
        ],
        selected: {favoritesOnly},
        showSelectedIcon: false,
        onSelectionChanged: (selection) => onChanged(selection.first),
        style: SegmentedButton.styleFrom(
          backgroundColor: AppTheme.surface,
          foregroundColor: Colors.white70,
          selectedBackgroundColor: AppTheme.surfaceHigh,
          selectedForegroundColor: Colors.white,
          side: const BorderSide(color: AppTheme.surfaceHigh),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
