/// Information about a tracked function/callback
class FunctionInfo {
  /// Unique identifier for this function
  final String identifier;

  /// Human-readable function name (for logging/debugging)
  final String functionName;

  /// The actual callback function
  final Function callback;

  /// Type of widget this function belongs to (e.g., 'button', 'textField')
  final String widgetType;

  /// Additional metadata
  final Map<String, dynamic> metadata;

  /// When this function was registered
  final DateTime registeredAt;

  FunctionInfo({
    required this.identifier,
    required this.functionName,
    required this.callback,
    required this.widgetType,
    this.metadata = const {},
    DateTime? registeredAt,
  }) : registeredAt = registeredAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'identifier': identifier,
      'functionName': functionName,
      'widgetType': widgetType,
      'metadata': metadata,
      'registeredAt': registeredAt.toIso8601String(),
    };
  }
}
