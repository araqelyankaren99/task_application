import 'package:flutter/material.dart';

import '../../routes.dart';
import '../../state/notes_scope.dart';
import '../../theme/app_theme.dart';
import '../../widgets/responsive_center.dart';
import 'widgets/empty_state.dart';
import 'widgets/favorites_filter.dart';
import 'widgets/swipeable_note_card.dart';

/// Frames 01/02/03/04/06 (Home Empty / Home Notes List / Swipe to Delete /
/// Swipe to Favorite / Filter View).
///
/// Frame 05 — a sectioned list — was the alternate design NOT built here.
/// The two-segment "All / Favorite" filter from frame 06 was chosen
/// instead: it scales better as the note count grows, and it reuses the
/// exact same `visibleNotes` rendering path that search already uses,
/// rather than introducing a second grouping concept.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  // Approximate violet/purple accent for the FAB — not sampled from
  // Figma (view-only, no Dev Mode), picked to read clearly on the dark
  // background.
  static const _fabColor = Color(0xFF7C6FF0);

  @override
  Widget build(BuildContext context) {
    final controller = NotesScope.of(context);
    return Scaffold(
      body: SafeArea(
        child: ListenableBuilder(
          listenable: controller,
          builder: (context, _) {
            final notes = controller.visibleNotes;
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                  child: ResponsiveCenter(child: const _HomeHeader()),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                  child: ResponsiveCenter(
                    child: FavoritesFilter(
                      favoritesOnly: controller.favoritesOnly,
                      onChanged: controller.setFavoritesOnly,
                    ),
                  ),
                ),
                Expanded(
                  child: controller.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : notes.isEmpty
                      ? EmptyState(favoritesOnly: controller.favoritesOnly)
                      : ResponsiveCenter(
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
                            itemCount: notes.length,
                            itemBuilder: (context, index) {
                              final note = notes[index];
                              return SwipeableNoteCard(
                                key: ValueKey(note.id),
                                note: note,
                                onTap: () => Navigator.of(
                                  context,
                                ).push(AppRoutes.reading(noteId: note.id)),
                                onDelete: () => controller.delete(note.id),
                                onFavorite: () =>
                                    controller.toggleFavorite(note.id),
                              );
                            },
                          ),
                        ),
                ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: _fabColor,
        foregroundColor: Colors.white,
        shape: const CircleBorder(),
        onPressed: () =>
            Navigator.of(context).push(AppRoutes.editor(noteId: null)),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Flexible(
          child: Text(
            'Notes',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
        const Spacer(),
        _CircleIconButton(
          icon: Icons.search,
          tooltip: 'Search',
          onTap: () => Navigator.of(context).push(AppRoutes.search()),
        ),
        const SizedBox(width: 10),
        _CircleIconButton(
          icon: Icons.info_outline,
          tooltip: 'About',
          onTap: () => _showAboutDialog(context),
        ),
      ],
    );
  }

  // The info icon's destination isn't defined anywhere in the two
  // prototype flows traced from Figma, so as a reasonable stand-in it
  // just opens a minimal AlertDialog with the app name/description.
  void _showAboutDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notes'),
        content: const Text(
          'A simple, offline notes app. Create, favorite, and search your '
          'notes — everything stays on this device.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({
    required this.icon,
    required this.onTap,
    required this.tooltip,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.surfaceHigh,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Tooltip(
            message: tooltip,
            child: Icon(icon, size: 22, color: Colors.white),
          ),
        ),
      ),
    );
  }
}
