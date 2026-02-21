import '../models/ui_snapshot.dart';
import '../models/user_action.dart';

/// Result of a screenshot capture operation
class ScreenshotResult {
  /// Base64-encoded PNG image data
  final String base64Image;

  /// MIME type of the image (always 'image/png')
  final String mimeType;

  /// Image width in pixels
  final int width;

  /// Image height in pixels
  final int height;

  /// Optional metadata about the screenshot
  final ScreenshotMetadata? metadata;

  /// Timestamp when the screenshot was captured
  final DateTime timestamp;

  ScreenshotResult({
    required this.base64Image,
    required this.mimeType,
    required this.width,
    required this.height,
    this.metadata,
    required this.timestamp,
  });

  /// Convert to JSON for WebSocket responses
  Map<String, dynamic> toJson() {
    return {
      'base64Image': base64Image,
      'mimeType': mimeType,
      'width': width,
      'height': height,
      'timestamp': timestamp.toIso8601String(),
      if (metadata != null) 'metadata': metadata!.toJson(),
    };
  }
}

/// Metadata associated with a screenshot
class ScreenshotMetadata {
  /// Current route/page name
  final String? currentRoute;

  /// UI snapshot at the time of capture
  final UISnapshot? uiSnapshot;

  /// Recent user actions (if recording is enabled)
  final List<UserAction>? recentActions;

  /// Window/display information
  final Map<String, dynamic> windowInfo;

  /// Timestamp when metadata was collected
  final DateTime timestamp;

  ScreenshotMetadata({
    this.currentRoute,
    this.uiSnapshot,
    this.recentActions,
    required this.windowInfo,
    required this.timestamp,
  });

  /// Convert to JSON for WebSocket responses
  Map<String, dynamic> toJson() {
    return {
      if (currentRoute != null) 'currentRoute': currentRoute,
      if (uiSnapshot != null) 'uiSnapshot': uiSnapshot!.toJson(),
      if (recentActions != null)
        'recentActions': recentActions!.map((a) => a.toJson()).toList(),
      'windowInfo': windowInfo,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
