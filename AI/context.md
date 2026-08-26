# AI/context.md — briefing for an assistant working on this repo

This is a small, from-scratch Flutter notes app (a hiring-challenge build for
M-One, not a product). It has no backend, no auth, no sync — everything is
local. Read this before touching code; it'll save you from "fixing" things
that are intentional.

## What this app is

A plain-text notes app: title + body, both plain `String`. Create, edit,
favorite, delete, search. That's the whole feature set — no tags, no
folders, no rich text, ever. If a task asks you to add formatting, links,
checklists, or anything that isn't a plain string, stop and ask; it's very
likely out of scope for this app, not a gap to fill in.

## Architecture map

```
lib/
  models/note.dart              Note{id,title,body,isFavorite,createdAt,updatedAt}
  data/notes_repository.dart    NotesRepository interface + JsonFileNotesRepository
  state/
    notes_controller.dart       NotesController — the ONLY source of truth
    notes_scope.dart            NotesScope.of(context) — how screens get it
  theme/
    app_theme.dart              AppTheme.* color constants, dark theme only
    note_colors.dart            colorForNote(id) — deterministic pastel per note
  routes.dart                   AppRoutes.{editor,reading,search}(...) — all navigation goes through here
  widgets/
    note_card.dart              Shared NoteCard — reused by home list AND search results
    responsive_center.dart      ResponsiveCenter — wrap EVERY screen body in this
  screens/
    home/                       List, empty state, All/Favorite filter, swipe gestures
    editor/                     Create/edit, save/discard dialog, static toolbar
    reading/                    Read-only note view
    search/                     Search field + results + no-results state
test/
  fakes/fake_notes_repository.dart   In-memory repo for tests (no path_provider needed)
  notes_controller_test.dart         Behavioral tests for NotesController
  home_screen_responsive_test.dart   Golden tests: widths × text scales × content states
```

Data flow is one-directional and simple: `NotesController` (a plain
`ChangeNotifier`) holds the full note list in memory, loaded once from
`JsonFileNotesRepository` at startup. Every mutation (`upsert`, `delete`,
`toggleFavorite`) writes through to disk *before* `notifyListeners()`
fires, then screens rebuild via `ListenableBuilder`/`AnimatedBuilder`
listening to `NotesScope.of(context)`. No screen ever touches
`NotesRepository` directly — always go through the controller.

## Conventions (non-negotiable — these came from the brief, not from taste)

- **No third-party packages for UI, ever.** Everything visual is built from
  Flutter SDK widgets. `path_provider` is the one non-SDK dependency, and
  it's used only to locate a directory for the JSON file — nothing to do
  with UI. Don't add `google_fonts`, animation packages, icon packages,
  state-management packages (`provider`, `riverpod`, `bloc`), etc.
- **`Dismissible` is explicitly banned.** Swipe-to-delete/favorite on the
  home screen (`screens/home/widgets/swipeable_note_card.dart`) is hand-
  rolled with `GestureDetector.onHorizontalDrag*` + an `AnimationController`
  for the interruptible snap-back. If you need to touch swipe behavior,
  extend that pattern — don't reach for `Dismissible` or a slidable package.
- **Notes are plain strings. No rich text, no markdown, no formatting
  model, anywhere in this app.** The `Note` model only ever has plain
  `title`/`body` strings. The formatting toolbar in the editor
  (`static_formatting_toolbar.dart`) is decorative on purpose — every
  button has `onPressed: null`. Do not wire it up; that would be adding
  scope the brief explicitly forbids, not fixing a bug.
- **Dark theme only.** There is no light theme, and none is planned — the
  source design has no light-mode frame. Don't add `ThemeMode.system`
  handling; `AppTheme.theme` is the only theme.
