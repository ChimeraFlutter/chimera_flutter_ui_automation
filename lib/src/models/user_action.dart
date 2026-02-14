import 'ui_snapshot.dart';

/// Represents a user action (tap, input, etc.)
class UserAction {
  /// When this action occurred
  final DateTime timestamp;

  /// Type of action (tap, longPress, setText, etc.)
  final String actionType;

  /// Identifier of the target element
  final String targetIdentifier;

  /// Label of the target element
  final String targetLabel;

  /// Function name that was executed
  final String? functionName;

  /// Function ID in the registry
  final String? functionId;

  /// Action arguments (e.g., text input)
  final dynamic arguments;

  /// UI state before the action (optional)
  final UISnapshot? uiStateBefore;

  UserAction({
    required this.timestamp,
    required this.actionType,
    required this.targetIdentifier,
    required this.targetLabel,
    this.functionName,
    this.functionId,
    this.arguments,
    this.uiStateBefore,
  });

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'actionType': actionType,
      'targetIdentifier': targetIdentifier,
      'targetLabel': targetLabel,
      'functionName': functionName,
      'functionId': functionId,
      'arguments': arguments,
      'uiStateBefore': uiStateBefore?.toJson(),
    };
  }

  factory UserAction.fromJson(Map<String, dynamic> json) {
    return UserAction(
      timestamp: DateTime.parse(json['timestamp'] as String),
      actionType: json['actionType'] as String,
      targetIdentifier: json['targetIdentifier'] as String,
      targetLabel: json['targetLabel'] as String,
      functionName: json['functionName'] as String?,
      functionId: json['functionId'] as String?,
      arguments: json['arguments'],
      uiStateBefore: json['uiStateBefore'] != null
          ? UISnapshot.fromJson(json['uiStateBefore'] as Map<String, dynamic>)
          : null,
    );
  }
}
