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
