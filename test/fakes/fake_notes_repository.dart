import 'package:task_application/data/notes_repository.dart';
import 'package:task_application/models/note.dart';

/// In-memory [NotesRepository] for widget tests — no filesystem, no
/// `path_provider` plugin channel to mock.
class FakeNotesRepository implements NotesRepository {
  FakeNotesRepository([List<Note> seed = const []]) : _notes = List.of(seed);

  List<Note> _notes;

  /// When true, [load] throws instead of returning — for exercising
  /// NotesController's error/retry path.
  bool failNextLoad = false;

  @override
  Future<List<Note>> load() async {
    if (failNextLoad) {
      throw const FileSystemFailure('simulated load failure');
    }
    return List.of(_notes);
  }

  @override
  Future<void> save(List<Note> notes) async {
    _notes = List.of(notes);
  }
}

/// Stand-in for the kind of platform/IO exception a real
/// `path_provider`/`dart:io` failure would throw — deliberately not a
/// [FormatException], so tests exercise the broad `catch` in
/// NotesController.load rather than a JSON-specific one.
class FileSystemFailure implements Exception {
  const FileSystemFailure(this.message);
  final String message;
  @override
  String toString() => 'FileSystemFailure: $message';
}
