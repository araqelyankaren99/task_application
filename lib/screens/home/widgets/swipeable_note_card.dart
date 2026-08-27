import 'package:flutter/material.dart';

import '../../../models/note.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/note_card.dart';
import 'note_actions_sheet.dart';

/// Wraps the shared [NoteCard] with the swipe-to-delete (frame 03) /
/// swipe-to-favorite (frame 04) gesture layer. Deliberately not built on
/// [Dismissible] (banned by the brief) — this is a hand-rolled
/// horizontal-drag layer using [Transform.translate] plus a single
/// [AnimationController] for the snap-back/away animation.
///
/// Gesture-conflict note: only [onHorizontalDragStart]/`Update`/`End` are
/// attached here. Tapping to open the note is left entirely to
/// [NoteCard]'s own `InkWell` (via the [onTap] we pass through), rather
/// than adding a second `onTap` on this widget's `GestureDetector`. That
/// way there is exactly one tap recognizer and one horizontal-drag
/// recognizer in the gesture arena for this card, and Flutter resolves
/// "did the finger move enough to be a drag, or was it a tap" the normal
/// way (touch-slop + direction), while the list's own vertical scroll
/// recognizer competes independently by initial direction — no manual
/// arena tricks needed.
///
/// Long-press opens [showNoteActionsSheet] — a non-gesture path to the
/// same delete/favorite actions the swipe reaches, for anyone who can't
/// perform (or reliably trigger) a horizontal drag. `InkWell` already
/// supports `onLongPress` as a distinct recognizer (a hold past a timer,
/// not a drag), so this composes with the arena above rather than adding
/// to its ambiguity.
class SwipeableNoteCard extends StatefulWidget {
  const SwipeableNoteCard({
    super.key,
    required this.note,
    required this.onTap,
    required this.onDelete,
    required this.onFavorite,
  });

  final Note note;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onFavorite;

  @override
  State<SwipeableNoteCard> createState() => _SwipeableNoteCardState();
}

class _SwipeableNoteCardState extends State<SwipeableNoteCard>
    with SingleTickerProviderStateMixin {
  // Fraction of the card's width the user must drag past before release
  // commits the action instead of snapping back.
  static const double _revealThreshold = 0.45;
  static const Duration _snapDuration = Duration(milliseconds: 220);
  static const Duration _fadeDuration = Duration(milliseconds: 150);
  static const Duration _collapseDuration = Duration(milliseconds: 200);

  late final AnimationController _snapController;
  Animation<double>? _snapAnimation;

  /// Current horizontal offset of the card. This is the single source of
  /// truth whether it's being driven by a live drag or by the snap-back
  /// animation, which is what makes the animation interruptible: a new
  /// drag simply calls `_snapController.stop()` and starts adjusting
  /// `_dragDx` directly from wherever the animation had gotten to, with
  /// no jump.
  double _dragDx = 0;

  bool _fadingOut = false;
  bool _removing = false;

  @override
  void initState() {
    super.initState();
    _snapController = AnimationController(vsync: this, duration: _snapDuration)
      ..addListener(() {
        final animation = _snapAnimation;
        if (animation == null) return;
        setState(() => _dragDx = animation.value);
      });
  }

  @override
  void dispose() {
    _snapController.dispose();
    super.dispose();
  }

  void _animateTo(double target) {
    _snapAnimation = Tween<double>(
      begin: _dragDx,
      end: target,
    ).animate(CurvedAnimation(parent: _snapController, curve: Curves.easeOut));
    _snapController
      ..stop()
      ..forward(from: 0);
  }

  void _onDragStart(DragStartDetails details) {
    if (_fadingOut) return;
    // Interrupt any in-flight snap-back: stop the ticker where it is.
    // `_dragDx` already holds the last animated value (set by the
    // listener above), so the drag continues smoothly from there.
    _snapController.stop();
  }

  void _onDragUpdate(DragUpdateDetails details, double cardWidth) {
    if (_fadingOut) return;
    setState(() {
      _dragDx = (_dragDx + details.delta.dx).clamp(-cardWidth, cardWidth);
    });
  }

  void _onDragEnd(DragEndDetails details, double cardWidth) {
    if (_fadingOut) return;
    final threshold = cardWidth * _revealThreshold;
    if (_dragDx <= -threshold) {
      _commitDelete();
    } else if (_dragDx >= threshold) {
      widget.onFavorite();
      _animateTo(0);
    } else {
      _animateTo(0);
    }
  }

  void _commitDelete() {
    setState(() => _fadingOut = true);
  }

  void _openActionsMenu(BuildContext context) {
    if (_fadingOut) return;
    showNoteActionsSheet(
      context,
      note: widget.note,
      onOpen: widget.onTap,
      onToggleFavorite: widget.onFavorite,
      // Same commit path as a swipe-delete, so it gets the same
      // fade-then-collapse animation instead of the note just vanishing.
      onDelete: _commitDelete,
    );
  }

  void _onFadeEnd() {
    if (!_fadingOut || _removing || !mounted) return;
    setState(() => _removing = true);
    Future.delayed(_collapseDuration, () {
      if (mounted) widget.onDelete();
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = constraints.maxWidth;
        final threshold = cardWidth * _revealThreshold;
        final isLeft = _dragDx < 0;
        final progress = threshold <= 0
            ? 0.0
            : (_dragDx.abs() / threshold).clamp(0.0, 1.0);

        return AnimatedSize(
          duration: _collapseDuration,
          curve: Curves.easeInOut,
          alignment: Alignment.topCenter,
          child: _removing
              ? const SizedBox(width: double.infinity, height: 0)
              : Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: AnimatedOpacity(
                    opacity: _fadingOut ? 0 : 1,
                    duration: _fadeDuration,
                    onEnd: _onFadeEnd,
                    child: GestureDetector(
                      onHorizontalDragStart: _onDragStart,
                      onHorizontalDragUpdate: (d) =>
                          _onDragUpdate(d, cardWidth),
                      onHorizontalDragEnd: (d) => _onDragEnd(d, cardWidth),
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: _RevealBackground(
                              isLeft: isLeft,
                              progress: progress,
                            ),
                          ),
                          Transform.translate(
                            offset: Offset(_dragDx, 0),
                            child: NoteCard(
                              note: widget.note,
                              onTap: widget.onTap,
                              onLongPress: () => _openActionsMenu(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
        );
      },
    );
  }
}

/// The full-bleed color + icon revealed behind the card as it's dragged.
/// The design shows the whole card face turning solid red/gold with a
/// centered icon, not a thin sliver peeking out at the edge, so this
/// fills the entire card rect rather than just the exposed gap.
class _RevealBackground extends StatelessWidget {
  const _RevealBackground({required this.isLeft, required this.progress});

  final bool isLeft;
  final double progress;

  @override
  Widget build(BuildContext context) {
    if (progress <= 0) return const SizedBox.shrink();
    final color = isLeft ? AppTheme.destructive : AppTheme.favoriteGold;
    final icon = isLeft ? Icons.delete_rounded : Icons.star_rounded;
    return Opacity(
      opacity: progress,
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(18),
        ),
        alignment: Alignment.center,
        child: Icon(icon, color: Colors.white, size: 30),
      ),
    );
  }
}
