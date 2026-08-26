import 'package:task_application/data/notes_repository.dart';
import 'package:task_application/models/note.dart';

/// In-memory [NotesRepository] for widget tests — no filesystem, no
/// `path_provider` plugin channel to mock.
class FakeNotesRepository implements NotesRepository {
  FakeNotesRepository([List<Note> seed = const []]) : _notes = List.of(seed);

  List<Note> _notes;

  @override
  Future<List<Note>> load() async => List.of(_notes);

  @override
  Future<void> save(List<Note> notes) async {
    _notes = List.of(notes);
  }
}
