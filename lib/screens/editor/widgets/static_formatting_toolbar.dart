import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';

/// The formatting toolbar from frame 09 (New Note Editor) — a row of icons
/// (bold, italic, underline, ...) shown above the keyboard.
///
/// This app has no rich-text/markdown model anywhere (notes are plain
/// strings, per [Note]), and nothing in the traced prototype wires these
/// buttons to any action. Rather than omit the toolbar and lose the
/// frame's look entirely, it's rendered here as a static/decorative bar:
/// every button has `onPressed: null`, which both disables its ripple and
/// visually dims it, making "this doesn't do anything" obvious rather than
/// misleading the user into thinking it does.
class StaticFormattingToolbar extends StatelessWidget {
  const StaticFormattingToolbar({super.key});

  static const _icons = <IconData>[
    Icons.format_bold,
    Icons.format_italic,
    Icons.format_underlined,
    Icons.link,
    Icons.format_strikethrough,
    Icons.format_list_numbered,
    Icons.format_list_bulleted,
    Icons.code,
    Icons.text_fields,
    Icons.format_quote,
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(top: BorderSide(color: AppTheme.surfaceHigh)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final icon in _icons)
              IconButton(
                // Intentionally not wired to anything — see class doc.
                onPressed: null,
                icon: Icon(icon),
                disabledColor: Colors.white30,
              ),
          ],
        ),
      ),
    );
  }
}
