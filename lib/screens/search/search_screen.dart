import 'package:flutter/material.dart';

import '../../routes.dart';
import '../../state/notes_scope.dart';
import '../../theme/app_theme.dart';
import '../../widgets/note_card.dart';
import '../../widgets/responsive_center.dart';
import 'widgets/no_results.dart';

/// Frames 07/08 (Search / Search No Results).
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Auto-focus the search field as soon as this screen is on screen,
    // so the user can start typing immediately without an extra tap.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    NotesScope.of(context).setSearchQuery(value);
  }

  void _onClear() {
    _textController.clear();
    NotesScope.of(context).setSearchQuery('');
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final controller = NotesScope.of(context);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        titleSpacing: 4,
        toolbarHeight: 68,
        title: Container(
          height: 44,
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: _textController,
            focusNode: _focusNode,
            onChanged: _onChanged,
            style: const TextStyle(color: Colors.white, fontSize: 16),
            cursorColor: Colors.white,
            decoration: InputDecoration(
              isDense: true,
              hintText: 'Search by title or word',
              hintStyle: const TextStyle(color: Colors.white54),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              suffixIcon: ValueListenableBuilder<TextEditingValue>(
                valueListenable: _textController,
                builder: (context, value, _) {
                  if (value.text.isEmpty) return const SizedBox.shrink();
                  return IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Colors.white54,
                      size: 20,
                    ),
                    tooltip: 'Clear search',
                    onPressed: _onClear,
                  );
                },
              ),
            ),
          ),
        ),
      ),
      body: ResponsiveCenter(
        child: ListenableBuilder(
          listenable: controller,
          builder: (context, _) {
            final hasQuery = controller.searchQuery.trim().isNotEmpty;
            final results = controller.searchResults;

            final Widget content;
            if (!hasQuery) {
              // Nothing typed yet — distinct from "typed but no matches"
              // (frame 08). Not a transcription of a specific Figma
              // frame, just a neutral placeholder for this state.
              content = const _SearchPrompt(key: ValueKey('prompt'));
            } else if (results.isEmpty) {
              content = const NoResults(key: ValueKey('no-results'));
            } else {
              content = ListView.separated(
                key: const ValueKey('results'),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                itemCount: results.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final note = results[index];
                  return NoteCard(
                    note: note,
                    onTap: () {
                      Navigator.of(
                        context,
                      ).push(AppRoutes.reading(noteId: note.id));
                    },
                  );
                },
              );
            }

            return AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: content,
            );
          },
        ),
      ),
    );
  }
}

class _SearchPrompt extends StatelessWidget {
  const _SearchPrompt({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_rounded, size: 56, color: Colors.white38),
            SizedBox(height: 16),
            Text(
              'Start typing to search your notes',
              style: TextStyle(color: Colors.white54, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