- **State management is plain `ChangeNotifier`, not a package.** One
  `NotesController`, exposed via `NotesScope` (an `InheritedNotifier`).
  This was a deliberate choice for an app this size (one list, CRUD,
  filter, search) — don't introduce Provider/Riverpod/Bloc "to make it more
  idiomatic." If a task genuinely needs more structure, raise it as a
  question rather than silently swapping the state layer.
- **Persistence is a single JSON file**, written atomically (temp file +
  rename) in `JsonFileNotesRepository`. If you add a field to `Note`,
  update `toJson`/`fromJson` together, and remember `fromJson` needs to
  tolerate old files missing the new field (see how `isFavorite` defaults
  to `false` if absent) — there's no migration system, and there won't be
  one for an app this size.
- **Every screen's scrollable body is wrapped in `ResponsiveCenter`.** The
  Figma design is drawn at one phone width; this widget caps content width
  on tablet/desktop instead of letting a single column stretch edge-to-
  edge. If you add a new screen, wrap it too — it's a no-op below the
  width cap, so there's no reason not to.
- **`NoteCard` is shared** between the home list and search results. If you
  need to change how a note renders as a list item, change it there, not
  in both places separately.

## Traps / things that look like bugs but aren't

- **The editor doesn't save on every keystroke.** `EditorScreen` holds
  edits in local `TextEditingController`s and only calls
  `controller.upsert` on explicit save (or "Save" in the unsaved-changes
  dialog). This is intentional — don't "fix" it into autosave-per-keystroke
  without being asked; that changes the save/discard UX entirely.
- **`NotesController.upsert` silently deletes instead of saving if the
  note ends up empty** (`note.isEmpty`, both title and body blank). This
  is why the editor doesn't need its own "don't save empty notes" check.
- **There is exactly one "unsaved changes" dialog**
  (`editor/widgets/unsaved_changes_dialog.dart`), even though the source
  Figma file has two near-duplicate frames for it (12 "Save Dialog" and 13
  "Discard Dialog") with inconsistent copy and inconsistent button
  semantics. They were deliberately merged into one dialog using frame
  12's cleaner Discard/Save semantics. **Do not split this back into two
  dialogs** to "match the design more closely" — the design contradicts
  itself there; the merge is the fix, not a shortcut.
- **The reading screen renders plain, unstyled text**, even though the
  source Figma frame shows some words italicized. That's intentional — see
  the "notes are plain strings" rule above. Don't add a rich-text renderer
  to match the mock more closely.
- **The formatting toolbar in the editor does nothing on tap.** That's the
  brief's own instruction ("render it as a static bar"), not a missing
  feature.
- **Swipe thresholds (45% of card width) and the exact reveal/commit
  behavior are a judgment call**, not something specified anywhere in the
  design (Figma only shows two static in-between frames, not the full
  gesture spec). If you're asked to tune swipe feel, that's fair game to
  change; just know there's no "correct" value to reverse-engineer from
  the design.
- **`colorForNote(id)` derives a note's card color from a hash of its id**
  — notes don't store a color field. This is because the design never
  shows a color picker; there's nothing for a user to have set. Don't add
  a `color` field to `Note` to "make it more flexible" unless a task
  explicitly asks for user-chosen colors.
- **`Note.fromJson`'s `id` field has no fallback and can throw a
  `TypeError` that the repository's `on FormatException` catch won't
  catch**, and `NotesController.load()` is called fire-and-forget from
  `main.dart` with no error handling anywhere in that chain — if it ever
  throws, the home screen's loading spinner just hangs forever with no
  error shown. See the README's "Exceptions and error handling" section
  for the full trace; don't "fix" this by adding a broad try/catch
  somewhere without also giving the user a visible retry path, or you'll
  turn a loud failure into a silent one.
