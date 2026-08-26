# Notes — M-One Flutter Challenge

A local-only, plain-text notes app built from the [Notes App UI Figma
design](https://www.figma.com/design/2OJezhe0ZOgw3KeSHLC8Fr/Notes-App-UI--M-one-task-)
for the M-One Flutter hiring challenge.

**Level applying for:** _TODO — fill in before submitting._

## Running it

```bash
flutter pub get
flutter run
```

iOS needs CocoaPods, which is now set up (`ios/Podfile` — see git history
for why it was missing and how it got generated). If you've never run
CocoaPods on this machine, `flutter run -d <ios-device>` installs pods
automatically on first build.

```bash
flutter analyze   # should be clean
flutter test      # 21 tests: controller behavior + golden images
```

## State management: plain `ChangeNotifier`

One `NotesController` (a `ChangeNotifier`) is the single source of truth
for the note list, exposed to every screen through `NotesScope` (an
`InheritedNotifier`) — no `provider`, `riverpod`, or `bloc` package.

Why: the entire app is one list with CRUD, a favorites filter, and search.
That's not enough surface area to justify a state-management framework —
`ChangeNotifier` plus `ListenableBuilder` covers it in code any reviewer
can read without knowing a specific package's conventions, and it keeps
the third-party dependency count at exactly one (`path_provider`, used
only to locate a directory — not for UI).

## Persistence: a single JSON file, written atomically

`JsonFileNotesRepository` stores every note as one JSON array in one file
in the app's documents directory. Writes go to a temp file first, then
`rename()` over the real file — a single filesystem directory-entry swap
on both Android and iOS. If the process is killed mid-write, the rename
either hasn't happened yet (old file intact) or already has (new file
intact); there's no window where a half-written file is what's on disk.
That's what "nothing lost when the process is killed" means here — the
last *completed* save always survives.

## 05 vs 06: I built frame 06 (Filter View)

The design has two answers to "how do you see your favorite notes": frame
05 is a single list sectioned into "FAVORITES" / "OTHER NOTES", and frame
06 is a segmented "All / Favorite" control that filters the same list in
place. I built 06.

Reasoning: it scales better as the note count grows (05's favorites
section pushes everything else further down the longer it gets), and it
reuses the exact same `visibleNotes`-style filtered-list rendering path
that search already needs — one list-rendering concept instead of two.

## Responsiveness — what I checked, and how

- **Automated**: `test/home_screen_responsive_test.dart` renders the home
  screen at three widths (320 / 390 / 800 logical pixels — small phone,
  standard phone, tablet) crossed with two text scales (1.0×, 2.0×) and
  two content states (empty, and a set of notes including one title long
  enough to force wrapping), asserting zero overflow exceptions at every
  combination. The 12 resulting images are committed under
  `test/goldens/` so they can be looked at directly, not just trusted.
- **Manual**: full click-through (create → save → favorite → search →
  swipe-delete → swipe-favorite → filter → read → edit) on an iPhone 16
  simulator, iOS 18.5, 393×852pt.
- **Not checked**: a real device (only simulator), any Android device or
  emulator, the desktop/web targets `flutter create` scaffolds by default,
  Dynamic Type/accessibility text sizes beyond 2×, VoiceOver/TalkBack,
  RTL locales. These are gaps, not "it definitely works" — see below.

`ResponsiveCenter` caps content at 640 logical pixels and centers it on
anything wider, rather than letting a single column of note cards stretch
edge-to-edge on a tablet or desktop window — the design gives no guidance
for that width at all, so this is my own reasonable extrapolation, not
something drawn anywhere.

## Design notes — where the design broke, and what's wrong in it

The brief says this is the highest-value section, so here's everything I
found, in the order I found it:

1. **Frame 14 (Reading Note) contradicts the app's own spec.** It renders
   some words in the body italicized, but the brief is explicit that notes
   are plain strings with no rich-text/formatting model anywhere in this
   app. I did not replicate the italics — the reading screen renders
   plain text. I'm treating this as a mistake in the mock, not a feature
   to build a formatting model for.
2. **Frame 13's dialog copy has a typo/grammar error**: "Are your sure you
   want discard your changes?" — missing "to", and "your" where it should
   be "you".
3. **Frames 12 and 13 are two near-duplicate dialogs for the same
   situation** (leaving the editor with unsaved changes), with
   inconsistent copy and inconsistent button semantics: frame 12 offers
   Discard(red)/Save(green), frame 13 offers Discard(red)/Keep(green) with
   different title text. Rather than build two dialogs that contradict
   each other, I merged them into one, using frame 12's cleaner
   Discard/Save semantics.
4. **Frame 11's note title is missing text present everywhere else for the
   same note.** Frames 10, 12, and 14 all show "Book Review: The Design of
   Everyday Things **by Don Norman**"; frame 11 shows the same note as
   just "Book Review: The Design of Everyday Things" — no author suffix.
   Content inconsistency in the mock, not something I tried to explain.
