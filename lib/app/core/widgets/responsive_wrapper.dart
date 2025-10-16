import 'package:flutter/material.dart';

/// A global responsive wrapper for all main pages.
class ResponsiveWrapper extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry? padding;

  const ResponsiveWrapper({
    super.key,
    required this.child,
    this.maxWidth = 900,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding =
        screenWidth < 480
            ? 12.0
            : screenWidth < 900
            ? 16.0
            : 20.0;
    final verticalPadding = screenWidth < 900 ? 8.0 : 12.0;
    return Center(
      child: Container(
        constraints: BoxConstraints(maxWidth: maxWidth),
        padding:
            padding ??
            EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: verticalPadding,
            ),
        child: child,
      ),
    );
  }
}
