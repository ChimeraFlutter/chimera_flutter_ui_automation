import 'ui_element.dart';

/// Snapshot of the UI state at a specific point in time
class UISnapshot {
  /// When this snapshot was taken
  final DateTime timestamp;

  /// Current page/route name
  final String? currentPage;

  /// All UI elements in the tree
  final List<UIElement> elements;

  /// Additional context information
  final Map<String, dynamic> context;

  UISnapshot({
    required this.timestamp,
    this.currentPage,
    required this.elements,
    this.context = const {},
  });

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'currentPage': currentPage,
      'elements': elements.map((e) => e.toJson()).toList(),
      'context': context,
    };
  }

  factory UISnapshot.fromJson(Map<String, dynamic> json) {
    return UISnapshot(
      timestamp: DateTime.parse(json['timestamp'] as String),
      currentPage: json['currentPage'] as String?,
      elements: [], // Would need full deserialization for replay
      context: json['context'] as Map<String, dynamic>? ?? {},
    );
  }
}