- **Tap, horizontal-swipe, and vertical-scroll on a home-screen note card
  all resolve through Flutter's normal gesture arena, not through custom
  disambiguation logic.** `NoteCard`'s `InkWell` owns tap;
  `SwipeableNoteCard`'s `GestureDetector` owns only horizontal drag; the
  `ListView` owns vertical drag. Splitting tap and drag onto different
  widgets is about code ownership, not about avoiding the arena — the
  arena resolves the same way regardless of which widget declares which
  recognizer, since arenas are per-pointer across the whole hit-test
  chain. See the README's "Gesture conflicts, in detail" section before
  changing anything here.
- **The eye icon (editor header) and the info icon (home header) don't do
  anything meaningful.** Neither destination is defined anywhere in the
  two Figma prototype flows that were traceable. They're placeholder
  behavior (a local visual toggle, and a static About dialog,
  respectively) — treat changing them as a product decision, not a bug fix.

## Testing

- `flutter test` runs everything. `notes_controller_test.dart` is fast,
  behavioral, and should be your first stop for any controller/repository
  change — it uses `FakeNotesRepository` (in-memory, `test/fakes/`), not
  the real JSON file.
- `home_screen_responsive_test.dart` is a golden-image test across 3
  widths × 2 text scales × 2 content states. If you deliberately change
  home-screen visuals, regenerate with:
  ```
  flutter test --update-goldens test/home_screen_responsive_test.dart
  ```
  and actually look at the diffed PNGs before committing — a passing
  `--update-goldens` run doesn't mean the change looks right, only that it
  ran without throwing.
- There's no CI wired up. Run `flutter analyze` and `flutter test` yourself
  before calling anything done.

## How this app was built, step by step

This is the literal sequence of commands/actions that produced this repo,
in order. It's here so that "how would I redo this, or something like it,
from an empty Flutter project" has a real answer instead of a vague one —
and so an agent picking up a similar task in this repo has a template for
the shape of the work, not just the end state.

