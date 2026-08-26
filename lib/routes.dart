import 'package:flutter/material.dart';

import 'screens/editor/editor_screen.dart';
import 'screens/reading/reading_screen.dart';
import 'screens/search/search_screen.dart';

/// Route builders every screen uses to navigate, so the navigation
/// contract lives in one place instead of being re-invented per screen.
class AppRoutes {
  AppRoutes._();

  static Route<void> editor({String? noteId}) => MaterialPageRoute(
    builder: (_) => EditorScreen(noteId: noteId),
  );

  static Route<void> reading({required String noteId}) => MaterialPageRoute(
    builder: (_) => ReadingScreen(noteId: noteId),
  );

  static Route<void> search() =>
      MaterialPageRoute(builder: (_) => const SearchScreen());
}
