import 'package:flutter/foundation.dart';

import '../data/notes_repository.dart';
import '../models/note.dart';

/// Single source of truth for the note list. Screens read from this via
/// [ListenableBuilder]/[AnimatedBuilder] and call its mutating methods —
/// nothing in `screens/` touches [NotesRepository] directly.
///
/// Every mutation writes through to disk before `notifyListeners()` fires,
/// so by the time the UI shows a change, that change is already durable.
class NotesController extends ChangeNotifier {
  NotesController(this._repository);

  final NotesRepository _repository;

  List<Note> _notes = [];
  bool _isLoading = true;
  bool _hasLoadError = false;
  String _searchQuery = '';
  bool _favoritesOnly = false;

  bool get isLoading => _isLoading;

  /// True if the initial [load] threw and the note list could not be
  /// read — distinct from [isLoading]: a screen should show a retry
  /// affordance for this, not spin forever. See [load].
  bool get hasLoadError => _hasLoadError;
  String get searchQuery => _searchQuery;
  bool get favoritesOnly => _favoritesOnly;

  /// All notes, unsorted, unfiltered. Rarely what a screen wants directly.
  List<Note> get allNotes => List.unmodifiable(_notes);

  /// Notes for the home list: favorites-filtered (frame 06) and newest
  /// edited first.
  List<Note> get visibleNotes {
    final base = _favoritesOnly ? _notes.where((n) => n.isFavorite) : _notes;
    final list = base.toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return list;
  }

  /// Notes matching [searchQuery] against title or body, case-insensitive.
  /// Empty query returns an empty list — the search screen shouldn't show
  /// the whole list before the user has typed anything.
  List<Note> get searchResults {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) return const [];
    final list = _notes.where((n) {
      return n.title.toLowerCase().contains(query) ||
          n.body.toLowerCase().contains(query);
    }).toList()..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return list;
  }

  Note? byId(String id) {
    for (final note in _notes) {
      if (note.id == id) return note;
    }
    return null;
  }

  /// Loads the note list from the repository. Safe to call again (e.g.
  /// from a "Retry" button) after a failed attempt — resets
  /// [hasLoadError] and tries again rather than staying stuck.
  ///
  /// Previously this let a repository failure propagate uncaught: since
  /// `main.dart` calls this fire-and-forget from `initState`, an
  /// unhandled exception here meant `_isLoading` never flipped to
  /// `false` and the home screen's spinner hung forever with no error
  /// shown. Catching it and exposing [hasLoadError] turns that into a
  /// real, visible, recoverable state instead.
  Future<void> load() async {
    _isLoading = true;
    _hasLoadError = false;
    notifyListeners();
    try {
      _notes = await _repository.load();
      _hasLoadError = false;
    } catch (_) {
      _hasLoadError = true;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setFavoritesOnly(bool value) {
    _favoritesOnly = value;
    notifyListeners();
  }

  /// Inserts a new note or replaces an existing one with the same id.
  /// A note whose title and body are both empty is dropped instead of
  /// saved — an empty note is not a note.
  Future<void> upsert(Note note) async {
    if (note.isEmpty) {
      await delete(note.id);
      return;
    }
    final index = _notes.indexWhere((n) => n.id == note.id);
    if (index == -1) {
      _notes = [..._notes, note];
    } else {
      _notes = [..._notes]..[index] = note;
    }
    await _repository.save(_notes);
    notifyListeners();
  }

  Future<void> delete(String id) async {
    final existed = _notes.any((n) => n.id == id);
    if (!existed) return;
    _notes = _notes.where((n) => n.id != id).toList();
    await _repository.save(_notes);
    notifyListeners();
  }

  Future<void> toggleFavorite(String id) async {
    final note = byId(id);
    if (note == null) return;
    await upsert(note.copyWith(isFavorite: !note.isFavorite));
  }
}