**Phase 0 — fix the missing iOS Podfile** (the project had no
`ios/Podfile` because it has zero native plugins and Flutter now defaults
to Swift Package Manager, which doesn't need one):
1. `flutter create .` — regenerates any platform files `flutter create`
   normally scaffolds but are missing, without touching existing files.
   (Confirmed: didn't create the Podfile either, since Podfile generation
   is gated on having a plugin that needs CocoaPods, not on `flutter
   create` itself.)
2. Edit `pubspec.yaml`, add under `flutter:`:
   ```yaml
   config:
     enable-swift-package-manager: false
   ```
3. `flutter pub get`
4. `flutter build ios --no-codesign --debug` — still no Podfile (Flutter's
   `DarwinDependencyManagement.setUp` only calls `CocoaPods.setupPodfile`
   when there's at least one plugin; zero plugins means it's skipped
   entirely, SPM-disabled or not).
5. Copy the Podfile template straight from the Flutter SDK install:
   `$FLUTTER_ROOT/packages/flutter_tools/templates/cocoapods/Podfile-ios`
   → `ios/Podfile` (this is exactly what the tooling would've copied had
   step 4 triggered it).
6. Manually add the matching `#include?` line CocoaPods integration needs
   to `ios/Flutter/Debug.xcconfig` and `ios/Flutter/Release.xcconfig`.
7. `cd ios && LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8 pod install` (the
   `LANG`/`LC_ALL` prefix works around a Ruby `Encoding::CompatibilityError`
   this machine's CocoaPods hits without a UTF-8 locale set).
8. `flutter build ios --no-codesign --debug` again — clean build, no
   warnings, confirms the manual Podfile setup matches what the tooling
   would have produced.

**Phase 1 — scaffold the app's spine** (model, persistence, state, theme,
routing, and placeholder screens — everything the four real screens will
depend on, built first and alone so parallel screen work has a stable
contract):
9. Write `lib/models/note.dart` (`Note`: plain `id`/`title`/`body`/
   `isFavorite`/`createdAt`/`updatedAt`, `toJson`/`fromJson`, `isEmpty`).
10. Write `lib/data/notes_repository.dart` (`NotesRepository` interface +
    `JsonFileNotesRepository`, atomic write via temp-file-then-rename).
11. Write `lib/state/notes_controller.dart` (`NotesController extends
    ChangeNotifier` — `load`/`upsert`/`delete`/`toggleFavorite`,
    `visibleNotes`/`searchResults` getters).
12. Write `lib/state/notes_scope.dart` (`NotesScope extends
    InheritedNotifier<NotesController>`).
13. Write `lib/theme/app_theme.dart` and `lib/theme/note_colors.dart`
    (dark-only `ThemeData`; `colorForNote(id)` — deterministic hash-based
    pastel color, since notes have no stored color field).
14. Write `lib/routes.dart` (`AppRoutes.editor/reading/search` — every
    `Navigator.push` in the app goes through this instead of constructing
    `MaterialPageRoute` inline).
15. Rewrite `lib/main.dart` — wire `NotesController` +
    `JsonFileNotesRepository` + `NotesScope` + `MaterialApp`, calling
    `controller.load()` from `initState`. Point `home:` at a placeholder
    `HomeScreen`; write throwaway placeholder `StatelessWidget`s for
    `EditorScreen`/`ReadingScreen`/`SearchScreen` so the app compiles and
    routes resolve before the real screens exist.
16. `flutter analyze` — clean.
17. `git add` the above + `git commit` (see git history section below for
    exact commands/messages, here and for every following commit).
18. Write `lib/widgets/note_card.dart` (the one card renderer shared by
    the home list and search results) and
    `lib/widgets/responsive_center.dart` (width-capping wrapper every
    screen body uses). Pulled out *before* the four real screens, on
    purpose, so they don't each invent their own card/width handling.
19. `flutter analyze`, commit.

**Phase 2 — the four screens, in parallel** (each screen only depends on
the Phase 1 contract above, not on each other, so this is the one place
parallelizing genuinely helps — four isolated agents, one per screen,
each told: build against `Note`/`NotesController`/`NotesScope`/
`AppRoutes`/`NoteCard`/`ResponsiveCenter` exactly as they already exist,
touch only your own screen's files, run `flutter analyze` and `dart
format` on your own directory before finishing):
20. Agent A → `lib/screens/reading/reading_screen.dart` (frame 14).
21. Agent B → `lib/screens/search/search_screen.dart` +
    `widgets/no_results.dart` (frames 07/08).
22. Agent C → `lib/screens/editor/editor_screen.dart` +
    `widgets/static_formatting_toolbar.dart` +
    `widgets/unsaved_changes_dialog.dart` (frames 09-13).
23. Agent D → `lib/screens/home/home_screen.dart` +
    `widgets/empty_state.dart` + `widgets/favorites_filter.dart` +
    `widgets/swipeable_note_card.dart` (frames 01-04, 06).
24. As each agent finished: read its diff, run `flutter analyze
    lib/screens/<x>`, `dart format lib/screens/<x>`, run the *whole-
    project* `flutter analyze` too (to catch cross-screen breakage), then
    commit that screen alone before moving to the next one that finished.

**Phase 3 — manual end-to-end verification** (no code changes; this phase
exists to catch the class of bug static analysis can't):
25. `flutter devices`; `xcrun simctl boot <iphone-16-udid>`; attach the
    simulator panel.
26. `flutter run -d <udid>`.
27. By hand, in order: create a note (title + body) → toggle favorite in
    the editor → save → confirm it appears on the home list with the
    right color and star badge → open it (reading view, confirm plain
    text, no italics) → back → search for a word from the body (confirms
    body, not just title, is indexed) → search for something that
    matches nothing (confirms the no-results state) → back to home →
    swipe a card left past the threshold (confirms delete + the
    fade/collapse animation + the note is actually gone from the
    persisted list, not just hidden) → create two more notes → swipe one
    right (confirms favorite-toggle-via-swipe, snaps back, stays in the
    list) → tap the "Favorite" segment (confirms the filter narrows to
    exactly the favorited note) → discard-dialog flow (edit a note, hit
    back, confirm the "Save changes?" dialog appears, test both Discard
    and Save).
28. Kill the `flutter run` process.

**Phase 4 — tests**:
29. Write `test/fakes/fake_notes_repository.dart` (in-memory
    `NotesRepository`, no `path_provider` plugin channel needed in tests).
30. Write `test/notes_controller_test.dart` (behavioral: load/upsert/
    delete/toggleFavorite/empty-note-deletes/sort-order/favorites-filter/
    search-matching).
31. Write `test/home_screen_responsive_test.dart` (golden matrix: 3
    widths × 2 text scales × 2 content states).
32. `flutter test --update-goldens test/home_screen_responsive_test.dart`
    — generates the 12 PNGs under `test/goldens/`.
33. `flutter test` (whole suite) — confirms everything, including the
    goldens just generated, actually passes on a normal (non-update) run.
34. `flutter analyze`, `dart format test lib`, commit.

**Phase 5 — docs**:
35. Write `README.md` and `AI/context.md` (this file), commit.
36. Fill in the one placeholder README needed from the person doing the
    challenge (the applying-level line), commit.

**Phase 6 — ship it** (not yet done as of this writing — listed for
completeness):
37. `git push origin main develop` (or open a PR — see the repo's actual
    git remote for where).
38. Confirm the GitHub repo's visibility is set to public.
39. Record the required 3-minute unedited screen recording.
40. Submit the repo link through the channel the brief specifies.

## Git history, one commit at a time

This section documents the actual commits already on this branch — one
`git add` + `git commit -m "…"` per entry, in the order they really
happened, with the reasoning behind each. **These are a record, not
instructions to re-run** — the commits already exist; running these
commands again would either no-op (nothing changed to add) or conflict.
If you're looking for "how do I reproduce a history shaped like this one"
for a *different* piece of work, this is the pattern to copy: one commit
per logically-complete, independently-reviewable unit, message explaining
*why* not just *what*, in the order the work was actually done — never a
single "initial commit" dump, which is exactly what the brief calls out
as telling a reviewer nothing.

1. ```bash
   git add ios/Podfile ios/Podfile.lock ios/Flutter/Debug.xcconfig \
     ios/Flutter/Release.xcconfig ios/Runner.xcodeproj/project.pbxproj \
     ios/Runner.xcworkspace/contents.xcworkspacedata pubspec.yaml
   git commit -m "Set up CocoaPods for iOS (Podfile was missing)"
   ```
   Why its own commit: infrastructure, not app code — bundling it into the
   first "real" commit would have buried a genuinely separate concern (the
   project not building for iOS at all) inside an unrelated diff.

2. ```bash
   git add lib/models/note.dart lib/data/notes_repository.dart \
     lib/state/notes_controller.dart lib/state/notes_scope.dart \
     lib/theme/app_theme.dart lib/theme/note_colors.dart lib/routes.dart \
     lib/main.dart pubspec.yaml pubspec.lock test/widget_test.dart \
     linux/flutter/generated_plugins.cmake macos/Podfile \
     macos/Flutter/Flutter-Debug.xcconfig \
     macos/Flutter/Flutter-Release.xcconfig \
     windows/flutter/generated_plugins.cmake
   git commit -m "Scaffold notes app: model, JSON persistence, ChangeNotifier state, routes"
   ```
   Why its own commit: the whole non-UI foundation, landed as one unit
   because every piece in it (model, persistence, state, routing) only
   makes sense in terms of the others — there's no useful place to split
   it further. (The `macos`/`windows`/`linux` file changes are
   `flutter pub get`/`flutter create` side effects of adding `path_
   provider`, not something authored by hand — included here rather than
   split out because splitting auto-generated plugin registration from the
   dependency that caused it would be artificial.) Deleted the default
   counter-app `test/widget_test.dart` here too, since it tested code that
   no longer exists as of this same commit.

3. ```bash
   git add lib/widgets/note_card.dart lib/widgets/responsive_center.dart
   git commit -m "Add shared NoteCard and ResponsiveCenter widgets"
   ```
   Why its own commit, and why *before* the four screens rather than
   folded into one of them: both widgets are used by more than one
   screen, so committing them as their own unit makes that shared-
   dependency relationship visible in history, instead of looking like
   "the home screen commit happens to also contain a widget search later
   imports."

4. ```bash
   git add lib/screens/reading/reading_screen.dart
   git commit -m "Implement reading screen (frame 14)"
   ```
5. ```bash
   git add lib/screens/search/search_screen.dart \
     lib/screens/search/widgets/no_results.dart
   git commit -m "Implement search screen (frames 07/08)"
   ```
6. ```bash
   git add lib/screens/editor/editor_screen.dart \
     lib/screens/editor/widgets/static_formatting_toolbar.dart \
     lib/screens/editor/widgets/unsaved_changes_dialog.dart
   git commit -m "Implement note editor and merge the save/discard dialogs (frames 09-13)"
   ```
7. ```bash
   git add lib/screens/home/home_screen.dart \
     lib/screens/home/widgets/empty_state.dart \
     lib/screens/home/widgets/favorites_filter.dart \
     lib/screens/home/widgets/swipeable_note_card.dart
   git commit -m "Implement home screen: list, empty state, filter, swipe gestures (01-04, 06)"
   ```
   Commits 4-7 are one per screen, in the order each was actually finished
   (they were built in parallel, so "finished" order isn't the same as
   "started" order) — each is independently reviewable and independently
   revertable without touching the other three screens.

8. ```bash
   git add test/fakes/fake_notes_repository.dart \
     test/notes_controller_test.dart \
     test/home_screen_responsive_test.dart test/goldens/ \
     lib/data/notes_repository.dart lib/routes.dart \
     lib/state/notes_controller.dart lib/state/notes_scope.dart \
     lib/theme/app_theme.dart
   git commit -m "Add tests: NotesController behavior + responsive home-screen goldens"
   ```
   The `lib/` files in this commit are whitespace-only `dart format`
   output, not behavior changes — included in the same commit as the
   tests that prompted running `dart format` in the first place, rather
   than split into a separate no-op-looking formatting commit.

9. ```bash
   git add README.md AI/context.md
   git commit -m "Write README and AI/context.md"
   ```
10. ```bash
    git add README.md
    git commit -m "README: fill in applying level"
    ```
    Its own (tiny) commit rather than folded into #9, since it's a
    different kind of change — filling in a fact only the applicant
    knows, not authoring content — landed after the applicant answered.

**Not listed above: a commit titled `set up android build configs`.** It
lands after #10 in `git log` but wasn't made by the work described in this
file — it appeared while this session's git write access was locked down
by the tool's own permission system, so it came from somewhere else. It
changes `android/app/build.gradle.kts` to a namespace (`com.sparsa.dix`)
that belongs to a different project entirely, and mixes Groovy-script
assignment syntax into a Kotlin-DSL (`.kts`) file in a way that looks like
it won't compile. See the README's "Known issue" callout near the top —
flagged there for visibility since it affects `flutter run` on Android,
not silently fixed or reverted here since it isn't this file's place to
make that call.

## Things you can safely ignore or that are known-incomplete

See the README's "What is still wrong with this" section for the full,
current list (icon-behavior placeholders, no Android/real-device manual
testing, no accessibility-label pass beyond defaults, etc.) — it's kept up
to date there rather than duplicated here, since it changes as the app
changes and this file shouldn't need editing every time that list does.

## What this app is explicitly *not* (don't build these unless asked)

Backend, sync, auth, tags, folders, a design system, rich text/markdown,
light theme, offline-conflict resolution. All out of scope per the brief
this app was built against.
