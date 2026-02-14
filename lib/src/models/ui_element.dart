import 'dart:ui';
import 'function_info.dart';

/// Represents a UI element captured from the Semantics tree
class UIElement {
  /// Unique identifier for this element
  final String identifier;

  /// Display label/text
  final String label;

  /// Current value (for text fields, etc.)
  final String? value;

  /// Element type (button, textField, etc.)
  final String type;

  /// Bounding rectangle
  final Rect rect;

  /// Available actions (tap, longPress, etc.)
  final List<String> actions;

  /// Associated function information
  final FunctionInfo? functionInfo;

  /// Whether the element is visible
  final bool visible;

  /// Additional properties
  final Map<String, dynamic> properties;

  UIElement({
    required this.identifier,
    required this.label,
    this.value,
    required this.type,
    required this.rect,
    required this.actions,
    this.functionInfo,
    this.visible = true,
    this.properties = const {},
  });

  Map<String, dynamic> toJson() {
    return {
      'identifier': identifier,
      'label': label,
      'value': value,
      'type': type,
      'rect': {
        'x': rect.left,
        'y': rect.top,
        'width': rect.width,
        'height': rect.height,
      },
      'actions': actions,
      'functionName': functionInfo?.functionName,
      'visible': visible,
      'properties': properties,
    };
  }
}
