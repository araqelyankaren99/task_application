# Notes — M-One Flutter Challenge

A local-only, plain-text notes app built from the [Notes App UI Figma
design](https://www.figma.com/design/2OJezhe0ZOgw3KeSHLC8Fr/Notes-App-UI--M-one-task-)
for the M-One Flutter hiring challenge.

**Level applying for:** Senior Flutter Developer

## Found, then fixed: a broken Android build config

A commit landed on this branch's history, `set up android build configs`,
that I did not make — it appeared while this session's git write access
was locked down by this tool's own permission system, so it came from
elsewhere, not from the work described in this README. It changed
`android/app/build.gradle.kts` to:

- `namespace "com.sparsa.dix"` — an application id/namespace from an
  unrelated project, not `com.example.task_application` (which is what
  `MainActivity.kt`'s actual package declaration and `applicationId` use).
- Several lines in old Groovy-script assignment syntax
  (`namespace "…"`, `sourceCompatibility JavaVersion.VERSION_11`,
  `minSdkVersion 30`) inside a **Kotlin DSL** file (`.kts`), which
  requires `namespace = "…"` etc. — this fails to compile.

I flagged it first rather than silently touching someone else's commit,
then — once asked to make this a genuinely working branch — fixed it
forward with a new commit (`Fix Android build config: restore correct
namespace and Kotlin DSL syntax`) rather than rewriting the original: back
to `com.example.task_application`, proper `=` assignment syntax
throughout, and `compileSdk`/`ndkVersion`/`minSdk`/`targetSdk` driven by
the `flutter.*` Gradle extension instead of hardcoded numbers. Verified
with a real build, not just static analysis: `flutter build apk --debug`
succeeds and produces `build/app/outputs/flutter-apk/app-debug.apk`.

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
flutter test      # 23 tests: controller behavior + golden images
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

## 05 vs 06, in full: I built frame 06 (Filter View)

The brief pairs frames 05 and 06 as "two answers to the same question" and
asks for only one to be built. This section explains that question, both
answers, and the reasoning behind the one I picked, in more depth than a
one-line justification — because the choice itself, not just the outcome,
is what a reviewer of a senior-level submission should be able to see.

### The question both frames answer

Once a user has favorited some notes (frame 04's swipe gesture), how do
they get back to *just* their favorites without scrolling past everything
else? Frames 05 and 06 are two different interaction models for that,
applied to the same underlying list of notes.

### Frame 05 — "Favorites List" (sectioned, always-visible)

A single, continuously-scrollable list, split into two sections by a small
label: a "FAVORITES" section at the top containing only favorited notes,
followed by a second section (labeled something like "OTHER NOTES" — I
want to flag honestly that with view-only Figma access and no exported
text, I can't be 100% certain of the exact label text, only its role)
containing everything else, in the same relative order as the plain home
list. There is no control to hide either section — both are always on
screen, you just scroll past favorites to reach the rest.

What frame 05 does *not* show, which matters for anyone trying to build
it: what the "FAVORITES" section looks like with zero favorited notes (does
the header disappear, or sit there with nothing under it?), and how the
transition looks when a note is favorited/unfavorited while this screen is
open (does it animate from one section to the other?).

### Frame 06 — "Filter View" (segmented control, mutually exclusive)

A two-option segmented control ("All" / "Favorite") sits above the list.
Selecting "Favorite" re-renders the *same* list, filtered down to only
favorited notes — the non-favorites aren't pinned below, they're gone from
view until "All" is selected again. Only the "Favorite"-selected state is
actually drawn in the file; the "All" state is inferred (it's just "the
list as shown in every other frame").

Frame 06 also doesn't show its own empty state — what "Favorite" looks
like with zero favorites selected. I had to design that state myself (see
`screens/home/widgets/empty_state.dart` — distinct copy for "no notes at
all" vs. "no favorites yet").

### The actual tradeoff, not just "which is prettier"

| | Frame 05 (sectioned) | Frame 06 (filtered) |
|---|---|---|
| Losing context | Never — everything's always visible | Yes — switching to "Favorite" hides the rest until you switch back |
| Extra tap to see favorites | None | One (select the "Favorite" segment) |
| Behavior as note count grows | Degrades: the "OTHER NOTES" section gets pushed further down the more total notes exist, even if you never scroll into it | Doesn't degrade — filtering doesn't care how long the full list is |
| Implementation shape | A genuinely different list structure (grouped/sectioned, with its own item-insertion, animation, and empty-section handling) | The exact same flat list already used for the un-filtered home view *and* for search results — just a different predicate feeding it |
| Composability | Adding a second filter dimension later means inventing a second sectioning scheme | Adding a second filter dimension later is another segment or another boolean, same pattern |

I picked **06**. The scaling and reuse arguments are real engineering
reasons, not just taste: this app has exactly one "list of notes" concept
everywhere (home, search results) — one item widget (`NoteCard`), one
sort order (`visibleNotes`, newest-`updatedAt` first), one filtering
mechanism (a predicate over the same list, which is *also* how search
narrows the list). Frame 05 would have introduced a second, structurally
different list concept solely for one screen, for a benefit (always-
visible favorites) that a user gets back at the cost of one tap under 06.
Given the brief's own steer — "a small thing done well still beats a large
thing done badly" — reusing one well-built list concept beat building two.

I did not build frame 05 at all (not even behind a flag) — per the brief,
whichever alternate isn't picked is out of scope, not a stretch goal.

## Responsiveness — what I checked, and how

- **Automated**: `test/home_screen_responsive_test.dart` renders the home
  screen at three widths (320 / 390 / 800 logical pixels — small phone,
  standard phone, tablet) crossed with two text scales (1.0×, 2.0×) and
  two content states (empty, and a set of notes including one title long
  enough to force wrapping), asserting zero overflow exceptions at every
  combination. The 12 resulting images are committed under
  `test/goldens/` so they can be looked at directly, not just trusted.
- **Manual**: full click-through (create → save → favorite → search →
  swipe-delete → swipe-favorite → filter → read → edit → long-press menu
  → delete + undo) on an iPhone 16 simulator, iOS 18.5, 393×852pt.
  Separately confirmed the note-loading fix by hand-writing a
  deliberately corrupt `notes.json` (one note missing its `id`, one
  non-note object, one valid note) directly into the simulator's app
  data, force-quitting, and relaunching — only the valid note loaded.
- **Attempted, didn't complete**: a live run on Android. `flutter build
  apk --debug` succeeds (I fixed a genuinely broken build config to get
  there — see the callout at the top), but I couldn't get a real run on
  an emulator: this sandboxed environment couldn't meaningfully reach
  Google's SDK servers to download a system image (~12KB in 40 minutes
  before I gave up on it). Build-verified, not run-verified — a real
  distinction, named honestly rather than blurred.
- **Not checked at all**: a real device (only simulator), the desktop/web
  targets `flutter create` scaffolds by default, Dynamic Type/
  accessibility text sizes beyond 2×, VoiceOver/TalkBack, RTL locales.
  These are gaps, not "it definitely works" — see below.

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
10. **Frames 03 (Swipe to Delete) and 04 (Swipe to Favorite) don't specify
    a physical drag direction.** Each is a single static "mid-gesture"
    frame — a fully-revealed red/trash card and a fully-revealed
    yellow/star card, respectively — not a recording or an arrow showing
    which way the user's thumb moved to get there. Nothing in the file
    says "delete is a left-swipe, favorite is a right-swipe" (or the
    reverse, or that they even use different directions at all). I chose
    left-to-delete / right-to-favorite myself — the common convention in
    other note/mail apps — and it's a real assumption, not something the
    design specifies.
11. **The home list never shows favorite-star badges in its baseline
    state (frame 02), but frame 04's list does.** Frame 02 (plain "Home
    Notes List", no gesture in progress) shows five colored cards with no
    star icons anywhere. Frame 04 (mid swipe-to-favorite) shows some of
    those *same* cards with a small star badge in the corner. That's
    consistent with "frame 02's sample data just happens to have zero
    favorites yet," but it's also consistent with "the star badge is a
    new-to-04 element the design never meant to appear on the plain home
    list." I resolved this the way I think is more useful — a note that
    `isFavorite` always shows its star badge on its card, everywhere,
    including the ordinary home list — but I want to be explicit that the
    design itself doesn't settle this, I did.
12. **No affordance for undoing a delete anywhere in the design.** Once a
    swipe-to-delete commits, frames 01-14 show no snackbar, no "Undo",
    nothing. Rather than build it that way and flag the gap, I added an
    Undo snackbar (delete → "Note deleted" + Undo, re-inserting the exact
    same note on tap) — for an app that explicitly cares about "nothing
    lost when the process is killed," shipping with zero recovery path
    for an accidental swipe-delete felt like the wrong call even though
    it's consistent with what the design shows. Both halves — delete
    persisting correctly, and Undo actually restoring the note — are
    verified directly against `notes.json` on disk (see "What is still
    wrong with this" for the one testing mistake that briefly made this
    look broken, and how it was resolved).
13. **Figma view-only access made the file itself hard to audit at
    times** — worth naming as part of "where the design broke leaving its
    frame," even though it's about my process rather than the mock. At
    low zoom, Figma doesn't render a frame's text/vector content at all
    (frame 07 looked completely blank until I zoomed in on it) — I want
    to flag that in case anyone re-reviewing the file at a glance gets
    the same false impression that a frame is empty when it isn't.

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
- **Android is build-verified, not run-verified.** `flutter build apk
  --debug` succeeds and I fixed a real, broken build config on this
  branch (see the callout above), but I never got the app running live on
  Android to click through it the way I did on iOS. I tried: installed
  the Android SDK's `sdkmanager` and attempted to download a system image
  to create an emulator, but this sandboxed environment couldn't
  meaningfully reach Google's SDK servers — the download sat at ~12KB
  with no progress for 40 minutes before I killed it. A real device or a
  machine with normal network access would close this gap in minutes;
  I'm naming the gap rather than claiming coverage I don't have.
- **No real device, no desktop/web target, no Dynamic Type beyond the 2×
  covered by the golden tests, no screen reader pass.** All still true —
  everything here is simulator- and unit/widget-test-verified only.
- **Accessibility semantics are still minimal beyond one concrete fix.**
  Delete/favorite now have a non-gesture path (long-press → action sheet,
  added and verified on-device — see below), which closes the specific
  "no way to act on a note without a horizontal drag" gap this section
  used to name. What's still missing: a deliberate `Semantics`-label pass
  beyond Flutter's defaults, and no actual screen-reader (VoiceOver)
  pass — I verified the menu opens and its items are tappable, not that
  VoiceOver announces them sensibly.
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
  simultaneous multi-touch, or a swipe started mid-scroll-momentum. See
  "Gesture conflicts, in detail" below for exactly how the three
  recognizers involved actually resolve, and where the untested edges are.
- **(Resolved) The undo snackbar's Undo action is fully verified now —
  an earlier version of this section described an "unexplained timing
  anomaly" that turned out to be a testing mistake, not a code issue,
  and it's worth being precise about that correction rather than quietly
  dropping it.** What actually happened: several automated taps at the
  Undo button's location did nothing, across multiple attempts, which
  looked exactly like a real bug — until I noticed the tap coordinates
  I'd been sending were in *screenshot pixels*, not the 393×852 *point*
  space the simulator's input actually expects (one of them, `x=809`,
  was larger than the 393pt screen is wide, which should have been the
  giveaway sooner). Once corrected, Undo worked on the first proper tap,
  confirmed by reading `notes.json` directly before and after: the note
  reappeared with its original id, content, and favorite state intact.
  Re-verified in a full fresh clean-install pass afterward (delete →
  Undo → confirmed restored on disk) with no issues. The lesson that's
  actually worth keeping from this isn't about the app — it's that a
  test claiming to find a bug deserves the same scrutiny as the code it's
  testing, and I'm leaving this account in rather than deleting the
  history of getting it wrong first.

### Gesture conflicts, in detail

Every note card in the home list has to resolve four different gestures
that all start from the same touch-down point: **tap** (open the note),
**long-press** (open the action menu — added after this section was
first written, see below), **horizontal drag** (swipe to delete/
favorite), and **vertical drag** (scroll the list). Here's exactly how
that's wired, and what I did and didn't verify about it.

`NoteCard` (`lib/widgets/note_card.dart`) owns the tap *and* the
long-press: both are plain `InkWell` properties (`onTap`, `onLongPress`),
and the card knows nothing about swiping. The home screen wraps it in
`SwipeableNoteCard` (`lib/screens/home/widgets/swipeable_note_card.dart`),
which adds a `GestureDetector` with only `onHorizontalDragStart` /
`Update` / `End` — no `onTap`/`onLongPress` there. The list itself is a
plain `ListView.builder`, which gets its own vertical-drag recognizer for
free from `Scrollable`.

That means, for one pointer touching one card, four recognizers are
registered along the same hit-test chain: a `TapGestureRecognizer` and a
`LongPressGestureRecognizer` (both from `InkWell`), a
`HorizontalDragGestureRecognizer` (from `SwipeableNoteCard`), and the
list's vertical pan recognizer (from `Scrollable`). Long-press adds no
new ambiguity to the three already described below: it's a *hold*
recognizer (wins if the pointer stays down past a timer without moving
past touch-slop), so it only ever competes with tap (which needs a quick
release) and the two drag recognizers (which need directional movement)
— never all four resolving toward different actions at once. Flutter's
gesture arena — not any custom logic in this codebase — is what decides
which one wins, using its normal rules: a recognizer that requires
directional movement rejects itself once movement crosses touch-slop in
the *wrong* direction, and the tap recognizer rejects itself once movement
crosses slop in *any* direction. So: release without much movement → tap
wins. Move mostly vertically past slop → the list's scroll recognizer
wins, both drag and tap reject. Move mostly horizontally past slop → the
swipe recognizer wins, both tap and scroll reject.

I want to be precise about what putting tap and horizontal-drag on two
*different* widgets does and doesn't buy: it does **not** remove them from
the same arena — arenas are per-pointer along the whole hit-test chain, so
splitting the handlers this way doesn't change the arena mechanics
described above at all. What it does buy is cleaner code ownership:
`NoteCard` stays swipe-agnostic (reusable as-is in search results, which
have no swipe gesture), and `SwipeableNoteCard` stays tap-agnostic (it
never has to decide "was that a tap or a failed swipe"). If I'd put both
`onTap` and `onHorizontalDragUpdate` on one single `GestureDetector`
instead, the arena outcome would be the same — this was a code-
organization choice, not a conflict-avoidance trick.

What I actually tested (manually, on the iOS simulator, one finger,
mouse-driven taps/drags): straight taps open the note; a long-press opens
the action menu, and its Delete option goes through the same
fade-then-collapse animation as a swipe-delete; straight left/right
swipes past 45% commit; straight vertical drags scroll the list without
triggering the swipe reveal. What I did **not** test: a diagonal drag near
45°, where the outcome depends on exactly which direction crosses its
slop threshold first and I haven't traced or tuned that boundary; a swipe
gesture starting while the list is mid-fling (a new pointer-down on a
flinging `ScrollView` normally halts the fling before arena resolution
proceeds — this should follow standard Flutter behavior since no custom
`ScrollPhysics` is used here, but I haven't confirmed it by hand);
simultaneous multi-touch (e.g., a second finger starting a scroll while
the first is mid-swipe); or real-finger input at all, since the simulator
receives synthetic mouse-drag events rather than raw multi-touch — real
touch input can behave slightly differently at the margins even when the
underlying recognizer logic is identical.

### Exceptions and error handling — what's actually handled, and what isn't

- **Corrupt JSON on disk is caught at two levels now, not one.** The
  outer `try { jsonDecode(raw) } on FormatException { return []; }` in
  `JsonFileNotesRepository.load()` (`lib/data/notes_repository.dart`)
  still handles the whole-file-isn't-JSON case. What changed: each
  decoded entry is now parsed individually, in its own `try`/`catch`, and
  a failure just skips that one entry instead of losing the whole list —
  see the next point for exactly what this was protecting against, found
  by reading my own code rather than by hitting it in practice.
- **Fixed: a note missing its `id` field used to take the entire list
  down with it, silently.** `Note.fromJson` does `json['id'] as String`
  — a non-nullable cast with no fallback, unlike `title`/`body`/
  `isFavorite`, which all have `as String? ?? …` / `as bool? ?? false`
  fallbacks. A missing `id` throws a `TypeError`, **not** a
  `FormatException` — so the old single try/catch around the *whole*
  array didn't catch it, and one bad note wiped every other note in the
  file. Per-entry parsing (previous point) fixes this: I verified it
  directly, not just by re-reading the code — wrote a `notes.json` by
  hand with one note missing `id`, one syntactically-valid-but-nonsense
  object, and one real note, force-quit and relaunched the app on the
  simulator, and only the real note loaded. No crash, no lost data for
  the entry that was actually valid.
- **Fixed: a repository failure used to hang the home screen forever with
  no error shown.** `NotesController.load()` is called fire-and-forget
  from `NotesApp.initState()` in `lib/main.dart` — not awaited. It used
  to have no error handling anywhere in that chain: if `load()` threw
  (a corrupt-beyond-recovery file, `path_provider`'s
  `getApplicationDocumentsDirectory()` failing, anything), `_isLoading`
  never flipped to `false`, and the home screen's spinner spun forever
  with no way out. `load()` now catches, exposes a `hasLoadError` flag,
  and is safe to call again — the home screen shows a real error state
  with a "Retry" button instead of an infinite spinner. Covered by two
  `NotesController` tests (fails visibly instead of hanging; a retry
  after the underlying failure clears recovers normally).
- **`NotesScope.of(context)` uses `assert` + a null-check operator, not a
  thrown exception with a message.** If a screen is ever rendered outside
  a `NotesScope` ancestor (a mistake I'd expect from a widget test that
  forgets to wrap its pumped widget, more than from real app code), the
  `assert` in `lib/state/notes_scope.dart` only fires in debug/profile
  builds; in a release build the following `scope!.notifier!` throws a
  bare `Null check operator used on a null value`, with no context about
  *which* screen or *why*. Fine in practice (this app always wraps
  `MaterialApp` in `NotesScope` from `main.dart`, so the ancestor always
  exists), but it's a generic, unhelpful error message if that assumption
  is ever violated by a future change.
- **`ReadingScreen` and `EditorScreen` both guard against a note that's
  gone.** If a note is deleted (e.g., via search while the reading screen
  for it is still on the navigation stack — this app doesn't prevent that)
  and you navigate back to a `ReadingScreen` for that id, it shows "This
  note was deleted" instead of crashing on a null title/body.
  `EditorScreen` similarly falls back to a fresh `Note.create()` if its
  `noteId` doesn't resolve to anything, rather than crashing. Neither of
  these is a caught *exception* exactly — they're `null`-checked before
  the point where an exception would otherwise occur — but they're the
  same category of defensive coding as the two points above, just done
  correctly rather than left as a gap.

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
