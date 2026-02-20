import 'package:flutter/material.dart';

/// Widget that wraps the app with RepaintBoundary for screenshot capture
class ScreenshotCapableApp extends StatelessWidget {
  final Widget child;
  final GlobalKey? screenshotKey;

  const ScreenshotCapableApp({
    Key? key,
    required this.child,
    this.screenshotKey,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: screenshotKey,
      child: child,
    );
  }
}