5. **The "save" action uses two different icon glyphs for the same
   thing.** Frame 09 (new note) shows an export/share-box icon in that
   header slot; frames 10/11 (editing existing content) show a disk icon.
   I unified this to one icon rather than replicating the inconsistency.
6. **Minor copy quirks**: "Create your first note !" (frame 01) and "Save
   changes ?" (frame 12) both have a stray space before the punctuation
   mark. Normalized in the app.
7. **Neither the info icon (Home) nor the eye icon (Editor) has a defined
   destination.** I traced both prototype flows in the Figma file (Flow 1
   and Flow 2) and neither wires these icons to anything. I made
   reasonable placeholder choices (a static About dialog; a local,
   unpersisted visual toggle) rather than guessing at unspecified
   functionality — see `AI/context.md` for exactly what they do.
8. **No dev-mode access** (view-only Figma link — no inspect panel, no
   redlines, no exported assets) means every color, spacing value, and the
   empty-state illustration are matched by eye, not sampled. The note-card
   palette (`theme/note_colors.dart`) and accent colors
   (`theme/app_theme.dart`) are my own approximations of what's shown, and
   the empty-state illustration is a plain `Icon` rather than a
   recreation of the design's drawn illustration (I have no exported asset
   to work from and didn't think a hand-redrawn copy was a good use of
   time versus everything else in this brief).
9. **The design is drawn at exactly one width and one text scale**, with
   no indication of intended behavior at any other size — that's the
   whole reason the brief calls this out as a requirement rather than
   something the design shows. `ResponsiveCenter`'s width cap (see above)
   is my own call, not an extrapolation from anything in the file.

## What is still wrong with this

Required section, and I mean it — this is what I know is incomplete or
questionable in my own code, not a victory lap:

- **The swipe gesture thresholds and exact reveal behavior are my own
  interpretation**, not a spec. The two Figma frames (03, 04) show a
  single static in-between moment, not the full gesture curve. I picked
  45% of card width as the commit threshold and a red/gold full-card
  reveal; it feels reasonable on the simulator, but I have not user-tested
  it, and a real finger on real glass may disagree with what feels right
  on a trackpad-driven simulator tap.
- **No manual testing beyond one iOS simulator.** Everything above "ran
  the automated widget/golden tests" and "clicked through the whole app
  once on an iPhone 16 simulator" is unverified: no real device, no
  Android at all (simulator or device), no desktop/web target despite
  `flutter create` having scaffolded them, no Dynamic Type beyond the 2×
  covered by the golden tests, no screen reader pass.
- **Minimal accessibility semantics.** Icon buttons get Flutter's default
  `Tooltip`/`Icon` semantics; I did not do a deliberate `Semantics`-label
  pass (e.g. the swipe-to-delete/favorite gesture has no non-gesture
  fallback for a screen-reader or switch-control user — there's no way to
  delete or favorite a note without a horizontal drag).
- **The editor's eye icon toggles local state that has no visible effect.**
  I chose to keep it interactive (see `AI/context.md`) rather than a true
  no-op, but on reflection a real user tapping it and seeing nothing
  change is arguably worse than it doing nothing at all — I'd revisit this
  with more time or a real answer about its intended behavior.
- **Search has no debounce and no ranking** — it re-filters the in-memory
  list on every keystroke and returns matches in recency order, not
  relevance order. Fine at the scale this app will ever see locally; would
  not scale as written to a large note count.
- **`colorForNote` can coincidentally repeat.** With a 6-color palette
  keyed off a hash of the note id, two visually-adjacent cards can land on
  the same color by chance — there's no adjacent-color-avoidance logic.
  Cosmetic, not a data issue, but a real one.
- **No shared-element/hero transitions.** Navigation uses Flutter's
  default push/pop route transitions throughout; nothing like a card
  morphing into the editor. The brief's "behaves like a shipped app" bar
  probably wants more polish here than I gave it, given the time box.
- **Gesture-conflict testing was manual, not exhaustive.** I verified tap
  vs. horizontal-drag vs. list-scroll resolve correctly for straight
  gestures on a simulator; I have not stress-tested rapid diagonal swipes,
  simultaneous multi-touch, or a swipe started mid-scroll-momentum.

## AI usage

Built with Claude Code (Anthropic's CLI agent) end to end — architecture,
all four screens (built in parallel by sub-agents against a shared
contract I wrote first: `Note`, `NotesController`, `NotesScope`,
`AppRoutes`, `NoteCard`, `ResponsiveCenter`), the Figma review, and this
README. `AI/context.md` is the actual brief used, not a reconstruction
after the fact.

## Not in scope

Whichever of 05/06 wasn't picked (05), backend, sync, auth, tags, folders,
a design system — per the brief.
