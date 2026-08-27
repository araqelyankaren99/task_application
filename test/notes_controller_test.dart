import 'package:flutter_test/flutter_test.dart';
import 'package:task_application/models/note.dart';
import 'package:task_application/state/notes_controller.dart';

import 'fakes/fake_notes_repository.dart';

Note _note({
  required String id,
  String title = 'Title',
  String body = 'Body',
  bool isFavorite = false,
  DateTime? updatedAt,
}) {
  final at = updatedAt ?? DateTime(2026, 1, 1);
  return Note(
    id: id,
    title: title,
    body: body,
    isFavorite: isFavorite,
    createdAt: at,
    updatedAt: at,
  );
}

void main() {
  group('NotesController', () {
    test('load populates notes from the repository', () async {
      final repo = FakeNotesRepository([_note(id: '1', title: 'Existing')]);
      final controller = NotesController(repo);

      expect(controller.isLoading, isTrue);
      await controller.load();

      expect(controller.isLoading, isFalse);
      expect(controller.hasLoadError, isFalse);
      expect(controller.allNotes, hasLength(1));
      expect(controller.allNotes.single.title, 'Existing');
    });

    test(
      'load sets hasLoadError instead of hanging when the repository throws',
      () async {
        final repo = FakeNotesRepository([_note(id: '1')])..failNextLoad = true;
        final controller = NotesController(repo);

        await controller.load();

        expect(controller.isLoading, isFalse);
        expect(controller.hasLoadError, isTrue);
        expect(controller.allNotes, isEmpty);
      },
    );

    test('a retried load recovers once the repository works again', () async {
      final repo = FakeNotesRepository([_note(id: '1', title: 'Recovered')])
        ..failNextLoad = true;
      final controller = NotesController(repo);
      await controller.load();
      expect(controller.hasLoadError, isTrue);

      repo.failNextLoad = false;
      await controller.load();

      expect(controller.hasLoadError, isFalse);
      expect(controller.allNotes.single.title, 'Recovered');
    });

    test('upsert adds a new note and persists it', () async {
      final repo = FakeNotesRepository();
      final controller = NotesController(repo)..addListener(() {});
      await controller.load();

      await controller.upsert(_note(id: 'a', title: 'New note'));

      expect(controller.allNotes, hasLength(1));
      // Persisted, not just held in memory — a fresh controller reading
      // the same repository sees it too.
      final reloaded = NotesController(repo);
      await reloaded.load();
      expect(reloaded.allNotes.single.title, 'New note');
    });

    test('upsert on an empty note deletes it instead of saving', () async {
      final repo = FakeNotesRepository([_note(id: 'a', title: 'Real note')]);
      final controller = NotesController(repo);
      await controller.load();

      await controller.upsert(_note(id: 'a', title: '', body: ''));

      expect(controller.allNotes, isEmpty);
    });

    test('delete removes a note and persists the removal', () async {
      final repo = FakeNotesRepository([_note(id: 'a'), _note(id: 'b')]);
      final controller = NotesController(repo);
      await controller.load();

      await controller.delete('a');

      expect(controller.allNotes.map((n) => n.id), ['b']);
    });

    test('toggleFavorite flips isFavorite and persists it', () async {
      final repo = FakeNotesRepository([_note(id: 'a', isFavorite: false)]);
      final controller = NotesController(repo);
      await controller.load();

      await controller.toggleFavorite('a');
      expect(controller.byId('a')!.isFavorite, isTrue);

      await controller.toggleFavorite('a');
      expect(controller.byId('a')!.isFavorite, isFalse);
    });

    test('visibleNotes sorts newest-updated first', () async {
      final repo = FakeNotesRepository([
        _note(id: 'old', updatedAt: DateTime(2026, 1, 1)),
        _note(id: 'new', updatedAt: DateTime(2026, 1, 3)),
        _note(id: 'mid', updatedAt: DateTime(2026, 1, 2)),
      ]);
      final controller = NotesController(repo);
      await controller.load();

      expect(controller.visibleNotes.map((n) => n.id), ['new', 'mid', 'old']);
    });

    test('visibleNotes respects favoritesOnly', () async {
      final repo = FakeNotesRepository([
        _note(id: 'fav', isFavorite: true),
        _note(id: 'plain', isFavorite: false),
      ]);
      final controller = NotesController(repo);
      await controller.load();

      controller.setFavoritesOnly(true);

      expect(controller.visibleNotes.map((n) => n.id), ['fav']);
    });

    test('searchResults is empty for an empty query', () async {
      final repo = FakeNotesRepository([_note(id: 'a', title: 'Anything')]);
      final controller = NotesController(repo);
      await controller.load();

      expect(controller.searchResults, isEmpty);
    });

    test('searchResults matches title or body, case-insensitively', () async {
      final repo = FakeNotesRepository([
        _note(id: 'title-match', title: 'Grocery List', body: 'x'),
        _note(id: 'body-match', title: 'x', body: 'buy GROCERIES later'),
        _note(id: 'no-match', title: 'Unrelated', body: 'Nothing here'),
      ]);
      final controller = NotesController(repo);
      await controller.load();

      controller.setSearchQuery('grocer');

      expect(controller.searchResults.map((n) => n.id).toSet(), {
        'title-match',
        'body-match',
      });
    });
  });
}
