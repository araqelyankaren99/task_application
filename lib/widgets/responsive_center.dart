import 'package:flutter/material.dart';

/// The design is drawn at one phone width. On anything wider (a tablet,
/// a foldable unfolded, a desktop window) this caps content at a
/// comfortable reading width and centers it, instead of letting a single
/// column of note cards stretch edge-to-edge or a text line run
/// unreadably long. Below the cap it's a no-op (full width, no padding
/// added beyond what the caller already has).
///
/// Every screen's top-level body should be wrapped in this exactly once.
class ResponsiveCenter extends StatelessWidget {
  const ResponsiveCenter({super.key, required this.child, this.maxWidth = 640});

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
