import 'package:flutter/material.dart';

import '../../models/note.dart';
import '../../state/notes_scope.dart';
import '../../theme/app_theme.dart';
import '../../widgets/responsive_center.dart';
import 'widgets/static_formatting_toolbar.dart';
import 'widgets/unsaved_changes_dialog.dart';

/// Frames 09/10/11 (New Note Editor / Editor with Content / Editor
/// Favorite) plus the merged save/discard dialog from frames 12/13 (see
/// `widgets/unsaved_changes_dialog.dart` for why those two frames became
/// one dialog).
///
/// `noteId == null` means "creating a new note"; otherwise this edits the
/// existing note with that id. If `noteId` doesn't resolve to a note (it
/// was deleted elsewhere, or is stale), this falls back to a fresh unsaved
/// note rather than erroring.
class EditorScreen extends StatefulWidget {
  const EditorScreen({super.key, this.noteId});

  final String? noteId;

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _bodyController;

  /// The note edits are based on: the loaded note for an existing id, or a
  /// freshly-minted empty [Note] otherwise. Its id/createdAt travel with
  /// every save; its title/body/isFavorite are the baseline unsaved
  /// changes are compared against.
  late Note _baseline;
  bool _isFavorite = false;

  /// Whether the design's "eye" icon is toggled. Nothing in the traced
  /// prototype defines what this icon does, so it's kept as a purely
  /// visual, unpersisted toggle rather than wired to any behavior.
  bool _previewToggled = false;

  bool _didInit = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _bodyController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInit) return;
    _didInit = true;
    final existing = widget.noteId == null
        ? null
        : NotesScope.of(context).byId(widget.noteId!);
    final note = existing ?? Note.create();
    _baseline = note;
    _titleController.text = note.title;
    _bodyController.text = note.body;
    _isFavorite = note.isFavorite;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  bool get _hasUnsavedChanges =>
      _titleController.text != _baseline.title ||
      _bodyController.text != _baseline.body ||
      _isFavorite != _baseline.isFavorite;

  Note _currentNote() => _baseline.copyWith(
    title: _titleController.text,
    body: _bodyController.text,
    isFavorite: _isFavorite,
    updatedAt: DateTime.now(),
  );

  /// Persists the current fields. Note that [NotesController.upsert] drops
  /// (deletes) the note instead of saving it if both title and body end up
  /// empty, so an empty note is never actually written to disk here.
  Future<void> _save() async {
    final note = _currentNote();
    await NotesScope.of(context).upsert(note);
    if (!mounted) return;
    setState(() => _baseline = note);
  }

  Future<void> _handleSavePressed() async {
    await _save();
    if (mounted) Navigator.of(context).pop();
  }

  void _toggleFavorite() {
    setState(() => _isFavorite = !_isFavorite);
  }

  /// Backing out of the editor: if there's nothing unsaved, just leave.
  /// Otherwise ask via the merged save/discard dialog and act on the
  /// answer.
  Future<void> _confirmAndPop() async {
    if (!_hasUnsavedChanges) {
      Navigator.of(context).pop();
      return;
    }
    final action = await showUnsavedChangesDialog(context);
    if (!mounted || action == null) return;
    if (action == UnsavedChangesAction.save) {
      await _save();
      if (!mounted) return;
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _confirmAndPop();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.maybePop(context),
          ),
          actions: [
            IconButton(
              // Unwired in the source design — see `_previewToggled` doc.
              icon: Icon(
                _previewToggled ? Icons.visibility : Icons.visibility_outlined,
              ),
              onPressed: () =>
                  setState(() => _previewToggled = !_previewToggled),
            ),
            IconButton(
              onPressed: _toggleFavorite,
              icon: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                transitionBuilder: (child, animation) =>
                    ScaleTransition(scale: animation, child: child),
                child: Icon(
                  _isFavorite ? Icons.star_rounded : Icons.star_border_rounded,
                  key: ValueKey(_isFavorite),
                  color: _isFavorite ? AppTheme.favoriteGold : Colors.white,
                ),
              ),
            ),
            IconButton(
              // The source design uses two different glyphs for "save"
              // across frames (an export/share-box icon in frame 09, a
              // disk icon in frames 10/11); unified here to one consistent
              // icon rather than replicating that inconsistency.
              icon: const Icon(Icons.save_outlined),
              onPressed: _handleSavePressed,
            ),
          ],
        ),
        body: SafeArea(
          top: false,
          bottom: false,
          child: ResponsiveCenter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _titleController,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    maxLines: null,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      hintText: 'Title',
                      hintStyle: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.white38,
                      ),
                      border: InputBorder.none,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: TextField(
                      controller: _bodyController,
                      style: const TextStyle(fontSize: 16, height: 1.4),
                      maxLines: null,
                      expands: true,
                      textAlignVertical: TextAlignVertical.top,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        hintText: 'Type something...',
                        hintStyle: TextStyle(color: Colors.white38),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        bottomNavigationBar: const SafeArea(
          top: false,
          child: StaticFormattingToolbar(),
        ),
      ),
    );
  }
}
