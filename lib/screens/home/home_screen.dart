import 'package:flutter/material.dart';

import '../../models/note.dart';
import '../../routes.dart';
import '../../state/notes_controller.dart';
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
                      : controller.hasLoadError
                      ? _LoadErrorState(onRetry: controller.load)
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
                                onDelete: () =>
                                    _deleteWithUndo(context, controller, note),
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

/// Deletes [note] and shows an "Undo" snackbar — the design has no
/// recovery affordance anywhere for an accidental swipe-delete (frames
/// 01-14 show no confirmation, no snackbar, nothing), which is a real gap
/// for an app that otherwise cares about not losing data. [note] is
/// captured by value (it's an immutable model) before the delete, so
/// "Undo" just re-`upsert`s the exact note that was removed — same id,
/// same content, same favorite state — rather than trying to reconstruct
/// it from anything.
void _deleteWithUndo(
  BuildContext context,
  NotesController controller,
  Note note,
) {
  controller.delete(note.id);
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: const Text('Note deleted'),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () => controller.upsert(note),
        ),
      ),
    );
}

/// Shown when [NotesController.load] fails — previously this state didn't
/// exist at all, and a load failure just left [NotesController.isLoading]
/// stuck `true` forever with the spinner spinning and no way out. See
/// [NotesController.load]'s doc comment for the full story.
class _LoadErrorState extends StatelessWidget {
  const _LoadErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 56,
              color: Colors.white38,
            ),
            const SizedBox(height: 16),
            const Text(
              "Couldn't load your notes",
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Something went wrong reading your notes from storage.',
              style: TextStyle(color: Colors.white54, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
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
