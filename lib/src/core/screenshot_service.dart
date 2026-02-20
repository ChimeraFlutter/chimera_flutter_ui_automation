import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../models/screenshot_result.dart';
import '../models/user_action.dart';
import '../core/ui_state_capture.dart';
import '../core/behavior_recorder.dart';
import '../core/navigator_observer.dart';
import '../exceptions/screenshot_exception.dart';

/// Service for capturing screenshots of the Flutter app
class ScreenshotService {
  static final ScreenshotService _instance = ScreenshotService._internal();
  static ScreenshotService get instance => _instance;

  ScreenshotService._internal();

  /// Default rate limit: 1 screenshot per second
  static const int _defaultRateLimitMs = 1000;

  /// GlobalKey for accessing the RepaintBoundary
  GlobalKey? _screenshotKey;

  /// Whether screenshot capture is enabled
  bool _isEnabled = false;

  /// Rate limit in milliseconds
  int _rateLimitMs = _defaultRateLimitMs;

  /// Timestamp of last capture
  DateTime? _lastCaptureTime;

  /// Total number of captures
  int _captureCount = 0;

  /// Set the GlobalKey for the RepaintBoundary
  void setScreenshotKey(GlobalKey key) {
    _screenshotKey = key;
  }

  /// Enable or disable screenshot capture
  void setEnabled(bool enabled) {
    _isEnabled = enabled;
  }

  /// Check if screenshot capture is enabled
  bool isEnabled() => _isEnabled;

  /// Set the rate limit in milliseconds
  void setRateLimit(int milliseconds) {
    _rateLimitMs = milliseconds;
  }

  /// Check if a screenshot can be captured (rate limiting)
  bool canCapture() {
    if (_lastCaptureTime == null) return true;

    final elapsed = DateTime.now().difference(_lastCaptureTime!);
    return elapsed.inMilliseconds >= _rateLimitMs;
  }

  /// Get capture statistics
  int get captureCount => _captureCount;

  /// Capture a screenshot of the app
  Future<ScreenshotResult> captureScreen({
    double pixelRatio = 1.0,
    bool includeMetadata = true,
    int maxRecentActions = 10,
  }) async {
    // Check if enabled
    if (!_isEnabled) {
      throw ScreenshotException(
        'Screenshot capture is disabled. Enable it in AutomationController.initialize()',
      );
    }

    // Check rate limiting
    if (!canCapture()) {
      throw ScreenshotException(
        'Rate limit exceeded. Please wait ${_rateLimitMs}ms between captures',
      );
    }

    // Validate key is set
    if (_screenshotKey == null) {
      throw ScreenshotException(
        'Screenshot key not set. Call setScreenshotKey() first',
      );
    }

    try {
      // Get the render object
      final context = _screenshotKey!.currentContext;
      if (context == null) {
        throw ScreenshotException(
          'Screenshot key not attached. Ensure app is wrapped with ScreenshotCapableApp',
        );
      }

      final renderObject = context.findRenderObject();
      if (renderObject == null) {
        throw ScreenshotException(
          'Render object not found. Widget may not be rendered yet',
        );
      }

      if (renderObject is! RenderRepaintBoundary) {
        throw ScreenshotException(
          'Invalid render object type. Expected RenderRepaintBoundary',
        );
      }

      // Capture the image with timeout
      final image = await renderObject
          .toImage(pixelRatio: pixelRatio)
          .timeout(
            const Duration(seconds: 5),
            onTimeout: () {
              throw ScreenshotException(
                'Screenshot capture timed out after 5 seconds',
              );
            },
          );

      // Convert to PNG bytes
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        throw ScreenshotException('Failed to convert image to PNG bytes');
      }

      final bytes = byteData.buffer.asUint8List();
      final base64Image = base64Encode(bytes);

      // Collect metadata if requested
      ScreenshotMetadata? metadata;
      if (includeMetadata) {
        metadata = await _collectMetadata(maxRecentActions);
      }

      // Update rate limiting
      _lastCaptureTime = DateTime.now();
      _captureCount++;

      return ScreenshotResult(
        base64Image: base64Image,
        mimeType: 'image/png',
        width: image.width,
        height: image.height,
        metadata: metadata,
        timestamp: DateTime.now(),
      );
    } on ScreenshotException {
      rethrow;
    } catch (e, stackTrace) {
      debugPrint('[ScreenshotService] Capture failed: $e\n$stackTrace');
      throw ScreenshotException('Unexpected error during capture: $e');
    }
  }

  /// Collect metadata about the current UI state
  Future<ScreenshotMetadata> _collectMetadata(int maxRecentActions) async {
    try {
      // Get current route
      final currentRoute = AutomationNavigatorObserver.currentRoute;

      // Capture UI snapshot
      final uiSnapshot = UIStateCapture.captureCurrentState(null);

      // Get recent actions from BehaviorRecorder
      List<UserAction>? recentActions;
      final recorder = BehaviorRecorder();
      if (recorder.isRecording && recorder.currentSession != null) {
        final allActions = recorder.currentSession!.actions;
        if (allActions.isNotEmpty) {
          final startIndex = allActions.length > maxRecentActions
              ? allActions.length - maxRecentActions
              : 0;
          recentActions = allActions.sublist(startIndex);
        }
      }

      // Get window dimensions
      final window = WidgetsBinding.instance.window;
      final windowInfo = {
        'physicalWidth': window.physicalSize.width,
        'physicalHeight': window.physicalSize.height,
        'devicePixelRatio': window.devicePixelRatio,
        'logicalWidth': window.physicalSize.width / window.devicePixelRatio,
        'logicalHeight': window.physicalSize.height / window.devicePixelRatio,
      };

      return ScreenshotMetadata(
        currentRoute: currentRoute,
        uiSnapshot: uiSnapshot,
        recentActions: recentActions,
        windowInfo: windowInfo,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      debugPrint('[ScreenshotService] Failed to collect metadata: $e');
      // Return minimal metadata on error
      return ScreenshotMetadata(
        windowInfo: {},
        timestamp: DateTime.now(),
      );
    }
  }
}
