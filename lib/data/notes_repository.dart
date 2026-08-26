import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../models/note.dart';

/// Persists notes locally. The only implementation is a flat JSON file,
/// but callers depend on this interface so tests can swap in a fake.
abstract class NotesRepository {
  Future<List<Note>> load();
  Future<void> save(List<Note> notes);
}

/// Stores every note as a single JSON array in one file in the app's
/// documents directory.
///
/// Writes are atomic: we write the new content to a sibling temp file and
/// then rename it over the real file. `rename` on both Android and iOS
/// filesystems is a single directory-entry swap, so a process kill (or a
/// crash) either leaves the old file untouched or already-replaced by the
/// new one — never a half-written file. That is what "nothing lost when
/// the process is killed" means here: the last *completed* save always
/// survives, even if the save that was in flight at the moment of the
/// kill does not.
class JsonFileNotesRepository implements NotesRepository {
  JsonFileNotesRepository({this.fileName = 'notes.json'});

  final String fileName;
  File? _cachedFile;

  Future<File> _file() async {
    final cached = _cachedFile;
    if (cached != null) return cached;
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$fileName');
    _cachedFile = file;
    return file;
  }

  @override
  Future<List<Note>> load() async {
    final file = await _file();
    if (!await file.exists()) return [];
    final raw = await file.readAsString();
    if (raw.trim().isEmpty) return [];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded.cast<Map<String, dynamic>>().map(Note.fromJson).toList();
    } on FormatException {
      // Corrupt file (should not happen given atomic writes, but a note
      // app should never crash on launch because of it) — start empty
      // rather than lose the ability to open the app.
      return [];
    }
  }

  @override
  Future<void> save(List<Note> notes) async {
    final file = await _file();
    final tmp = File('${file.path}.tmp');
    final encoded = jsonEncode(notes.map((n) => n.toJson()).toList());
    await tmp.writeAsString(encoded, flush: true);
    await tmp.rename(file.path);
  }
}
