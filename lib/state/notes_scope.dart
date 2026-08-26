import 'package:flutter/widgets.dart';

import 'notes_controller.dart';

/// Makes the single app-wide [NotesController] available to every screen
/// without pulling in a state-management package — see README for why
/// plain `ChangeNotifier` + `InheritedNotifier` is enough for this app.
class NotesScope extends InheritedNotifier<NotesController> {
  const NotesScope({
    super.key,
    required NotesController controller,
    required super.child,
  }) : super(notifier: controller);

  static NotesController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<NotesScope>();
    assert(scope != null, 'No NotesScope found in context');
    return scope!.notifier!;
  }
}
