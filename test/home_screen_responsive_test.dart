// Renders the home list across a range of widths, text scales, and
// content states, and checks it against committed golden images.
//
// This is the test the brief calls out as most valuable, so it's the one
// test in this repo that's a golden test rather than a behavioral one —
// see `notes_controller_test.dart` for the CRUD/filter/search logic.
//
// Regenerate goldens after an intentional visual change with:
//   flutter test --update-goldens test/home_screen_responsive_test.dart
//
// Goldens are rendered with Flutter's default test font (not the real
// system font), so they check *layout* — wrapping, overflow, spacing —
// not real typography. They were generated on this machine's Flutter
// version; a different Flutter/Skia version may need a re-generation,
// which is a well-known limitation of golden tests in general, not
// specific to this repo.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_application/models/note.dart';
import 'package:task_application/screens/home/home_screen.dart';
import 'package:task_application/state/notes_controller.dart';
import 'package:task_application/state/notes_scope.dart';
import 'package:task_application/theme/app_theme.dart';

import 'fakes/fake_notes_repository.dart';

final _fixedNow = DateTime(2026, 1, 1, 12);

List<Note> _fewNotes() => [
  Note(
    id: '1',
    title: 'Grocery list',
    body: 'Milk, eggs, bread, coffee.',
    isFavorite: true,
    createdAt: _fixedNow,
    updatedAt: _fixedNow,
  ),
  Note(
    id: '2',
    // Long enough to force wrapping at narrow widths and ellipsis at
    // large text scales — that's the point of this fixture.
    title:
        'A genuinely quite long note title that should wrap across '
        'multiple lines instead of overflowing the card',
    body: '',
    isFavorite: false,
    createdAt: _fixedNow.subtract(const Duration(minutes: 1)),
    updatedAt: _fixedNow.subtract(const Duration(minutes: 1)),
  ),
  Note(
    id: '3',
    title: 'Book recommendations',
    body: 'The Design of Everyday Things',
    isFavorite: false,
    createdAt: _fixedNow.subtract(const Duration(minutes: 2)),
    updatedAt: _fixedNow.subtract(const Duration(minutes: 2)),
  ),
];

Future<void> _pumpHome(
  WidgetTester tester, {
  required List<Note> notes,
  required double width,
  required double textScale,
}) async {
  tester.view.physicalSize = Size(width, 1200);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final controller = NotesController(FakeNotesRepository(notes));
  await controller.load();

  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(
        size: Size(width, 1200),
        textScaler: TextScaler.linear(textScale),
      ),
      child: NotesScope(
        controller: controller,
        child: MaterialApp(theme: AppTheme.theme, home: const HomeScreen()),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  final widths = {'phone-320': 320.0, 'phone-390': 390.0, 'tablet-800': 800.0};
  final textScales = {'scale-1x': 1.0, 'scale-2x': 2.0};
  final states = {'empty': const <Note>[], 'notes': _fewNotes()};

  for (final widthEntry in widths.entries) {
    for (final scaleEntry in textScales.entries) {
      for (final stateEntry in states.entries) {
        final name =
            'home_${stateEntry.key}_${widthEntry.key}_${scaleEntry.key}';
        testWidgets('home screen — $name', (tester) async {
          await _pumpHome(
            tester,
            notes: stateEntry.value,
            width: widthEntry.value,
            textScale: scaleEntry.value,
          );

          // No overflow anywhere in the tree at this width/scale — this
          // is the actual pass/fail signal; the golden image is for a
          // human to look at, not for this assertion.
          expect(tester.takeException(), isNull);

          await expectLater(
            find.byType(HomeScreen),
            matchesGoldenFile('goldens/$name.png'),
          );
        });
      }
    }
  }
}
