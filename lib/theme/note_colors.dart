import 'package:flutter/material.dart';

/// The pastel palette the design cycles through for note card backgrounds.
///
/// The Figma file is view-only (no Dev Mode, no inspect panel), so these
/// are matched by eye rather than sampled exactly — see README "Design
/// notes". Card text is always rendered near-black on top of these, which
/// is legible against every swatch here.
const List<Color> kNoteColors = [
  Color(0xFFE3AEF2), // orchid
  Color(0xFFF0A8A0), // salmon
  Color(0xFFAEE8A8), // mint green
  Color(0xFFF2E29B), // pale yellow
  Color(0xFFA6E8EC), // cyan
  Color(0xFFC7B8F5), // lavender
];

/// Notes don't store a color — the design never shows a color picker, so
/// there's nowhere for a user to have chosen one. Instead each note's
/// background is derived from its id, which keeps it stable across
/// restarts and re-sorts without persisting an extra field.
Color colorForNote(String noteId) {
  final index = noteId.hashCode.abs() % kNoteColors.length;
  return kNoteColors[index];
}

/// Readable foreground for text/icons sitting on a note card.
const Color kNoteCardForeground = Color(0xDD1A1A1A);
